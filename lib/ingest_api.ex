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
          metadata_keys: list() | :all,
          utc_offset: String.t()
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
        metadata_keys
      ) do
    msg
    |> IO.chardata_to_string()
    |> String.split("\n")
    |> filter_empty_strings
    |> Enum.map(&format_event(level, &1, ts, md, format, metadata_keys))
    |> Enum.join("")
  end

  defp format_event(level, msg, ts, md, format, metadata_keys) do
    Logger.Formatter.format(format, level, msg, ts, take_metadata(md, metadata_keys))
  end

  defp filter_empty_strings(strings) do
    strings
    |> Enum.reject(&(String.trim(&1) == ""))
  end
end
