require Logger

defmodule Replica do
  defstruct slot_num: 1,
            proposals: %{},
            decisions: %{},
            leaders: []


  @type replica :: %Replica{}
  @type command :: {pid, integer, any}

  @spec propose(replica, command) :: replica
  def propose(replica, {b, s, o} = command) do
    # Logger.debug "Replica #{inspect self}: Replica.propose"
    # Logger.debug "decisions = #{inspect replica.decisions}"
    # Logger.debug "proposals = #{inspect replica.proposals}"

    unless Map.has_key?(replica.decisions, s) do
      sp = Stream.iterate(1, &(&1+1))
           |> Stream.drop_while(fn x -> Map.has_key?(replica.proposals, x) || Map.has_key?(replica.decisions, x) end)
           |> Enum.at(0)

      for leader <- replica.leaders do
        send leader, {:propose, sp, command}
      end

      %{replica | proposals: Map.put(replica.proposals, sp, command)}
    else
      Logger.debug "Replica #{inspect self}: already received a decision for this command #{inspect command}"
      replica
    end
  end

  @spec perform(replica, command) :: replica
  def perform(replica, command) do
    Logger.debug "Replica #{inspect self} perform decisison = #{inspect replica.decisions}"

    any = Enum.any?(1..(replica.slot_num - 1), fn s -> 
      replica.decisions[s] == command
    end)

    if not any do
      Logger.debug "Replica #{inspect self} running command #{inspect command}"
    end

    %{replica | slot_num: replica.slot_num + 1}
  end

  @spec decision(replica) :: replica
  def decision(replica) do
    c = replica.decisions[replica.slot_num]

    if c do
      c2 = replica.proposals[replica.slot_num]

      replica = if c2 && c2 == c do
        propose(replica, c2)
      else
        replica
      end

      perform(replica, c)
    else
      replica
    end
  end

  @spec run(replica) :: replica
  def run(replica) do
    receive do
      {:init, leaders} ->
        run(%{replica | leaders: leaders})

      {:request, p} ->
        Logger.debug "Replica #{inspect self}: :request"

        run(propose(replica, p))

      {:decision, s, p} ->
        Logger.debug "Replica #{inspect self}: :decision"

        replica = decision(%{replica | decisions: Map.put(replica.decisions, s, p)})
        run(replica)
    end
  end
end
