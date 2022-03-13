function call(::Types.Who, args::Vector, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))

    user = storage.active_clients[ip_addr]
    fancy_write(storage, conn, "$(user.name) $(user.ip_addr)\n")
end
