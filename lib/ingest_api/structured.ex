defmodule Logger.Backend.Humio.IngestApi.Structured do
  @moduledoc """
    This Ingest API implementation is for Humio's `Structured` API.
    [Humio Documentation]: https://docs.humio.com/api/ingest/#structured-data
  """
  @behaviour Logger.Backend.Humio.IngestApi

  @path "/api/v1/ingest/humio-structured"
  @content_type "application/json"

  @impl true
  def transmit(%{entries: entries, host: host, token: token, client: client}) do
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

  def encode_entries(entries) do
    Jason.encode([
      %{
        "messages" => entries
      }
    ])
  end
end
