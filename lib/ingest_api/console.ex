defmodule Logger.Humio.Backend.IngestApi.Console do
  @moduledoc """
  Not actually a Humio Ingest API, instead a Console logger that can be used for testing.
  Additionally, this Module is used for situations when the Logger can't communicate for some reason, i.e. the Client returned either a non-200 status code or an :error.
  """
  @behaviour Logger.Backend.Humio.IngestApi
  alias Logger.Backend.Humio.IngestApi

  @impl true
  def transmit(%{
        log_events: log_events,
        format: format,
        metadata_keys: metadata_keys
      }) do
    _entries = format_messages(log_events, format, metadata_keys)
    {:ok, %{status: 200, body: "Wrote to console"}}
  end

  defp format_messages(log_events, format, metadata_keys) do
    log_events
    |> Enum.map(&IngestApi.format_message(&1, format, metadata_keys))
  end
end
