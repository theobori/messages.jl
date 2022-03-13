function call(::Types.Login, args::Vector, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    name = args[1]

    if (name in [value.name for (_, value) in storage.active_clients])
        return (write(conn, "This account is already used\n"))
    end

    arr = Requests.get_account(storage.sql_conn, name)

    if (length(arr) == 0)
        return (write(conn, "Invalid username or password\n"))
    end
    password = String(args[2])
    arr = map(x -> string(x), arr)
    if (Bcrypt.CompareHashAndPassword(arr[2], password) == false)
        return (write(conn, "Invalid username or password\n"))
    end
    write(conn, "Successfully logged in\n")

    storage.active_clients[ip_addr].id = arr[1]
    storage.active_clients[ip_addr].name = name
    storage.active_clients[ip_addr].is_auth = true
    storage.active_clients[ip_addr].current_channel_id = "1"
end
