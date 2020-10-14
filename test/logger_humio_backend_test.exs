defmodule Logger.Backend.Humio.Test do
  @moduledoc """
  Smoke tests for the backend.
  """
  use ExUnit.Case, async: true
  require Logger

  alias Logger.Backend.Humio.IngestApi

  @backend {Logger.Backend.Humio, :test}
  Logger.add_backend(@backend)

  ### Setup Functions

  defp smoke_test_config(_context) do
    config(
      ingest_api: IngestApi.Test,
      host: "humio.url",
      format: "[$level] $message\n",
      token: "humio-token",
      max_batch_size: 1
    )

    IngestApi.Test.start_link(self())
    :ok
  end

  defp batch_test_config(_context) do
    config(
      ingest_api: Logger.Backend.Humio.IngestApi.Test,
      host: "humio.url",
      format: "[$level] $message\n",
      token: "humio-token",
      max_batch_size: 3,
      flush_interval_ms: 10_000
    )

    IngestApi.Test.start_link(self())
    :ok
  end

  defp timeout_test_config(_context) do
    flush_interval_ms = 200
    max_batch_size = 10

    config(
      ingest_api: Logger.Backend.Humio.IngestApi.Test,
      host: "humio.url",
      format: "$message",
      token: "humio-token",
      max_batch_size: max_batch_size,
      flush_interval_ms: flush_interval_ms
    )

    IngestApi.Test.start_link(self())
    {:ok, %{flush_interval_ms: flush_interval_ms, max_batch_size: max_batch_size}}
  end

  ### Tests

  describe "smoke tests" do
    setup [:smoke_test_config]

    test "default logger level is `:debug`" do
      assert Logger.level() == :debug
    end

    test "does not log when level is under minimum Logger level" do
      config(level: :info)
      Logger.debug("do not log me")
      refute_receive {:transmit, %{}}
    end

    test "does log when level is above or equal minimum Logger level" do
      config(level: :info)
      Logger.warn("you will log me")
      assert_receive {:transmit, %{}}
    end

    test "can configure format" do
      config(format: "$message ($level)\n")
      Logger.info("I am formatted")
      assert_receive {:transmit, %{format: [:message, " (", :level, ")\n"]}}
    end

    test "can configure metadata" do
      config(format: "$metadata$message\n", metadata: [:user_id, :auth])

      Logger.info("hello")
      assert_receive {:transmit, %{metadata_keys: [:user_id, :auth]}}
    end
  end

  describe "batch tests" do
    setup [:batch_test_config]

    test "send message batch" do
      Logger.info("message1")
      Logger.info("message2")
      refute_receive {:transmit, %{}}
      Logger.info("message3")

      assert_receive {:transmit,
                      %{
                        log_events: [
                          %{message: "message1"},
                          %{message: "message2"},
                          %{message: "message3"}
                        ]
                      }}

      Logger.info("message4")
      refute_receive {:transmit, %{}}
    end

    test "flush" do
      Logger.info("message1")
      refute_receive {:transmit, %{}}
      Logger.flush()
      assert_receive {:transmit, %{log_events: [%{message: "message1"}]}}
    end
  end

  describe "timeout tests" do
    setup [:timeout_test_config]

    test "no message received before timeout", %{flush_interval_ms: flush_interval_ms} do
      Logger.info("message")
      # we multiply by 0.7 to ensure we're under the threshold introduced by the 20% jitter.
      refute_receive({:transmit, %{}}, round(flush_interval_ms * 0.7))

      # we multipley by 0.5 so that we assert the :transmit is received between 0.7 to 1.3 the flush interval, which accounts for the 20% jitter.
      assert_receive(
        {:transmit, %{log_events: [%{message: "message"}]}},
        round(flush_interval_ms * 0.6)
      )
    end

    test "receive batched messages via timeout", %{
      flush_interval_ms: flush_interval_ms,
      max_batch_size: max_batch_size
    } do
      for n <- 1..(max_batch_size - 2) do
        Logger.info("message" <> Integer.to_string(n))
      end

      assert_receive(
        {:transmit,
         %{
           log_events: [
             %{message: "message1"},
             %{message: "message2"},
             %{message: "message3"},
             %{message: "message4"},
             %{message: "message5"},
             %{message: "message6"},
             %{message: "message7"},
             %{message: "message8"}
           ]
         }},
        round(flush_interval_ms * 1.2)
      )
    end

    test "no timer set/nothing sent to ingest API while log event queue is empty", %{
      flush_interval_ms: flush_interval_ms
    } do
      refute_receive({:transmit, %{}}, round(flush_interval_ms * 1.5))
    end

    test "timer is reset after timeout", %{flush_interval_ms: flush_interval_ms} do
      Logger.info("message1")

      assert_receive(
        {:transmit, %{log_events: [%{message: "message1"}]}},
        round(flush_interval_ms * 1.2)
      )

      Logger.info("message2")
      Logger.info("message3")

      assert_receive(
        {:transmit, %{log_events: [%{message: "message2"}, %{message: "message3"}]}},
        round(flush_interval_ms * 1.2)
      )
    end

    test "timer is reset by flush due to max batch size", %{
      flush_interval_ms: flush_interval_ms,
      max_batch_size: max_batch_size
    } do
      for n <- 1..max_batch_size do
        Logger.info("message" <> Integer.to_string(n))
      end

      # received before flush interval reached, since max_batch_size reached
      assert_receive(
        {:transmit,
         %{
           log_events: [
             %{message: "message1"},
             %{message: "message2"},
             %{message: "message3"},
             %{message: "message4"},
             %{message: "message5"},
             %{message: "message6"},
             %{message: "message7"},
             %{message: "message8"},
             %{message: "message9"},
             %{message: "message10"}
           ]
         }},
        round(div(flush_interval_ms, 2))
      )

      Logger.info("timer is reset")

      assert_receive(
        {:transmit, %{log_events: [%{message: "timer is reset"}]}},
        round(flush_interval_ms * 1.2)
      )
    end
  end

  defp config(opts) do
    :ok = Logger.configure_backend(@backend, opts)
  end
end
