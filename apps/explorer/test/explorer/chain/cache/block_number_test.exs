defmodule Explorer.Chain.Cache.BlockNumberTest do
  use Explorer.DataCase

  alias Explorer.Chain.Cache.BlockNumber

  describe "max_number/0" do
    setup :cache_without_ttl

    test "returns max number" do
      insert(:block, number: 5)

      assert BlockNumber.max_number() == 5
    end
  end

  describe "min_number/0" do
    setup :cache_without_ttl

    test "returns max number" do
      insert(:block, number: 2)

      assert BlockNumber.max_number() == 2
    end
  end

  describe "update/1" do
    setup :cache_without_ttl

    test "updates max number" do
      insert(:block, number: 2)

      assert BlockNumber.max_number() == 2

      assert BlockNumber.update(3)

      assert BlockNumber.max_number() == 3
    end

    test "updates min number" do
      insert(:block, number: 2)

      assert BlockNumber.min_number() == 2

      assert BlockNumber.update(1)

      assert BlockNumber.min_number() == 1
    end
  end

  @tag :wip
  describe "with ttl" do
    setup :cache_with_ttl

    test "min_number/0" do
      insert(:block, number: 5)

      assert BlockNumber.min_number() == 5

      insert(:block, number: 3)

      assert BlockNumber.min_number() == 5

      Process.sleep(1_000)

      assert BlockNumber.min_number() == 3
    end

    test "max_number/0" do
      insert(:block, number: 3)

      assert BlockNumber.max_number() == 3

      insert(:block, number: 5)

      assert BlockNumber.max_number() == 3

      Process.sleep(1_000)

      assert BlockNumber.max_number() == 5
    end
  end

  defp cache_without_ttl(_) do
    Application.put_env(:explorer, BlockNumber, enabled: true)
    Supervisor.start_child(Explorer.Supervisor, BlockNumber.child_spec([]))

    on_exit(fn ->
      Supervisor.terminate_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Supervisor.delete_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Application.put_env(:explorer, BlockNumber, enabled: false)
    end)
  end

  defp cache_with_ttl(_) do
    Application.put_env(:explorer, BlockNumber, enabled: true, ttl: :timer.seconds(1))
    Supervisor.start_child(Explorer.Supervisor, BlockNumber.child_spec([]))

    on_exit(fn ->
      Supervisor.terminate_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Supervisor.delete_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Application.put_env(:explorer, BlockNumber, enabled: false)
    end)
  end
end
