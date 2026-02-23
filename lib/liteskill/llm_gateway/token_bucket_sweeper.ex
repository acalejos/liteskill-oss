defmodule Liteskill.LlmGateway.TokenBucket.Sweeper do
  @moduledoc """
  Periodic sweeper that cleans stale LLM token bucket ETS entries.
  Runs every 60 seconds to remove expired window entries.
  """

  use GenServer

  # coveralls-ignore-start

  @sweep_interval_ms 60_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_sweep()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    Liteskill.LlmGateway.TokenBucket.sweep_stale()
    schedule_sweep()
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp schedule_sweep do
    Process.send_after(self(), :sweep, @sweep_interval_ms)
  end

  # coveralls-ignore-stop
end
