defmodule SLP.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [worker(SLP.Server, [[name: :slp_port]]),]
    supervise(children, strategy: :one_for_one)
  end
end
