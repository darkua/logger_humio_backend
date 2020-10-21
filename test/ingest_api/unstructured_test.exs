defmodule Logger.Backend.Humio.IngestApi.UnstructuredTest do
  use ExUnit.Case, async: false
  require Logger

  alias Logger.Backend.Humio.IngestApi
  alias Logger.Backend.Humio.Client

  @backend {Logger.Backend.Humio, :test}
  Logger.add_backend(@backend)

  @base_url "humio.url"
  @token "token"
  @path "/api/v1/ingest/humio-unstructured"
  @headers [{"Authorization", "Bearer " <> @token}, {"Content-Type", "application/json"}]

  setup do
    config(
      ingest_api: IngestApi.Unstructured,
      client: Client.Test,
      host: @base_url,
      format: "$message",
      token: @token,
      max_batch_size: 1
    )

    Client.Test.start_link(self())
    :ok
  end

  test "Send payload successfully" do
    message = "message"
    Logger.info(message)

    expected_body = Jason.encode!([%{messages: [message]}])

    assert_receive(
      {:send, %{body: ^expected_body, base_url: @base_url, path: @path, headers: @headers}}
    )
  end

  defp config(opts) do
    :ok = Logger.configure_backend(@backend, opts)
  end
end
