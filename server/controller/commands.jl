module Commands

include("../types.jl")
include("../requests.jl")

using .Types, Bcrypt, Sockets

function init_lobby!(storage)
    arr = Requests.get_lobby(storage.sql_conn)

    if (length(arr) == 0)
        return
    end

    arr = map(x -> string(x), arr)
    storage.active_channels[arr[1]] = Types.Channel(arr[1], arr[2], arr[3],
        parse(Int64, arr[4]), arr[5], arr[6])
end

function is_logged(storage, ip_addr::String)
    ip_addr in [key for (key, _) in storage.active_clients]
end

function disconnect!(storage, conn::IO)
    for (key, value) in storage.active_clients
        if (isopen(value.conn) == false)
            delete!(storage.active_clients, key)
        end
    end
end

function broadcast_channel(storage, msg::String, conn::IO)
    ip_addr = string(first(getpeername(conn)))

    if (is_logged(storage, ip_addr) == false)
        return
    end

    client = storage.active_clients[ip_addr]
    channel_id = client.current_channel_id

    for (target_ip, value) in storage.active_clients
        if (value.current_channel_id == channel_id && value.id != client.id)

            user = storage.active_clients[ip_addr]
            channel_name = storage.active_channels[channel_id].name
            PS1 = "[$channel_name][$(user.name)] -> "

            if (isopen(value.conn))
                write(value.conn, "\n" * PS1 * msg * "\n")
                fancy_write(storage, value.conn, "")
            end
        end
    end
end

function channel_exist(storage, id::String)
    id in [key for (key, _) in storage.active_channels]
end

function fancy_write(storage, conn::IO, msg::String)
    ip_addr = string(first(getpeername(conn)))

    if (is_logged(storage, ip_addr) == false)
        return (write(conn, msg))
    end
    client = storage.active_clients[ip_addr]
    username = client.name
    channel_id = client.current_channel_id
    channel_name = storage.active_channels[channel_id].name
    PS1 = "[$channel_name][$username] "
    write(conn, PS1 * msg)
end

include("../commands/create.jl")
include("../commands/help.jl")
include("../commands/join.jl")
include("../commands/leave.jl")
include("../commands/login.jl")
include("../commands/register.jl")
include("../commands/who.jl")
include("../commands/unknown.jl")

function is_command_error(command::Vector{SubString{String}})
    size(command)[1] - 1 < commands_ref[command[1]][2]
end

function exec_command(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    command_name = String(command[1])
    args = command[2:length(command)]
    commandInfos = getCommandInfos(command_name)

    if (is_logged(storage, ip_addr) == false && commandInfos.auth == true)
        return (write(conn, "You must be logged in to use this command\n"))
    end
    if (size(args)[1] < commandInfos.args_amount)
        return (write(conn, "Invalid number of arguments\n"))
    end

    call(commandInfos, args, storage, conn)
end

end # Commands