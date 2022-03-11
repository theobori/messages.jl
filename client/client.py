#!/usr/bin/env python3

import socket, select, sys
from typing import *

def error():
    if (len(sys.argv) < 3):
        print("Usage: ./client.py <ip_addr> <port>")
        exit(84)
    if (not sys.argv[2].isdigit()):
        exit(84)

class Client:

    def __init__(self):
        error() 
        # Server to connect
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.connect((sys.argv[1], int(sys.argv[2])))

        # Possible streams
        self.sockets_list = [sys.stdin, self.server]

    def _listen(self, read_sockets: Any):
        for sock in read_sockets:
            if sock == self.server:
                message = sock.recv(2048)
                print(message.decode("utf-8"), end = "")
            else:
                message = sys.stdin.readline()
                self.server.send(message.encode())
                sys.stdout.flush()

    def run(self):
        while (42):
            read_sockets, write_socket, error_socket = select.select(
                self.sockets_list, [], [])

            self._listen(read_sockets)

def main():
    client = Client()
    client.run()

if __name__ == "__main__":
    main()