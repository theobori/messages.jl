module Network 

include("../controller/requests.jl")
include("../types.jl")
include("../utils.jl")

using .Types, .Utils, Sockets

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
    client = storage.active_clients[ip_addr]
    client.is_auth
end

function is_connected(storage, ip_addr::String)
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

    for (_, value) in storage.active_clients
        if (value.current_channel_id == channel_id && value.id != client.id)

            user = storage.active_clients[ip_addr]
            channel_name = storage.active_channels[channel_id].name
            PS1 = "[$(date(12:19))][$channel_name][$(user.name)] -> "

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

function fancy_write(storage, conn::IO, msg::String = "")
    ip_addr = string(first(getpeername(conn)))

    if (is_logged(storage, ip_addr) == false)
        return (write(conn, "> "))
    end
    client = storage.active_clients[ip_addr]
    username = client.name
    channel_id = client.current_channel_id
    channel_name = storage.active_channels[channel_id].name
    PS1 = "[$(date(12:19))][$channel_name][$username] "
    write(conn, PS1 * msg)
end

end # Network
