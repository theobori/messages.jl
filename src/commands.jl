module Commands

include("data.jl")

using .Data, MySQL, DotEnv, Bcrypt, Sockets

DotEnv.config()

# SQL connection
const mysql_conn = DBInterface.connect(
    MySQL.Connection,
    ENV["MYSQL_HOST"],
    ENV["MYSQL_USER"],
    ENV["MYSQL_ROOT_PASSWORD"],
    db = ENV["MYSQL_DATABASE"]
)

function init_lobby(storage)
    response = DBInterface.execute(mysql_conn, """SELECT id, name, description,
    protected, password, owner FROM channel WHERE id=1""")

    if (length(response) == 0)
        return
    end

    arr = map(x -> string(x), first(response))
    storage.active_channels[arr[1]] = Data.Channel(arr[1], arr[2], arr[3], 
    parse(Int64, arr[4]), arr[5], arr[6])
end

function is_logged(storage, ip_addr::String)
    ip_addr in [key for (key, _) in storage.active_clients]
end

function disconnect(storage, conn::IO)
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
                write(value.conn, PS1 * msg * "\n")
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

function register(command::Vector{SubString{String}}, storage, conn::IO)
    if (command[3] != command[4])
        return (write(conn, "The passwords do not match\n"))
    end
    if (length(command[3]) < 6)
        return (write(conn, "The passwords must have more than 6 characters\n"))
    end
    
    name = command[2]
    password = String(Bcrypt.GenerateFromPassword(Array{UInt8,1}(command[3]), 0))
    try
        DBInterface.execute(mysql_conn, """INSERT INTO user (name, password)
        VALUES ('$name', '$password')""")
    catch err
        return (write(conn, "An account with the username $name already exists\n"))
    end
    write(conn, "Account successfully created ! Now you can use /login\n")
end

function login(command::Vector{SubString{String}}, storage, conn::IO)
    name = command[2]
    ip_addr = string(first(getpeername(conn)))

    if (is_logged(storage, ip_addr))
        return (write(conn, "There already is a connection with this IP address\n"))
    end
    if (name in [value.name for (_, value) in storage.active_clients])
        return (write(conn, "This account is already used\n"))
    end

    response = DBInterface.execute(mysql_conn, """SELECT id, password, name
    FROM user WHERE name='$name'""")

    if (length(response) == 0)
        return (write(conn, "Invalid username or password\n"))
    end
    password = String(command[3])
    arr = map(x -> string(x), first(response))
    if (Bcrypt.CompareHashAndPassword(arr[2], password) == false)
        return (write(conn, "Invalid username or password\n"))
    end
    write(conn, "Successfully logged in\n")

    storage.active_clients[ip_addr] = Client(arr[1], arr[3], ip_addr, "1", conn)
end

function who(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))

    user = storage.active_clients[ip_addr]
    fancy_write(storage, conn, "$(user.name) $(user.ip_addr)\n")
end

function create_channel(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    name = command[2]
    password = length(command) - 1 != 2 ? "no password" : 
    String(Bcrypt.GenerateFromPassword(Array{UInt8,1}(command[3]), 0))
    protected = password == "no password" ? 0 : 1
    user_id = storage.active_clients[ip_addr].id

    try
        DBInterface.execute(mysql_conn, """INSERT INTO channel (name,
        description, protected, password, owner) VALUES ('$name', 
        'tmp', $protected, '$password', $user_id)""")
        write(conn, "Successfully created the channel $name\n")
    catch err
        return (write(conn, "A channel with the name $name already exists\n"))
    end
end

function join_channel(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    name = command[2]

    response = DBInterface.execute(mysql_conn, """SELECT id, description, 
    name, protected, password, owner FROM channel WHERE name='$name'""")

    if (length(response) == 0)
        return (write(conn, "This channel doesnt exist\n"))
    end

    arr = first(response)
    if (arr.protected == 1)
        if (length(command) - 1 != 2)
            return (write(conn, "This channel required a password\n"))
        end
        if (Bcrypt.CompareHashAndPassword(arr.password, String(command[3])) == false)
            return (write(conn, "Invalid password\n"))
        end
    end

    storage.active_clients[ip_addr].current_channel_id = string(arr.id)
    if (channel_exist(storage, string(arr.id)) == false)
        storage.active_channels[string(arr.id)] = Data.Channel(string(arr.id), 
        arr.name, arr.description, arr.protected, arr.password, string(arr.owner))
    end
    write(conn, "Successfully joined\n")
end

function leave_channel(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))

    client = storage.active_clients[ip_addr]
    channel = storage.active_channels[client.current_channel_id]

    if (client.current_channel_id == "1")
        return (write(conn, "You can't leave the lobby\n"))
    end
    client.current_channel_id = "1"
    write(conn, "You left the channel $(channel.name)\n")
end

function help(command::Vector{SubString{String}}, storage, conn::IO)
    write(conn, Data.help_msg)
end

const commands_ref = Dict{String, Vector}(
    # Function reference , args needed, auth required
    "register" => [register, 3, false],
    "login" => [login, 2, false],
    "who" => [who, 0, true],
    "create" => [create_channel, 1, true],
    "join" => [join_channel, 1, true],
    "leave" => [leave_channel, 0, true],
    "help" => [help, 0, false]
)
    
function is_command_error(command::Vector{SubString{String}})
    return (size(command)[1] - 1 < commands_ref[command[1]][2])
end

function exec_command(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))

    if (is_command_error(command))
        return write(conn, "You should use /help\n")
    end

    command_ref = commands_ref[command[1]]
    if (is_logged(storage, ip_addr) == false && command_ref[3] == true)
        return (write(conn, "You must be logged in to use this command\n"))
    end
    command_ref[1](command, storage, conn)
end

end # Commands