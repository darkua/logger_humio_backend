defmodule Logger.Backend.Humio.IngestApi.Test do
  @moduledoc """
  This Ingest API implementation is designed for testing.

  It writes entries to @logfile contains convenience functions for reading back what was logged and cleaning up the generated file.
  """
  @behaviour Logger.Backend.Humio.IngestApi

  @impl true
  def transmit(params) do
    GenServer.cast(__MODULE__, {:transmit, params})
    {:ok, %{response: 200, body: "great success!"}}
  end

  use GenServer

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid, name: __MODULE__)
  end

  @impl true
  def init(pid) do
    {:ok, %{pid: pid}}
  end

  @impl true
  def handle_cast({:transmit, params}, %{pid: pid} = state) do
    send(pid, {:transmit, params})
    {:noreply, state}
  end
end
