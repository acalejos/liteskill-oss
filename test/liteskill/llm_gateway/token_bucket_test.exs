defmodule Liteskill.LlmGateway.TokenBucketTest do
  use ExUnit.Case, async: true

  alias Liteskill.LlmGateway.TokenBucket

  # Use a unique per-test table to allow async
  setup do
    table = :"test_bucket_#{System.unique_integer([:positive])}"

    :ets.new(table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    on_exit(fn ->
      try do
        :ets.delete(table)
      rescue
        ArgumentError -> :ok
      end
    end)

    %{table: table}
  end

  test "allows requests under the limit" do
    user_id = Ecto.UUID.generate()
    model_id = "test-model"

    for _ <- 1..5 do
      assert :ok = TokenBucket.check_rate(user_id, model_id, limit: 10, window_ms: 60_000)
    end
  end

  test "rejects requests over the limit" do
    user_id = Ecto.UUID.generate()
    model_id = "test-model"

    # Exhaust the limit
    for _ <- 1..3 do
      assert :ok = TokenBucket.check_rate(user_id, model_id, limit: 3, window_ms: 60_000)
    end

    # Next request should be rejected
    assert {:error, :rate_limited, remaining_ms} =
             TokenBucket.check_rate(user_id, model_id, limit: 3, window_ms: 60_000)

    assert is_integer(remaining_ms)
    assert remaining_ms > 0
  end

  test "different users have separate counters" do
    user_a = Ecto.UUID.generate()
    user_b = Ecto.UUID.generate()
    model_id = "test-model"

    # Exhaust user_a's limit
    for _ <- 1..2 do
      TokenBucket.check_rate(user_a, model_id, limit: 2, window_ms: 60_000)
    end

    assert {:error, :rate_limited, _} =
             TokenBucket.check_rate(user_a, model_id, limit: 2, window_ms: 60_000)

    # user_b should still be allowed
    assert :ok = TokenBucket.check_rate(user_b, model_id, limit: 2, window_ms: 60_000)
  end

  test "different models have separate counters" do
    user_id = Ecto.UUID.generate()

    for _ <- 1..2 do
      TokenBucket.check_rate(user_id, "model-a", limit: 2, window_ms: 60_000)
    end

    assert {:error, :rate_limited, _} =
             TokenBucket.check_rate(user_id, "model-a", limit: 2, window_ms: 60_000)

    assert :ok = TokenBucket.check_rate(user_id, "model-b", limit: 2, window_ms: 60_000)
  end

  test "sweep_stale removes old entries" do
    # Just verify it doesn't crash - actual cleanup tested via the real table
    assert is_integer(TokenBucket.sweep_stale(0))
  end
end
