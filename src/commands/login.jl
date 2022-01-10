function login(command::Vector{SubString{String}}, storage, conn::IO)
    name = command[2]
    ip_addr = string(first(getpeername(conn)))

    if (is_logged(storage, ip_addr))
        return (write(conn, "There already is a connection with this IP address\n"))
    end
    if (name in [value.name for (_, value) in storage.active_clients])
        return (write(conn, "This account is already used\n"))
    end

    response = DBInterface.execute(mysql_conn, """SELECT id, password, name
    FROM user WHERE name='$name'""")

    if (length(response) == 0)
        return (write(conn, "Invalid username or password\n"))
    end
    password = String(command[3])
    arr = map(x -> string(x), first(response))
    if (Bcrypt.CompareHashAndPassword(arr[2], password) == false)
        return (write(conn, "Invalid username or password\n"))
    end
    write(conn, "Successfully logged in\n")

    storage.active_clients[ip_addr] = Client(arr[1], arr[3], ip_addr, "1", conn)
end