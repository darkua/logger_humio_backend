defmodule Logger.Backend.Humio.IngestApi.Unstructured do
  @moduledoc """
  This Ingest API implementation is for Humio's `Unstructured` API.
  [Humio Documentation]: https://docs.humio.com/api/ingest/#parser
  """
  @behaviour Logger.Backend.Humio.IngestApi

  @path "/api/v1/ingest/humio-unstructured"
  @content_type "application/json"

  @impl true
  def transmit(%{entries: entries, host: host, token: token, client: client}) do
    {:ok, body} = encode_entries(entries)
    headers = generate_headers(token)

    {:ok, _response} =
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
