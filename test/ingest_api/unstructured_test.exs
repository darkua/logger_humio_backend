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
    Client.Test.start_link(self())

    :ok
  end

  test "Send payload successfully" do
    {:ok, body} = Jason.encode([%{"messages" => [@message]}])

    headers = [{"Authorization", "Bearer " <> @token}, {"Content-Type", @content_type}]

    {:ok, %{status: _status, body: _body}} =
      IngestApi.Unstructured.transmit(%{
        entries: [@message],
        host: @base_url,
        token: @token,
        client: Client.Test
      })

    assert_receive({:send, %{body: ^body, base_url: @base_url, path: @path, headers: ^headers}})
  end
end
