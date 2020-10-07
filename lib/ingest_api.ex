defmodule Logger.Backend.Humio.IngestApi do
  @moduledoc """
  Defines the contract for implementing a Humio Ingest API,
  such as humio-structured, humio-unstructured, HEC, etc.
  """

  @type params :: %{
          entries: nonempty_list(String.t()),
          host: String.t(),
          token: String.t(),
          client: Logger.Backend.Humio.Client
        }
  @type response :: %{
          status: 100..599,
          body: String.t()
        }
  @type result :: {:ok, response} | {:error, any}

  @callback transmit(params) :: result
end
