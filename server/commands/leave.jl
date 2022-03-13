function call(::Types.Leave, args::Vector, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    client = storage.active_clients[ip_addr]
    channel = storage.active_channels[client.current_channel_id]

    if (client.current_channel_id == "1")
        return (write(conn, "You can't leave the lobby\n"))
    end
    client.current_channel_id = "1"
    write(conn, "You left the channel $(channel.name)\n")
end
