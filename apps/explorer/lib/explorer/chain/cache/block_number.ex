defmodule Explorer.Chain.Cache.BlockNumber do
  @moduledoc """
  Cache for max and min block numbers.
  """

  alias Explorer.Chain

  @tab :block_number_cache
  @key "min_max"

  def child_spec(_) do
    interval = Application.get_env(:explorer, __MODULE__)[:ttl_check_interval] || false
    ttl = Application.get_env(:explorer, __MODULE__)[:global_ttl]

    Supervisor.child_spec(
      {
        ConCache,
        [
          name: @tab,
          ttl_check_interval: interval,
          global_ttl: ttl
        ]
      },
      id: {ConCache, @tab}
    )
  end

  def max_number do
    value(:max)
  end

  def min_number do
    value(:min)
  end

  def min_and_max_numbers do
    value(:all)
  end

  defp value(type) do
    {min, max} =
      if Application.get_env(:explorer, __MODULE__)[:enabled] do
        get_cache()
      else
        min_and_max_from_db()
      end

    case type do
      :max -> max
      :min -> min
      :all -> {min, max}
    end
  end

  defp get_cache do
    case ConCache.get(@tab, @key) do
      nil ->
        val = min_and_max_from_db()
        ConCache.put(@tab, @key, val)
        val

      val ->
        val
    end
  end

  @spec update(non_neg_integer()) :: boolean()
  def update(number) do
    if Application.get_env(:explorer, __MODULE__)[:enabled] do
      {old_min, old_max} = ConCache.get(@tab, @key)

      cond do
        number > old_max ->
          tuple = {old_min, number}
          ConCache.put(@tab, @key, tuple)

        number < old_min ->
          tuple = {number, old_max}
          ConCache.put(@tab, @key, tuple)

        true ->
          false
      end
    end
  end

  defp min_and_max_from_db do
    Chain.fetch_min_and_max_block_numbers()
  rescue
    _e ->
      {0, 0}
  end
end
