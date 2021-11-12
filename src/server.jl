module Server

include("data.jl")
include("commands.jl")

using .Data, Sockets

function error_command(command::String)::Bool
    return any([startswith(command, "/$key") for (key, _) in Commands.commands_ref])
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

    if (size(parsed_line)[1] > 0)
        Commands.exec_command(parsed_line, s, conn)
    end
end

function serve(port::Int)
	storage = Storage(listen(IPv4(0), port), Dict())

    print("Server listening on port $port")
  	while true
		conn = accept(storage.listener)
		write(conn, Data.welcome_msg)
		print(getpeername(conn))
		@async begin
			try
				while isopen(conn)
					wait_client(conn, storage)
				end
			catch err
				print("connection ended with error $err")
			end
		end
	end
end
	
export serve, Storage

end # Server

using .Server

serve(6666)