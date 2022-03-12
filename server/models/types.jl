module Data

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
    # ip => Client
    active_clients::Dict{String,Any}
    # id => Channel
    active_channels::Dict{String,Any}
end

export Client, Channel, Storage

end # Data