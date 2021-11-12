module Commands

include("data.jl")

using .Data, MySQL, DotEnv, Bcrypt

DotEnv.config()

# SQL connection
const mysql_conn = DBInterface.connect(
    MySQL.Connection,
    ENV["MYSQL_HOST"], 
    ENV["MYSQL_USER"], 
    ENV["MYSQL_ROOT_PASSWORD"], 
    db = ENV["MYSQL_DATABASE"]
)

function register(command::Vector{SubString{String}}, s::Any, conn::IO)
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
        return (write(conn, "An account with the username \"$name\" already exists\n"))
    end
    write(conn, "Account successfully created\n")
end

function login(command::Vector{SubString{String}}, s::Any, conn::IO)
    name = command[2]
    try
        DBInterface.execute(mysql_conn, """SELECT id FROM user WHERE name='$name'""")
    catch err
        return (write(conn, "T\n"))
    end
end

function who(command::Vector{SubString{String}}, s::Any, conn::IO)

end

function create_channel(command::Vector{SubString{String}}, s::Any, conn::IO)

end

function join_channel(command::Vector{SubString{String}}, s::Any, conn::IO)

end

function leave_channel(command::Vector{SubString{String}}, s::Any, conn::IO)

end

function exit(command::Vector{SubString{String}}, s::Any, conn::IO)
    
end

function help(command::Vector{SubString{String}}, s::Any, conn::IO)
    write(conn, Data.help_msg)
end

const commands_ref = Dict{String, Vector}(
    "register" => [register, 3],
    "login" => [login, 2],
    "who" => [who, 0],
    "create" => [create_channel, 1],
    "join" => [join_channel, 1],
    "leave" => [leave_channel, 0],
    "exit" => [exit, 0],
    "help" => [help, 0]
)
    
function is_command_error(command::Vector{SubString{String}})
    return (size(command)[1] - 1 < commands_ref[command[1]][2])
end

function exec_command(command::Vector{SubString{String}}, s::Any, conn::IO)
    if (is_command_error(command))
        return write(conn, "You should use /help\n")
    end
    commands_ref[command[1]][1](command, s, conn)
end

end # Commands