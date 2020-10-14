defmodule Logger.Backend.Humio.IngestApiTest do
  @moduledoc """
  Tests of the common functionality for all ingest APIs, primarily related to message formatting.
  """
  use ExUnit.Case, async: true

  alias Logger.Backend.Humio.IngestApi

  test "can configure metadata" do
    metadata = [auth: true, user_id: 13]
    assert [auth: true] == IngestApi.take_metadata(metadata, [:auth])
  end

  test "can parse :all metadata" do
    metadata = [auth: true, user_id: 13]
    assert metadata == IngestApi.take_metadata(metadata, :all)
  end

  test "can format multi-line messages" do
    format = Logger.Formatter.compile("$metadata$message\n")

    formatted_message =
      IngestApi.format_message(
        %{
          message: "hello\nworld",
          level: :info,
          timestamp: get_timestamp(),
          metadata: [auth: true]
        },
        format,
        :all
      )

    assert formatted_message == "auth=true hello\nauth=true world\n"
  end

  test "generates headers appropriate for Humio" do
    token = "token"
    content_type = "content_type"

    assert [{"Authorization", "Bearer " <> token}, {"Content-Type", content_type}] ==
             IngestApi.generate_headers(token, content_type)
  end

  # The Logger timestamp format is weird.  This helper gets you a valid one.
  defp get_timestamp do
    DateTime.utc_now()
    |> to_logger_timestamp()
  end

  defp to_logger_timestamp(dateTime) do
    {microsecond, _} = dateTime.microsecond

    {
      {dateTime.year, dateTime.month, dateTime.day},
      {dateTime.hour, dateTime.minute, dateTime.second, div(microsecond, 1000)}
    }
  end
end
