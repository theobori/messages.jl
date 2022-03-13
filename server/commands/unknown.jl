function call(::Types.Unknown, args::Vector, storage, conn::IO)
    write(conn, "This command doesn't exist, you can check /help\n")
end