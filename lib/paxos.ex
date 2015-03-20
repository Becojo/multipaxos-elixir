require Logger
require Replica
require Leader
require Acceptor

defmodule Paxos do

  @type ballot_number :: {integer, pid}

  def start do
    acceptors_size = 3
    leaders_size = 2
    replicas_size = 2
    requests_size = 1
    
    acceptors = for _ <- 1..acceptors_size do
      spawn(fn -> Acceptor.run(%Acceptor{}) end)
    end

    replicas = for _ <- 1..replicas_size do
      spawn(fn -> Replica.run(%Replica{}) end)
    end

    leaders = for _ <- 1..leaders_size do
      spawn(fn -> Leader.run(%Leader{}) end)
    end

    for replica <- replicas do
      send replica, {:init, leaders}
    end

    for leader <- Enum.reverse(leaders) do
      send leader, {:init, replicas, acceptors}
    end



    :timer.sleep(3000)

    Logger.debug("sending commands...")

    for i <- 1..requests_size do
      for replica <- replicas do
        send replica, {:request, {self, 0, "operation:#{i}"}}
        :timer.sleep(500)
      end
    end

  end

end

Paxos.start
