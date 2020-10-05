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
  @default_max_batch_size 50

  @type log_event :: %{
          level: atom(),
          message: String.t(),
          timestamp: any(),
          metadata: keyword()
        }
  @type log_events :: [log_event]
  @type state :: %{
          log_events: log_events,
          config: map()
        }

  @impl true
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  @impl true
  def handle_call({:configure, opts}, %{config: %{name: name}}) do
    {:ok, :ok, configure(name, opts)}
  end

  @impl true
  def handle_call(:ingest_api, %{config: %{ingest_api: ingest_api}} = state) do
    {:ok, {:ok, ingest_api}, state}
  end

  @impl true
  @spec handle_event(
          :flush | {any, any, {Logger, any, Logger.Formatter.time(), keyword()}},
          state()
        ) :: {:ok, any}
  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{config: %{level: min_level}} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      add_to_batch(%{level: level, message: msg, timestamp: ts, metadata: md}, state)
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_event(:flush, state) do
    send_events(state)
  end

  @impl true
  @spec handle_info(any, state) :: {:ok, any}
  def handle_info({:io_reply, _ref, :ok}, state) do
    # ignored
    {:ok, state}
  end

  def handle_info(message, state) do
    Logger.warn(fn -> "#{__MODULE__} unhandled message: #{inspect(message)}" end)
    {:ok, state}
  end

  def add_to_batch(log_event, %{config: %{max_batch_size: max_batch_size}} = state) do
    state = Map.put(state, :log_events, [log_event | state.log_events])

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
    {:ok, Map.put(state, :log_events, [])}
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

  defp take_metadata(metadata, keys) do
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
        max_batch_size: max_batch_size
      },
      log_events: []
    }
  end

  defp token({:system, envvar}) do
    System.get_env(envvar)
  end

  defp token(binary) when is_binary(binary) do
    binary
  end
end
