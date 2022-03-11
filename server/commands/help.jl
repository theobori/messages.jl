function help(command::Vector{SubString{String}}, storage, conn::IO)
    write(conn, Data.help_msg)
end