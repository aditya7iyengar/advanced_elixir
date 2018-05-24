### First node
`$ iex --name node1@ip1 --cookie cookie`

```elixir
iex(node1@ip1)> defmodule X do
iex(node1@ip1)>   def loop(fun) do
iex(node1@ip1)>     fun.()
iex(node1@ip1)>     loop(fun)
iex(node1@ip1)>   end
iex(node1@ip1)> end
iex(node1@ip1)> child = spawn(fn -> X.loop(fn ->
iex(node1@ip1)>   receive do
iex(node1@ip1)>     {from, "Hi"} -> IO.puts "#{from} says Hi"
iex(node1@ip1)>   end
iex(node1@ip1)>   end)
iex(node1@ip1)> end)
iex(node1@ip1)> :global.register_name(:receiver, child)
```

### Second node
`$ iex --name node2@ip2 --cookie cookie`

```elixir
iex(node2@ip2)> Node.connect(:"node1@ip1")
iex(node2@ip2)> :receiver |> :global.whereis_name() |> send({"node2@ip2", "Hi"})
```

