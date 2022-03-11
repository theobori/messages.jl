function create_channel(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    name = command[2]
    password = length(command) - 1 != 2 ? "no password" : 
    String(Bcrypt.GenerateFromPassword(Array{UInt8,1}(command[3]), 0))
    protected = password == "no password" ? 0 : 1
    user_id = storage.active_clients[ip_addr].id

    try
        DBInterface.execute(mysql_conn, """INSERT INTO channel (name,
        description, protected, password, owner) VALUES ('$name', 
        'tmp', $protected, '$password', $user_id)""")
        write(conn, "Successfully created the channel $name\n")
    catch err
        return (write(conn, "A channel with the name $name already exists\n"))
    end
end