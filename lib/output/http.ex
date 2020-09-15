defmodule Logger.Backend.Splunk.Output.Http do
  def transmit(entry, host, token) do
    headers = [
      {"Authorization", "Bearer #{token}"},
       {"Content-Type", "application/json"
      }]

    {:ok, _response} = Tesla.post(host, entry, headers: headers)
  end
end
