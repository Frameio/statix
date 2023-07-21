defmodule Statix.Conn do
  @moduledoc false

  defstruct [:sock, :header]

  alias Statix.Packet

  require Logger

  def new(host, port) when is_binary(host) do
    new(String.to_charlist(host), port)
  end

  def new(host, port) when is_list(host) or is_tuple(host) do
    case :inet.getaddr(host, :inet) do
      {:ok, address} ->
        header = Packet.header(address, port)
        {:ok, sock} = :gen_udp.open(0, active: false)
        %__MODULE__{header: header, sock: sock}

      {:error, reason} ->
        raise(
          "cannot get the IP address for the provided host " <>
            "due to reason: #{:inet.format_error(reason)}"
        )
    end
  end

  def transmit(%__MODULE__{header: header, sock: sock}, type, key, val, options)
      when is_binary(val) and is_list(options) do
    packet = Packet.build(header, type, key, val, options)
    :gen_udp.send(sock, packet)
  end
end
