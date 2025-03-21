FROM golang:1.20-alpine AS builder

WORKDIR /app

# Copy the Go module files
COPY main.go .

# Build the application with static linking
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o echo-server .

# Use a minimal alpine image for the final container
FROM alpine:3.17

WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/echo-server .

# Expose the default port
EXPOSE 80/tcp
EXPOSE 80/udp

# Run the server
ENTRYPOINT ["/app/echo-server"]
