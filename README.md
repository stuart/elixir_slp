# Elixir SLP

This is an application for accessing Service Location Protocol (SLP) services with
Elixir. SLP is a widely used service discovery protocol.

See the [Open SLP](http://www.openslp.org/) site for more information on SLP.

## Installation

This package requires that the OpenSLP library is installed.
It can be found at http://www.openslp.org/download.html

On OSX you can use ```brew install openslp``` in Linux it is likely that
your package manager has the library.

  1. Add slp to your list of dependencies in `mix.exs`:

        def deps do
          [{:slp, "~> 0.0.1"}]
        end

  2. Ensure that the slpd daemon is running and available on the network.

  2. Ensure the slp Elixir application is started before your application:

        def application do
          [applications: [:slp]]
        end

## Usage

You can advertise services on SLP with the register command.

    iex> SLP.register("my.service:http://10.1.1.1:5560", [location: "australia"], 65535)
    :ok

To find registered services use the find_services command.

    iex> SLP.find_services("my.service")
    ["my.service:http://10.1.1.1:5560"]

## Architecture

This application uses a C port program (slp_port) to make library calls.
