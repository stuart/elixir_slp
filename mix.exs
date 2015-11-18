defmodule Slpex.Mixfile do
  use Mix.Project

  def project do
    [app: :slp,
     version: "0.0.2",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "SLP",
     description: description,
     package: package,
     source_url: "https://github.com/stuart/elixir_slp",
     homepage_url: "http://github.com/stuart/elixir_slp",
     compilers: [:make, :elixir, :app],
     aliases: aliases,
     deps: deps]
  end

  def application do
    [applications: [:logger],
     mod: {SLP, []}]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.10", only: :dev}]
  end

  defp aliases do
    [clean: ["clean", "clean.make"]]
  end

  defp package do
    [ maintainers: ["Stuart Coyle"],
      links: %{"Github" => "https://github.com/stuart/elixir_slp"},
      licenses: ["MIT"],
      files: ["src","lib","mix.exs", "Makefile", "LICENCE*", "README*"]]
  end

  defp description do
    """
    An Elixir application for using the Service Location Protocol.
    SLP is a commonly used service discovery protocol.
    """
  end
end

# Make the C code.
defmodule Mix.Tasks.Compile.Make do
  def run(_) do
    {result, _error_code} = System.cmd("make", [], stderr_to_stdout: true)
    Mix.shell.info result
    :ok
  end
end

defmodule Mix.Tasks.Clean.Make do
  def run(_) do
    {result, _error_code} = System.cmd("make", ['clean'], stderr_to_stdout: true)
    Mix.shell.info result
    :ok
  end
end
