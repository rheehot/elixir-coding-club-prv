schedulers = :erlang.system_info(:schedulers)
repeat = 10000
keys = 1000

bench_read = fn {cache_mod, cache, tasks} ->
  task_repeat = repeat |> div(tasks)

  1..tasks
  |> Task.async_stream(fn _ ->
    1..task_repeat
    |> Enum.each(fn _ -> cache_mod.get(cache, :rand.uniform(keys)) end)
  end)
  |> Stream.run()
end

setup_cache = fn cache_mod, tasks ->
  kv = Enum.zip(1..keys, StreamData.term() |> Enum.take(keys))

  {:ok, cache} = cache_mod.start_link()

  kv
  |> Enum.each(fn {key, value} ->
    cache_mod.set(cache, key, value)
  end)

  {cache_mod, cache, tasks}
end

Benchee.run(
  [AgentCache, EtsCache]
  |> Enum.map(fn cache_mod ->
    {cache_mod, {bench_read, before_scenario: fn tasks -> setup_cache.(cache_mod, tasks) end}}
  end),
  inputs: [1, schedulers] |> Enum.map(fn tasks -> {%{tasks: tasks} |> inspect(), tasks} end)
)
