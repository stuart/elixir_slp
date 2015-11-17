defmodule SLPServerTest do
  use ExUnit.Case

  test "init starts the slp_port program" do
    {:ok, port} = SLP.Server.init(:ok)
    info = Port.info(port)
    assert Keyword.get(info, :connected) == self
    assert String.ends_with?(List.to_string(Keyword.get(info, :name)), "slp_port")
  end
end
