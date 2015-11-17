defmodule SLP do
  use Application
  @type slp_response :: :ok | {:ok, [key: binary]} | {:error, binary}

  def start(_type, _args) do
   SLP.Supervisor.start_link()
  end

  @doc ~S"""
    Registers a service with SLP.

    ## Parameters

      * service_url : string which must conform to the SLP Service URL format.
      * attributes : A list of attributes to set on the record.
      * lifetime : The number of seconds the service will be registered for.
        Must be an integer less than or equal to 65535. If set to 65535 the service will be
        registered for the lifetime of the SLP application.

    ## Examples
        iex> SLP.register "foo.bar:http://127.0.0.1:3000"
        :ok
        iex> SLP.register "foo.bar:http://127.0.0.1:3001", [foo: "bar", bar: "baz"], 65535
        :ok
        iex> SLP.register "foo.bar", [foo: "bar", bar: "baz"], 3000
        {:error, "Invalid Registration"}
        iex> SLP.deregister "foo.bar:http://127.0.0.1:3000"
        ...> SLP.deregister "foo.bar:http://127.0.0.1:3001"
        :ok

  """
  @spec register(binary, [key: binary], integer) :: slp_response
  def register service_url, attributes \\ [], lifetime \\ 10800 do
    GenServer.call :slp_port, {:register, [service_url, convert_attributes(attributes), <<lifetime::16>>]}, timeout
  end

  @doc ~S"""
    Deregisters a service from SLP.

    Returns an error if the url is not already registered.

    ## Parameters:

      * service_url : string which must conform to the SLP Service URL format.

    ## Examples

        iex> SLP.register "foo.bar:http://127.0.0.1:3002", [foo: "bar", bar: "baz"], 3000
        :ok
        iex> SLP.deregister "foo.bar:http://127.0.0.1:3002"
        :ok
        iex> SLP.deregister "foo.bar:http://127.0.0.1:3002"
        {:error, "Invalid Registration"}

  """
  @spec register(binary) :: slp_response
  def deregister service_url do
    GenServer.call :slp_port, {:deregister, [service_url]}, timeout
  end

  @doc ~S"""
    Finds services that are registered with SLP.

    ## Parameters

      * service_type : string which must conform to the SLP Service type format.
      * scope_list : A list of scopes to search.
      * filter : An LDAPv3 search filter to apply to the search. Omit this to include all results.

    ## Examples
      iex> SLP.register "foo.bar:http://127.0.0.1:3003"
      ...> SLP.register "foo.bar:http://127.0.0.1:3004"
      ...> SLP.find_services "foo.bar"
      {:ok, ["foo.bar:http://127.0.0.1:3003","foo.bar:http://127.0.0.1:3004"]}
  """
  def find_services service_type, scope_list \\[], filter \\"" do
    GenServer.call(:slp_port, {:find_services, [service_type, convert_scopes(scope_list), filter]}, timeout)
  end

  defp timeout do
    Application.get_env(:slp, :timeout, 5000)
  end

  # [foo: "bar", bar: "baz"] -> "(foo=bar),(bar=baz)"
  defp convert_attributes attrs do
    Enum.map(attrs, fn({k,v}) -> <<"(",to_string(k)::binary,"=",to_string(v)::binary, ")">> end)
      |> Enum.join(",")
  end

  defp convert_scopes scopelist do
    Enum.join(scopelist, ",")
  end
end
