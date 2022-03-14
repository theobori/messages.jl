module Server

using DotEnv
DotEnv.config()

include("utils.jl")
include("controller/requests.jl")
include("types.jl")
include("controller/network.jl")
include("controller/commands.jl")

using .Types, .Requests, Sockets, Dates

function is_valid_command(command::String)
    if (!startswith(command, "/"))
        return (false)
    end
    true
end

function parse_line!(command::String, conn::IO)
    if (is_valid_command(command) == false)
        return ([])
    end
    command = replace(command, "/" => "")
    command = split(command, " ")
    command
end

function wait_client(conn::IO, storage)
    line = readline(conn)
    parsed_line = parse_line!(line, conn)

    if (size(parsed_line)[1] > 0)
        Commands.exec_command(parsed_line, storage, conn)
    end
    Network.fancy_write(storage, conn)
    if (length(line) <= 0)
        return
    end
    Network.broadcast_channel(storage, line, conn)

    # Store logs in files
    Utils.log(conn, line)
end

function add_default_client(storage, ip_addr::String, conn::IO)
    storage.active_clients[ip_addr] = Client(ip_addr, conn)
end

function serve(port::Int)
    storage = Storage(listen(IPv4(0), port), SQL())
    Network.init_lobby!(storage)

    print("Server listening on port $port\n")
    while true
        conn = accept(storage.listener)
        ip_addr = string(first(getpeername(conn)))
        
        if (Network.is_connected(storage, ip_addr))
            write(conn, "Someone is already using this ip address ($ip_addr)\n")
            continue
        end

        write(conn, Types.welcome_msg)
        add_default_client(storage, ip_addr, conn)
        Network.fancy_write(storage, conn)

        @async begin
            try
                while isopen(conn)
                    wait_client(conn, storage)
                end
            catch err
                Network.disconnect!(storage, conn)
            end
        end
    end
end

export serve

end # Server
