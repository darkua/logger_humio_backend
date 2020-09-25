defmodule Logger.Backend.Humio.Client do
  @moduledoc """
  Defines the HTTP client interface used to send messages to the Humio ingest APIs
  """
  @callback send(
              params :: %{
                base_url: String.t(),
                path: String.t(),
                body: String.t(),
                headers: list(tuple)
              }
            ) :: {:ok, response :: map()} | {:error, reason :: any()}
end
