defmodule Logger.Humio.Backend.Output.UnstructuredTest do
  use ExUnit.Case

  alias Logger.Backend.Humio.IngestApi
  alias Logger.Backend.Humio.Client

  @base_url "https://humio-ingest.bigcorp.com:443"
  @path "/api/v1/ingest/humio-unstructured"
  @content_type "application/json"
  @token "token"
  @message "message"

  setup do
    on_exit(fn -> Client.Test.destroy() end)
  end

  test "Send payload successfully" do
    {:ok, body} = Jason.encode([%{"messages" => [@message]}])

    headers = [{"Authorization", "Bearer " <> @token}, {"Content-Type", @content_type}]

    assert {:ok, %{body: ^body, base_url: @base_url, path: @path, headers: ^headers}} =
             IngestApi.Unstructured.transmit(%{
               entries: [@message],
               host: @base_url,
               token: @token,
               client: Client.Test
             })
  end
end
