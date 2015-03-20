require Logger

defmodule Leader do
  defstruct ballot_number: {0, nil},
            active: false,
            proposals: %{},
            acceptors: [],
            replicas: []


  @type leader :: %Leader{}

  @spec run(leader) :: leader
  def run(leader) do
    receive do
      {:init, replicas, acceptors} ->
        pid = self
        leader = %Leader{
          ballot_number: {0, self},
          replicas: replicas,
          acceptors: acceptors}

        spawn fn ->
          Scout.run(pid, leader.acceptors, leader.ballot_number)
        end

        run(leader)

      {:propose, s, p} ->

        Logger.debug("Leader #{inspect self}: :propose")


        proposals = Map.put(leader.proposals, s, p)

        if leader.active do
          parent = self
          spawn fn ->
            Commander.run(parent, leader.acceptors, leader.replicas, {leader.ballot_number, s, p})
          end
        end

        run(%{leader | proposals: proposals})

      {:adopted, ballot_number, pvals} ->
        proposals = leader.proposals

        Logger.debug("Leader #{inspect self}: :adopted, proposals = #{inspect proposals}")

        run(%{leader | active: true})

      {:preempted, {round, pid} = ballot} ->
        Logger.debug("Leader #{inspect self}: :preempted")
        if ballot > leader.ballot_number do
          next = %{leader | ballot_number: {round + 1, self}, active: false}
          pid = self

          Logger.debug("incrementing round: #{inspect next}")

          spawn fn ->
            Scout.run(pid, leader.acceptors, next.ballot_number)
          end

          run(next)
        end
    end
  end

end
