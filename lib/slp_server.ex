defmodule SLP.Server do
  use GenServer
  require Logger

  @commands [{:register, 1},{:deregister, 2},{:find_services, 3},{:find_attributes, 4}]

  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def init(:ok) do
    Logger.info "Starting SLP Port"
    Process.flag(:trap_exit, true)
    port = Port.open({:spawn, "#{:code.priv_dir(:slp)}/slp_port"}, [{:packet, 2}, :binary])
    {:ok, port}
  end

  # Passes arguments through to the C program as null separated strings.
  def handle_call {command, arguments}, _from, port do
    data = Enum.reduce arguments, <<>>, fn(arg, acc) -> acc <> <<0::8, arg::binary>>  end
    Port.command(port, <<@commands[command]::8>> <> data <> <<0::8>>)
    receive do
      {port, {:data, response}} -> {:reply, handle_response(response), port}
      {port, :closed} -> {:stop, :port_closed, port}
      {:EXIT,port,reason} -> {:stop, {:port_exited, reason}, port}
    end
  end

  defp handle_response "ok" do
    :ok
  end

  defp handle_response <<"ok: ", response::binary>> do
    {:ok, String.rstrip(response) |> String.split(["\n"])}
  end

  defp handle_response <<"error: ", errcode::binary>> do
    errstring = error_string[String.to_integer(errcode)]
    Logger.info("Error response from SLP: #{errcode} #{errstring}")
    {:error, errstring}
  end

  defp error_string do
    [{ 0, "Ok"},
     {-1, "Language not supported."},
     {-2, "Parse error."},
     {-3, "Invalid Registration"},
     {-4, "Scope not supported"},
     {-6, "Authentication absent"},
     {-7, "Authentication failed"},
     {-13, "Invalid update"},
     {-15, "Refresh rejected"},
     {-17, "Not implemented"},
     {-18, "Buffer overflow"},
     {-19, "Network timed out: Is slpd running?"},
     {-20, "Network init failed"},
     {-21, "Out of memory error"},
     {-22, "Parameter bad"},
     {-23, "Network error"},
     {-24, "Internal system error"},
     {-25, "Handle in use"},
     {-26, "Type error"}]
  end
end
