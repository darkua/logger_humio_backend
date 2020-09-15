defmodule Logger.Backend.Splunk.Output.Http do
  def transmit(entry, host, token) do
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    {:ok, msg} =
      Jason.encode([
        %{
          "fields" => %{
            "host" => "webhost1"
          },
          "messages" => [entry]
        }
      ])

    {:ok, _response} = Tesla.post(host, msg, headers: headers)
  end
end
