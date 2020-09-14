defmodule Logger.Backend.Splunk.Output.Http do
  def transmit(entry, host, token) do
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]


    {:ok, msg} = Jason.encode(
      [
        %{
          "fields" => %{
            "host" => "webhost1"
          },
          "messages" => [entry]
        }
      ]
    )

    case Tesla.post(host, msg, headers: headers) do
      {:ok, %{status: status} = response} when status not in 200..299 -> IO.inspect(response)
    end
  end
end
