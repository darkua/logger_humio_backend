defmodule Logger.Backend.Humio.IngestApi do
  @moduledoc """
  Defines the contract for implementing a Humio Ingest API,
  such as humio-structured, humio-unstructured, HEC, etc.
  """

  @type log_event :: %{
          level: atom(),
          message: String.t(),
          timestamp: any(),
          metadata: keyword()
        }
  @type params :: %{
          log_events: nonempty_list(log_event),
          host: String.t(),
          token: String.t(),
          client: Logger.Backend.Humio.Client,
          format: any(),
          metadata_keys: list()
        }
  @type response :: %{
          status: 100..599,
          body: String.t()
        }
  @type result :: {:ok, response} | {:error, any}

  @callback transmit(params) :: result
end
