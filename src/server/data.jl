module Data

const help_msg = """
+-------------------------------------------------------------+
| /register <name> <password> <password> - Create an account  |
| /login <name> <password> - Connect with an existing account |
| /who - Show your name, id                                   |
| /create <channel_name> - Create a channel                   |
| /join <channel_name> - Join a channel                       |
| /leave - Leave a channel                                    |
| /exit - Disconnect                                          |
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
	channel_id::Int
end

mutable struct Channel
	id::String
	clients::Vector{String} # Clients id
end

mutable struct Storage
	listener::Any
	active_channels::Dict{String, Channel}
end

export Client, Channel, Storage

end # Data