module Server

include("models/types.jl")
include("controller/commands.jl")

using .Data, Sockets, Dates

function error_command!(command::String)::Bool
    command = split(command, " ")
    any([command[1] == "/$key" for (key, _) in Commands.commands_ref])
end

function is_valid_command(command::String, conn::IO)
    if (!startswith(command, "/"))
        return (false)
    end
    if (!error_command!(command))
        write(conn, "The command $command doesnt exist\n")
        return (false)
    end
    return (true)
end

function parse_line!(command::String, conn::IO)
    if (!is_valid_command(command, conn))
        return ([])
    end
    command = replace(command, "/" => "")
    command = split(command, " ")
    command
end

function log(conn::IO, line::String, file::String)
    current = string(now())
    time = current[12:19]
    ip_addr = string(first(getpeername(conn)))

    open(file, "a+") do f
        write(f, "$ip_addr -> $time -> $line\n")
    end
end

log(conn::IO, line::String) = log(conn, line, "./logs/$(string(now())[1:10]).log")


function wait_client(conn::IO, s::Storage)
    line = readline(conn)
    parsed_line = parse_line!(line, conn)

    if (size(parsed_line)[1] > 0)
        Commands.exec_command(parsed_line, s, conn)
    end
    Commands.fancy_write(s, conn, "")
    if (length(line) <= 0)
        return
    end
    Commands.broadcast_channel(s, line, conn)

    # Store logs in files
    log(conn, line)

end

function serve(port::Int)
    storage = Storage(listen(IPv4(0), port), Dict(), Dict())
    Commands.init_lobby!(storage)

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
                Commands.disconnect!(storage, conn)
            end
        end
    end
end

export serve

end # Server