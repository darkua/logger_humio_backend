defmodule Logger.Backend.Humio.IngestApi do
  @moduledoc """
  Defines the contract for implementing a Humio Ingest API,
  such as humio-structured, humio-unstructured, HEC, etc.
  """
  alias Logger.Backend.Humio.Client

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
          formatter: any(),
          metadata_keys: list() | :all,
          iso8601_format_fun: function()
        }
  @type result :: {:ok, Client.response()} | {:error, any}

  @callback transmit(params) :: result

  def generate_headers(token, content_type) do
    [
      {"Authorization", "Bearer " <> token},
      {"Content-Type", content_type}
    ]
  end

  def take_metadata(metadata, :all) do
    metadata
  end

  def take_metadata(metadata, keys) when is_list(keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
    |> Enum.reverse()
  end

  def format_message(
        %{message: msg, level: level, timestamp: ts, metadata: md},
        format,
        Logger.Formatter,
        metadata_keys
      ) do
    format
    |> Logger.Formatter.format(level, msg, ts, take_metadata(md, metadata_keys))
    |> IO.chardata_to_string()
    |> String.trim()
  end

  def format_message(
        %{message: msg, level: level, timestamp: ts, metadata: md},
        format,
        formatter,
        metadata_keys
      ) do
    formatter
    |> apply(:format, [format, level, msg, ts, md, metadata_keys])
    |> IO.chardata_to_string()
    |> String.trim()
  end
end
