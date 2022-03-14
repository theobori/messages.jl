module Commands

include("../types.jl")
include("../requests.jl")
include("network.jl")

using .Types, Bcrypt, Sockets

include("../commands/create.jl")
include("../commands/help.jl")
include("../commands/join.jl")
include("../commands/leave.jl")
include("../commands/login.jl")
include("../commands/register.jl")
include("../commands/who.jl")
include("../commands/unknown.jl")

function exec_command(command::Vector{SubString{String}}, storage, conn::IO)
    ip_addr = string(first(getpeername(conn)))
    command_name = String(command[1])
    args = command[2:length(command)]
    commandInfos = getCommandInfos(command_name)

    if (Network.is_logged(storage, ip_addr) == false && commandInfos.auth == true)
        return (write(conn, "You must be logged in to use this command\n"))
    end
    if (size(args)[1] < commandInfos.args_amount)
        return (write(conn, "Invalid number of arguments\n"))
    end

    call(commandInfos, args, storage, conn)
end

end # Commands
