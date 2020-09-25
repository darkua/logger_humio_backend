defmodule Logger.Backend.Humio do
  @moduledoc """
  A Genserver that receives calls and events from Elixir when configured as a logger.
  """
  @behaviour :gen_event

  @default_format "[$level] $message\n"

  require Logger

  @impl true
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  @impl true
  def handle_call({:configure, opts}, %{name: name}) do
    {:ok, :ok, configure(name, opts)}
  end

  @impl true
  def handle_call(:ingest_api, %{ingest_api: ingest_api} = state) do
    {:ok, {:ok, ingest_api}, state}
  end

  @impl true
  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, msg, ts, md, state)
    end

    {:ok, state}
  end

  @impl true
  def handle_event(:flush, state) do
    # TODO: implement when introducing batching
    {:ok, state}
  end

  @impl true
  def handle_info({:io_reply, _ref, :ok}, state) do
    # ignored
    {:ok, state}
  end

  def handle_info(message, state) do
    Logger.warn(fn -> "#{__MODULE__} unhandled message: #{inspect(message)}" end)
    {:ok, state}
  end

  defp log_event(level, msg, ts, md, state) do
    msg
    |> format_message(level, ts, md, state)
    |> transmit(state)
  end

  defp format_message(msg, level, ts, md, state) do
    msg
    |> IO.chardata_to_string()
    |> String.split("\n")
    |> filter_empty_strings
    |> Enum.map(&format_event(level, &1, ts, md, state))
    |> Enum.join("")
  end

  defp format_event(level, msg, ts, md, %{format: format, metadata: keys}) do
    Logger.Formatter.format(format, level, msg, ts, take_metadata(md, keys))
  end

  defp filter_empty_strings(strings) do
    strings
    |> Enum.reject(&(String.trim(&1) == ""))
  end

  defp transmit(msg, %{ingest_api: ingest_api} = state) do
    state
    |> Map.put_new(:entries, [msg])
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

    ingest_api = Keyword.get(opts, :ingest_api, Logger.Backend.Humio.Output.Unstructured)
    client = Keyword.get(opts, :client, Logger.Backend.Humio.Client.Tesla)
    host = Keyword.get(opts, :host)
    level = Keyword.get(opts, :level, :debug)
    metadata = Keyword.get(opts, :metadata, [])
    format = Keyword.get(opts, :format, @default_format) |> Logger.Formatter.compile()

    %{
      name: name,
      ingest_api: ingest_api,
      client: client,
      host: host,
      level: level,
      format: format,
      metadata: metadata,
      token: token(Keyword.get(opts, :token, ""))
    }
  end

  defp token({:system, envvar}) do
    System.get_env(envvar)
  end

  defp token(binary) when is_binary(binary) do
    binary
  end
end
