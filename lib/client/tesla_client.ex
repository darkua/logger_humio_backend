defmodule Logger.Backend.Humio.Client.Tesla do
  @behaviour Logger.Backend.Humio.Client

  @impl true
  def send(%{base_url: base_url, path: path, body: body, headers: headers}) do
    {:ok, response} = Tesla.post(client(base_url, headers), path, body)

    %{
      body: response.body,
      status: response.status
    }
  end

  def client(base_url, headers) do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middleware)
  end
end
