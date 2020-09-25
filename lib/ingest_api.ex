defmodule Logger.Backend.Humio.IngestApi do
  @moduledoc """
  Defines the contract for implementing a Humio Ingest API,
  such as humio-structured, humio-unstructured, HEC, etc.
  """
  @callback transmit(
              params :: %{
                entries: nonempty_list(String.t()),
                host: String.t(),
                token: String.t(),
                client: Logger.Backend.Humio.Client
              }
            ) :: {:ok, response :: map()} | {:error, reason :: any()}
end
