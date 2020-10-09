defmodule Logger.Backend.Humio.IngestApi.Unstructured do
  @moduledoc """
  This Ingest API implementation is for Humio's `Unstructured` API.
  [Humio Documentation]: https://docs.humio.com/api/ingest/#parser
  """
  @behaviour Logger.Backend.Humio.IngestApi

  @path "/api/v1/ingest/humio-unstructured"
  @content_type "application/json"

  @impl true
  def transmit(%{
        log_events: log_events,
        host: host,
        token: token,
        client: client,
        format: format,
        metadata_keys: metadata_keys
      }) do
    entries = format_messages(log_events, format, metadata_keys)
    {:ok, body} = encode_entries(entries)
    headers = generate_headers(token)

    client.send(%{
      base_url: host,
      path: @path,
      body: body,
      headers: headers
    })
  end

  def generate_headers(token) do
    [
      {"Authorization", "Bearer " <> token},
      {"Content-Type", @content_type}
    ]
  end

  defp encode_entries(entries) do
    Jason.encode([
      %{
        "messages" => entries
      }
    ])
  end

  defp format_messages(log_events, format, metadata_keys) do
    log_events
    |> Enum.map(&format_message(&1, format, metadata_keys))
  end

  defp format_message(
         %{message: msg, level: level, timestamp: ts, metadata: md},
         format,
         metadata_keys
       ) do
    msg
    |> IO.chardata_to_string()
    |> String.split("\n")
    |> filter_empty_strings
    |> Enum.map(&format_event(level, &1, ts, md, format, metadata_keys))
    |> Enum.join("")
  end

  defp format_event(level, msg, ts, md, format, metadata_keys) do
    Logger.Formatter.format(format, level, msg, ts, take_metadata(md, metadata_keys))
  end

  defp filter_empty_strings(strings) do
    strings
    |> Enum.reject(&(String.trim(&1) == ""))
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
end
