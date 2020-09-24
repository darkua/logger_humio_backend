defmodule Logger.Humio.Backend.Output.HecTest do
  use ExUnit.Case

  alias Logger.Backend.Humio.IngestApi.Hec
  alias Logger.Backend.Humio.Client.Test

  @base_url "https://humio-ingest.bigcorp.com:443"
  @path "/api/v1/ingest/hec"
  @content_type "application/json"
  @token "token"
  @message "message"

  test "Send payload successfully" do
    {:ok, body} =
      Jason.encode([
        %{
          "fields" => %{
            "host" => "webhost1"
          },
          "messages" => [@message]
        }
      ])

    headers = [{"Authorization", "Bearer " <> @token}, {"Content-Type", @content_type}]

    assert {:ok, %{body: ^body, base_url: @base_url, path: @path, headers: ^headers}} =
             Hec.transmit(%{
               entries: [@message],
               host: @base_url,
               token: @token,
               client: Test
             })
  end
end
