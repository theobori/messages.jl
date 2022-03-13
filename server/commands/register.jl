function register(command::Vector{SubString{String}}, storage, conn::IO)
    if (command[3] != command[4])
        return (write(conn, "The passwords do not match\n"))
    end
    if (length(command[3]) < 6)
        return (write(conn, "The passwords must have more than 6 characters\n"))
    end
    
    name = command[2]
    password = String(Bcrypt.GenerateFromPassword(Array{UInt8,1}(command[3]), 0))
    response = Requests.insert_account(storage.sql_conn, name, password)

    if (response)
        write(conn, "Account successfully created ! Now you can use /login\n")
    else
        write(conn, "An account with the username $name already exists\n")
    end
end
