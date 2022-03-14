module Utils

using Dates, Sockets

date(slicer) = string(now())[slicer]

function log(conn::IO, line::String, file::String)
    ip_addr = string(first(getpeername(conn)))

    open(file, "a+") do f
        write(f, "$ip_addr -> $(date(12:19)) -> $line\n")
    end
end

log(conn::IO, line::String) = log(conn, line, "./logs/$(date(1:10)).log")

export date

end # Utils