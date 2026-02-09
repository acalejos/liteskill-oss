defmodule Liteskill.Aggregate.Loader do
  @moduledoc """
  Stateless aggregate loader.

  Loads aggregate state by reading events from the event store (with optional
  snapshot support), and executes commands by loading state, handling the command,
  and appending resulting events.
  """

  alias Liteskill.EventStore.Postgres, as: Store

  @doc """
  Loads the current state of an aggregate from the event store.

  If a snapshot exists, loads from the snapshot version forward.
  Otherwise replays all events from the beginning.
  """
  def load(aggregate_module, stream_id) do
    {state, version} =
      case Store.get_latest_snapshot(stream_id) do
        {:ok, snapshot} ->
          state = struct(aggregate_module, atomize_keys(snapshot.data))
          {state, snapshot.stream_version}

        {:error, :not_found} ->
          {aggregate_module.init(), 0}
      end

    events = Store.read_stream_forward(stream_id, version + 1, 10_000)

    final_state =
      Enum.reduce(events, state, fn event, acc ->
        aggregate_module.apply_event(acc, event)
      end)

    current_version = if events == [], do: version, else: List.last(events).stream_version
    {final_state, current_version}
  end

  @doc """
  Executes a command against an aggregate.

  Loads the aggregate state, handles the command, and appends
  resulting events to the event store. Returns the updated state
  and new events on success.
  """
  def execute(aggregate_module, stream_id, command) do
    {state, version} = load(aggregate_module, stream_id)

    case aggregate_module.handle_command(state, command) do
      {:ok, events_data} when events_data == [] ->
        {:ok, state, []}

      {:ok, events_data} ->
        case Store.append_events(stream_id, version, events_data) do
          {:ok, stored_events} ->
            new_state =
              Enum.reduce(stored_events, state, fn event, acc ->
                aggregate_module.apply_event(acc, event)
              end)

            {:ok, new_state, stored_events}

          # coveralls-ignore-next-line
          {:error, :wrong_expected_version} ->
            {:error, :wrong_expected_version}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      # coveralls-ignore-next-line
      {key, value} -> {key, value}
    end)
  end
end
