defmodule Logger.Backend.Humio.IngestApi.Unstructured do
  @moduledoc """
  This Ingest API implementation is for Humio's `Unstructured` API.
  [Humio Documentation]: https://docs.humio.com/api/ingest/#parser
  """
  @behaviour Logger.Backend.Humio.IngestApi
  alias Logger.Backend.Humio.IngestApi

  @path "/api/v1/ingest/humio-unstructured"
  @content_type "application/json"

  @impl true
  def transmit(%{
        log_events: log_events,
        host: host,
        token: token,
        client: client,
        format: format,
        formatter: formatter,
        metadata_keys: metadata_keys
      }) do
    entries = format_messages(log_events, format, formatter, metadata_keys)
    {:ok, body} = encode_entries(entries)
    headers = IngestApi.generate_headers(token, @content_type)

    client.send(%{
      base_url: host,
      path: @path,
      body: body,
      headers: headers
    })
  end

  defp encode_entries(entries) do
    Jason.encode([
      %{
        "messages" => entries
      }
    ])
  end

  defp format_messages(log_events, format, formatter, metadata_keys) do
    log_events
    |> Enum.map(&IngestApi.format_message(&1, format, formatter, metadata_keys))
  end
end
