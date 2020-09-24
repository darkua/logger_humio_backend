defmodule Logger.Backend.Humio.IngestApi.Test do
  @behaviour Logger.Backend.Humio.IngestApi

  @logfile "test_log.log"

  @impl true
  def transmit(%{entries: entries, host: _host, token: _token, client: _client} = params) do
    File.write!(@logfile, entries)
    {:ok, params}
  end

  def read() do
    if exists() do
      File.read!(@logfile)
    end
  end

  def exists() do
    File.exists?(@logfile)
  end

  def destroy() do
    if exists() do
      File.rm!(@logfile)
    end
  end
end
