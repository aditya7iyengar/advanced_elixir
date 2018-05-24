defmodule NodePool.Node do
  defstruct [sup_name: nil, name: nil, capacity: 1, usage: 0]
end

defmodule NodePool do
  # def async_all(node_pool, enum, fun) do
  #   Enum.each(enum, &async(node_pool, fun, &1))
  # end

  def async(node_pool, fun, timeout \\ 100_000) do
    case find_capable_node(node_pool) do
      nil -> async(node_pool, fun)
      n -> Task.start_link(fn -> ship_to_node(node_pool, n, fun, timeout) end)
    end
  end

  # def async(node_pool, fun, arg) do
  # end

  defp ship_to_node(pid, n, fun, timeout) do
    inc_node_usage(pid, {n.sup_name, n.name})
    task = Task.Supervisor.async({n.sup_name, n.name}, fun, timeout: :infinity)
    Task.await(task, :infinity)
    dec_node_usage(pid, {n.sup_name, n.name})
  end

  def init(nodes \\ []), do: Agent.start_link(fn -> nodes end)
  defp get_nodes(pid), do: Agent.get(pid, & &1)
  defp get_node(pid, {sup_name, name}) do
    pid
    |> Agent.get(& &1)
    |> Enum.find(& &1.sup_name == sup_name && &1.name == name)
  end

  defp find_capable_node(pid) do
    pid
    |> get_nodes()
    |> Enum.find(fn node -> node_capable?(pid, node) end)
  end

  defp node_capable?(pid, n), do: n.capacity > n.usage

  defp inc_node_usage(pid, {sup_name, name}) do
    Agent.update(pid, fn nodes ->
        Enum.map(nodes, fn n ->
          case n.sup_name == sup_name && n.name == name do
            true -> %NodePool.Node{sup_name: n.sup_name, name: n.name,
              capacity: n.capacity, usage: n.usage + 1}
            _ -> n
          end
        end)
    end)
  end

  defp dec_node_usage(pid, {sup_name, name}) do
    Agent.update(pid, fn nodes ->
        Enum.map(nodes, fn n ->
          case n.sup_name == sup_name && n.name == name do
            true -> %NodePool.Node{sup_name: n.sup_name, name: n.name,
              capacity: n.capacity, usage: n.usage - 1}
            _ -> n
          end
        end)
    end)
  end
end
