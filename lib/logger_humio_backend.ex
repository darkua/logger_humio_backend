defmodule Logger.Backend.Humio do
  @moduledoc """
  A Genserver that receives calls and events from Elixir when configured as a logger.
  """
  @behaviour :gen_event

  require Logger

  @default_format "[$level] $message\n"
  @default_ingest_api Logger.Backend.Humio.IngestApi.Unstructured
  @default_client Logger.Backend.Humio.Client.Tesla
  @default_level :debug
  @default_metadata []
  @default_max_batch_size 20
  @default_flush_interval_ms 10_000

  @type log_event :: %{
          level: atom(),
          message: String.t(),
          timestamp: any(),
          metadata: keyword()
        }
  @type state :: %{
          log_events: [log_event],
          config: %{
            token: String.t(),
            host: String.t(),
            name: any(),
            ingest_api: Logger.Backend.Humio.IngestApi,
            client: Logger.Backend.Humio.Client,
            level: Logger.level(),
            format: any(),
            metadata: keyword(),
            max_batch_size: pos_integer(),
            flush_interval_ms: pos_integer()
          },
          flush_timer: reference()
        }

  #### :gen_event implementation

  @impl true
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  @doc """
  The logger can be (re-)configured at runtime by calling :configure.
  There currently isn't any logic for merging the existing config and the new options,
  so if you use this, set all the options that are relevant to you.
  Also batched log lines are lost when the logger is re-configured at runtime.list()

  Will eventually be improved.

  Use at your own risk.
  """
  @impl true
  def handle_call({:configure, opts}, %{config: %{name: name}}) do
    {:ok, :ok, configure(name, opts)}
  end

  def handle_call(:ingest_api, %{config: %{ingest_api: ingest_api}} = state) do
    {:ok, {:ok, ingest_api}, state}
  end

  @doc """
  Ignore messages where the group leader is in a different node than the one where handler is installed.
  """
  @impl true
  def handle_event({_level, group_leader, {Logger, _msg, _ts, _md}}, state)
      when node(group_leader) != node() do
    {:ok, state}
  end

  def handle_event(
        {level, _group_leader, {Logger, msg, ts, md}},
        %{config: %{level: min_level}} = state
      ) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      add_to_batch(%{level: level, message: msg, timestamp: ts, metadata: md}, state)
    else
      {:ok, state}
    end
  end

  @doc """
  Send batched events when `Logger.flush/0` is called.
  """
  @impl true
  def handle_event(:flush, state) do
    send_events(state)
  end

  @doc """
  Handles flush due to timeout from the timer set in the `set_timer` function.
  """
  @impl true
  def handle_info({:timeout, _ref, :flush}, state) do
    send_events(state)
  end

  @doc """
  Unhandled messages are simply ignored.
  """
  def handle_info(_message, state) do
    {:ok, state}
  end

  #### internal implementation

  defp set_timer_if_nil(%{flush_timer: nil} = state), do: set_timer(state)

  defp set_timer_if_nil(state), do: state

  # Sets the timer in the state to have the backend send a :flush info message to itself on timeout.
  # Introduces 20% jitter.
  defp set_timer(%{config: %{flush_interval_ms: flush_interval_ms}} = state) do
    jitter = :random.uniform(div(flush_interval_ms, 5))
    timer = :erlang.start_timer(flush_interval_ms + jitter, self(), :flush)
    %{cancel_timer(state) | flush_timer: timer}
  end

  defp cancel_timer(%{flush_timer: timer} = state) when is_nil(timer), do: state

  defp cancel_timer(%{flush_timer: timer} = state) do
    :erlang.cancel_timer(timer)
    %{state | flush_timer: nil}
  end

  @spec add_to_batch(log_event(), state()) :: {:ok, state()}
  defp add_to_batch(log_event, %{config: %{max_batch_size: max_batch_size}} = state) do
    state =
      state
      |> Map.put(:log_events, [log_event | state.log_events])
      |> set_timer_if_nil()

    if length(state.log_events) >= max_batch_size do
      send_events(state)
    else
      {:ok, state}
    end
  end

  defp send_events(%{log_events: []} = state) do
    {:ok, state}
  end

  defp send_events(state) do
    messages = format_messages(state)
    transmit(messages, state)
    {:ok, %{cancel_timer(state) | log_events: []}}
  end

  defp format_messages(%{log_events: log_events, config: config}) do
    log_events
    |> Enum.reverse()
    |> Enum.map(&format_message(&1, config))
  end

  defp format_message(%{message: msg, level: level, timestamp: ts, metadata: md}, config) do
    msg
    |> IO.chardata_to_string()
    |> String.split("\n")
    |> filter_empty_strings
    |> Enum.map(&format_event(level, &1, ts, md, config))
    |> Enum.join("")
  end

  defp format_event(level, msg, ts, md, %{format: format, metadata: keys}) do
    Logger.Formatter.format(format, level, msg, ts, take_metadata(md, keys))
  end

  defp filter_empty_strings(strings) do
    strings
    |> Enum.reject(&(String.trim(&1) == ""))
  end

  @spec transmit(messages :: nonempty_list(String.t()), state()) ::
          {:ok, response :: map()} | {:error, reason :: any()}
  defp transmit(messages, %{
         config: %{ingest_api: ingest_api, host: host, token: token, client: client}
       }) do
    %{
      entries: messages,
      host: host,
      token: token,
      client: client
    }
    |> ingest_api.transmit()
  end

  defp take_metadata(metadata, :all) do
    IO.inspect(metadata)
    metadata
  end

  defp take_metadata(metadata, keys) when is_list(keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
    |> Enum.reverse()
  end

  defp configure(name, opts) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    host = Keyword.get(opts, :host, "")
    token = token(Keyword.get(opts, :token, ""))

    ingest_api = Keyword.get(opts, :ingest_api, @default_ingest_api)
    client = Keyword.get(opts, :client, @default_client)
    level = Keyword.get(opts, :level, @default_level)
    metadata = Keyword.get(opts, :metadata, @default_metadata)
    format = Keyword.get(opts, :format, @default_format) |> Logger.Formatter.compile()
    max_batch_size = Keyword.get(opts, :max_batch_size, @default_max_batch_size)
    flush_interval_ms = Keyword.get(opts, :flush_interval_ms, @default_flush_interval_ms)

    %{
      config: %{
        token: token,
        host: host,
        name: name,
        ingest_api: ingest_api,
        client: client,
        level: level,
        format: format,
        metadata: metadata,
        max_batch_size: max_batch_size,
        flush_interval_ms: flush_interval_ms
      },
      log_events: [],
      flush_timer: nil
    }
  end

  defp token({:system, envvar}) do
    System.get_env(envvar)
  end

  defp token(binary) when is_binary(binary) do
    binary
  end
end
