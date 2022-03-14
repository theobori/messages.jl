module Requests

using MySQL

SQL() = DBInterface.connect(
        MySQL.Connection,
        ENV["MYSQL_HOST"],
        ENV["MYSQL_USER"],
        ENV["MYSQL_ROOT_PASSWORD"],
        db = ENV["MYSQL_DATABASE"]
    )

function insert_channel(conn::MySQL.Connection, values...)
    ret = true
    try
        DBInterface.execute(conn, """INSERT INTO channel (name,
        description, protected, password, owner) VALUES ('$(values[1])', 
        'tmp', $(values[2]), '$(values[3])', $(values[4]))""")
    catch err
        ret = false
    end
    ret
end

function insert_account(conn::MySQL.Connection, name, password)
    ret = true
    try
        DBInterface.execute(conn, """INSERT INTO user (name, password)
        VALUES ('$name', '$password')""")
    catch err
        ret = false
    end
    ret
end

function get_channel(conn::MySQL.Connection, name)
    r = DBInterface.execute(conn, """SELECT id, description, 
    name, protected, password, owner FROM channel WHERE name='$name'""")
    if (length(r) == 0)
        return ([])
    end
    first(r)
end

function get_account(conn::MySQL.Connection, name)
    r = DBInterface.execute(conn, """SELECT id, password, name
    FROM user WHERE name='$name'""")
    if (length(r) == 0)
        return ([])
    end
    first(r)
end

function get_lobby(conn::MySQL.Connection)
    r = DBInterface.execute(conn, """SELECT id, name, description,
    protected, password, owner FROM channel WHERE id=1""")
    if (length(r) == 0)
        return ([])
    end
    first(r)
end

export SQL

end # Requests
