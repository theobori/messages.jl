# `💬 IRC implementation`

## Setup

### `Server`

1. Install the dependencies
    - Run the bash script `install.sh` (Can request sudo)
  
2. Create the file `.env` in the repository source using the `.env_example`
    - Complete the database fields

3. Import the SQL schema into a db engine, for MySQL:
   - `mysql -u username -p database < data/schema.sql`

4. Create a julia file and import `server.jl`

5. You have to use the module named `server` in `src/server.jl`
```julia
include("src/server.jl").serve(6666)
```

### `Client`

1. Install the dependencies
    - Run the bash script `install.sh` (Can request sudo)
2. Run `python3 client/client.py`

## Features / TODO

Name           | Status
-------------  |:-------------:
netcat working as a client | ✔️
Basic command system | ✔️
Account system | ✔️
SQL model      | ✔️
Disallow multiple connections with same IP | ✔️
Meta parsing to create command types  | ✔️
Multiple dispatch with command functions | ✔️
Anti DOS       | ⌛
Client         | ✔️
Private messages | ⌛
Encrypted communication (probably diff port) | ⌛
