require Logger

defmodule Acceptor do

  defstruct ballot_number: nil,
            accepted: HashSet.new

  @type acceptor :: %Acceptor{}
  @spec run(acceptor) :: acceptor

  def run(acceptor) do
    receive do
      {:p1a, scout, b} ->
      	Logger.debug "Acceptor #{inspect self}: :p1a acceptor.ballot_number=#{inspect acceptor.ballot_number} b=#{inspect b}"

      	number = if acceptor.ballot_number == nil || b > acceptor.ballot_number, do: b, else: acceptor.ballot_number
      	send(scout, {:p1b, self, number, acceptor.accepted})

        run(%{acceptor | ballot_number: number})

      {:p2a, commander, {b, s, p} = command} ->
      	Logger.debug "Acceptor #{inspect self}: :p2a"

      	result = if b >= acceptor.ballot_number do
      	  %{acceptor | ballot_number: b, 
                       accepted: HashSet.put(acceptor.accepted, command)}
      	else
      	  acceptor
      	end

      	send commander, {:p2b, self(), result.ballot_number}

        run(result)
    end
  end
end
