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
  @spec deregister(binary) :: slp_response
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
  @spec find_services(binary, [binary], binary) :: slp_response
  def find_services service_type, scope_list \\[], filter \\"" do
    GenServer.call(:slp_port, {:find_services, [service_type, convert_scopes(scope_list), filter]}, timeout)
  end

  @doc ~S"""

    Returns the attributes set on a registered service.

    ## Parameters

    * service_url : string which must conform to the SLP Service url format.
    * attributes : A list of attributes to return.
    * scope_list  : A list of scopes to search.

    ## Examples

      iex> SLP.register "foo.bar:http://127.0.0..1:3005", [foo: "bar", bar: "baz"]
      ...> SLP.find_attributes "foo.bar:http://127.0.0..1:3005", [:foo, :bar]
      {:ok, [foo: "bar", bar: "baz"]}
      iex> SLP.deregister "foo.bar:http://127.0.0..1:3005"
      :ok

  """
  @spec find_attributes(binary, [key: binary], [binary]) :: slp_response
  def find_attributes service_url, attributes \\ [], scope_list \\ [] do
    result = GenServer.call(:slp_port, {:find_attributes, [service_url, convert_scopes(attributes), convert_scopes(scope_list)]}, timeout)
    case result do
      {:ok, attrs} -> {:ok, deconvert_attributes(attrs)}
      r -> r
    end
  end

  defp timeout do
    Application.get_env(:slp, :timeout, 5000)
  end

  # [foo: "bar", bar: "baz"] -> "(foo=bar),(bar=baz)"
  defp convert_attributes attrs do
    Enum.map(attrs, fn({k,v}) -> <<"(",to_string(k)::binary,"=",to_string(v)::binary, ")">> end)
      |> Enum.join(",")
  end


  defp deconvert_attributes attributes do
    deconvert_attributes attributes, []
  end

  defp deconvert_attributes [], result do
    result
  end

  defp deconvert_attributes [line | rest ], result do
    attr_list = String.split(line, ",") |> Enum.map(fn(attr) -> deconvert_attribute(attr) end)
    deconvert_attributes(rest, attr_list ++ result)
  end

  defp deconvert_attribute attr do
    ["", k, v, ""] = String.split(attr, ["(", "=", ")"])
    {String.to_atom(k), v}
  end

  defp convert_scopes scopelist do
    Enum.join(scopelist, ",")
  end
end
