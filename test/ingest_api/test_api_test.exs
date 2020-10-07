defmodule Logger.Backend.Humio.IngestApi.TestIngestApiTest do
  @moduledoc """
  An example test for the Test IngestAPI.

  This serves mainly as an example for how to use the Test IngestAPI in other tests.
  """
  use ExUnit.Case, async: true

  alias Logger.Backend.Humio.IngestApi

  setup do
    IngestApi.Test.start_link(self())
    :ok
  end

  test "send and receive" do
    params = "testParams"
    IngestApi.Test.transmit(params)
    assert_receive {:transmit, params}
  end
end
