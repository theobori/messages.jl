function call(::Types.Help, args::Vector, storage, conn::IO)
    write(conn, Types.help_msg)
end
