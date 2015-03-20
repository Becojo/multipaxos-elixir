require Logger

defmodule Scout do
  def run(leader, acceptors, b) do
    Logger.debug "Scout #{inspect self} launched by #{inspect leader}"

    for a <- acceptors do
      send a, {:p1a, self(), b}
    end

    loop(leader, acceptors, b, acceptors, HashSet.new)
  end

  defp loop(leader, acceptors, b, waitfor, pvalues) do
    receive do
      {:p1b, a, bp, r} ->
        Logger.debug "Scout #{inspect self}: :p1b"

        if b == bp do
          pvalues = HashSet.union(pvalues, r)
          waitfor = List.delete(waitfor, a)

          if 2 * length(waitfor) <= length(acceptors) do
            send leader, {:adopted, b, pvalues}
          else
            loop(leader, acceptors, b, waitfor, pvalues)
          end
        else
          send leader, {:preempted, bp}
        end
    end
  end
end
