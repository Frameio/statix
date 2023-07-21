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
    result =
      header
      |> Packet.build(type, key, val, options)
      |> transmit(sock)

    if result == {:error, :port_closed} do
      Logger.error(fn ->
        if(is_atom(sock), do: "", else: "Statix ") <>
          "#{inspect(sock)} #{type} metric \"#{key}\" lost value #{val}" <> " due to port closure"
      end)
    end

    result
  end

  defp transmit(packet, sock) do
    try do
      :gen_udp.send(sock, packet)
    rescue
      ArgumentError ->
        {:error, :port_closed}
    else
      true ->
        receive do
          {:inet_reply, _port, status} -> status
        end
    end
  end
end
