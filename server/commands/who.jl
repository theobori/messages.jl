function who(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))

    user = storage.active_clients[ip_addr]
    fancy_write(storage, conn, "$(user.name) $(user.ip_addr)\n")
end