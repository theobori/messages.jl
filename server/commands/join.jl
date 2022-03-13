function call(::Types.Join, args::Vector, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    name = args[1]
    arr = Requests.get_channel(storage.sql_conn, name)

    if (length(arr) == 0)
        return (write(conn, "This channel doesnt exist\n"))
    end

    if (arr.protected == 1)
        if (length(args) != 2)
            return (write(conn, "This channel required a password\n"))
        end
        if (Bcrypt.CompareHashAndPassword(arr.password, String(args[2])) == false)
            return (write(conn, "Invalid password\n"))
        end
    end

    storage.active_clients[ip_addr].current_channel_id = string(arr.id)
    if (channel_exist(storage, string(arr.id)) == false)
        storage.active_channels[string(arr.id)] = Types.Channel(string(arr.id), 
        arr.name, arr.description, arr.protected, arr.password, string(arr.owner))
    end
    write(conn, "Successfully joined\n")
end