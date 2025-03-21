#!/bin/bash

# Build the echo server
echo "Building echo server..."
go build -o echo-server main.go

if [ $? -eq 0 ]; then
    echo "Build successful! The binary is available as './echo-server'"
    echo "Usage examples:"
    echo "  ./echo-server                          # Run with default ports (HTTP and UDP on port 80)"
    echo "  ./echo-server -port 8080               # Run both servers on port 8080"
    echo "  ./echo-server -http-port 8080 -udp-port 9090  # Run HTTP on 8080 and UDP on 9090"
else
    echo "Build failed!"
fi
