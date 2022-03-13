function call(::Types.Register, args::Vector, storage, conn::IO)
    if (args[2] != args[3])
        return (write(conn, "The passwords do not match\n"))
    end
    if (length(args[2]) < 6)
        return (write(conn, "The passwords must have more than 6 characters\n"))
    end
    
    name = args[1]
    password = String(Bcrypt.GenerateFromPassword(Array{UInt8,1}(args[2]), 0))
    response = Requests.insert_account(storage.sql_conn, name, password)

    if (response)
        write(conn, "Account successfully created ! Now you can use /login\n")
    else
        write(conn, "An account with the username $name already exists\n")
    end
end
