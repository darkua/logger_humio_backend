defmodule Logger.Backend.Humio.IngestApi.Hec do
  @behaviour Logger.Backend.Humio.IngestApi

  @path "/api/v1/ingest/hec"
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
        "fields" => %{
          "host" => "webhost1"
        },
        "messages" => entries
      }
    ])
  end
end
