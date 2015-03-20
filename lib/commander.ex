require Logger

defmodule Commander do

  def run(leader, acceptors, replicas, c) do
    Logger.debug "Commander #{inspect self} launched by #{inspect leader}"
    for a <- acceptors do
      send a, {:p2a, self(), c}
    end

    loop(leader, acceptors, replicas, c, acceptors)
  end

  defp loop(leader, acceptors, replicas, {b, s, p} = command, waitfor) do
    receive do
      {:p2b, a, bp} ->
        Logger.debug "Commander #{inspect self}: :p2b from Acceptor #{inspect a}"

        if b == bp do
          waitfor = List.delete(waitfor, a)

          if 2 * length(waitfor) <= length(acceptors) do
            for replica <- replicas do
              send replica, {:decision, s, p}
            end
          else
            loop(leader, acceptors, replicas, command, waitfor)
          end
        else
          send leader, {:preempted, bp}
        end
    end
  end
end
