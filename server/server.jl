module Server

include("models/data.jl")
include("controller/commands.jl")

using .Data, Sockets, Dates

function error_command(command::String)::Bool
    command = split(command, " ")
    return any([command[1] == "/$key" for (key, _) in Commands.commands_ref])
end

function is_valid_command(command::String, conn::IO)
    if (!startswith(command, "/"))
        return (false)
    end
    if (!error_command(command))
        write(conn, "The command $command doesnt exist\n")
        return (false)
    end
    return (true)
end

function parse_line(command::String, conn::IO)
    if (!is_valid_command(command, conn))
        return ([])
    end
    command = replace(command, "/" => "")
    command = split(command, " ")
    return (command)
end

function wait_client(conn::IO, s::Storage)
    line = readline(conn)
    parsed_line = parse_line(line, conn)

    # Store logs into logs/
    current = string(now())
    date = current[1:10]
    time = current[12:19]
    ip_addr = string(first(getpeername(conn)))

    open("logs/$date.log", "a+") do f
        write(f, "$ip_addr -> $time -> $line\n")
    end


    if (size(parsed_line)[1] > 0)
        Commands.exec_command(parsed_line, s, conn)
    else
        Commands.broadcast_channel(s, line, conn)
    end
    Commands.fancy_write(s, conn, "")
end

function serve(port::Int)
    storage = Storage(listen(IPv4(0), port), Dict(), Dict())
    Commands.init_lobby(storage)

    print("Server listening on port $port\n")
    while true
        conn = accept(storage.listener)
        write(conn, Data.welcome_msg)

        @async begin
            try
                while isopen(conn)
                    wait_client(conn, storage)
                end
            catch err
                Commands.disconnect(storage, conn)
            end
        end
    end
end

export serve

end # Server
