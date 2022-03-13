module Types

using MySQL

const help_msg = """
+-------------------------------------------------------------+
| /register <name> <password> <password> - Create an account  |
| /login <name> <password> - Connect with an existing account |
| /who - Show your name, id                                   |
| /create <channel_name> [password]- Create a channel         |
| /join <channel_name> [password]- Join a channel             |
| /leave - Leave a channel                                    |
| /help - Display this message                                |
+-------------------------------------------------------------+

"""

const welcome_msg = """
Use /help if you need more informations

"""

mutable struct Client
    id::String
    name::String
    ip_addr::String
    current_channel_id::String
    conn::IO
end

mutable struct Channel
    id::String
    name::String
    description::String
    is_protected::Int
    password::String
    owner_id::String
end

mutable struct Storage
    listener::Any
    sql_conn::MySQL.Connection
    # ip => Client
    active_clients::Dict{String,Any}
    # id => Channel
    active_channels::Dict{String,Any}
end

function Storage(listener::Any, sql_conn::MySQL.Connection)
    Storage(listener, sql_conn, Dict(), Dict())
end

abstract type AbstractCommand{A <: Number, B <: Bool} end

function addCommandType(name::String, args_amount::String, auth::String)
    expr = """
    struct $name{A, B} <: AbstractCommand{A, B}
        args_amount::A
        auth::B
        function $name()
            if ($args_amount < 0)
                error(\"The arguments amount must be >= 0\")
            end
            new{Int, Bool}($args_amount, $auth)
        end
    end"""
    expr = Meta.parse(expr)
    eval(expr)
end

addCommandType("Register", "0", "false")
addCommandType("Login", "2", "false")
addCommandType("Help", "0", "false")
addCommandType("Who", "0", "true")
addCommandType("Create", "1", "true")
addCommandType("Join", "1", "true")
addCommandType("Leave", "0", "true")
addCommandType("Unknown", "0", "false")

const table = Dict(
    "register" => Register,
    "login" => Login,
    "help" => Help,
    "who" => Who,
    "create" => Create,
    "join" => Join,
    "leave" => Leave
)

function getCommandInfos(name::String)
    if (any([name == key for (key, _) in table]) == false)
        return (Unknown())
    end
    table[name]()
end

export Client, Channel, Storage, getCommandInfos

end # Data
