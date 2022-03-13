function call(::Types.Create, args::Vector, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    name = args[1]
    password = "no password"

    if (length(args) == 2)
        password = String(Bcrypt.GenerateFromPassword(Array{UInt8,1}(args[2]), 0))
    end

    protected = password == "no password" ? 0 : 1
    user_id = storage.active_clients[ip_addr].id

    response = Requests.insert_channel(
        storage.sql_conn, name, 
        protected, password, 
        user_id)

    if (response)
        write(conn, "Successfully created the channel $name\n")
    else
        write(conn, "A channel with the name $name already exists\n")
    end
end