# Echo Server

A simple Go-based echo server that provides both HTTP and UDP services. This server responds to any request with information about the client connection and maintains a counter for each protocol.

## Features

- HTTP server that responds with:
  - All client request headers
  - Source and destination IP addresses and ports
  - Request counter value
- UDP server that responds with JSON containing:
  - Source and destination IP addresses and ports
  - Request counter value
  - Original message received
- Dual-stack support for both IPv4 and IPv6 protocols
- Protocol information included in the response

## Usage

### Command Line Options

```bash
-http-port int
    HTTP server port (default 80)
-udp-port int
    UDP server port (default 80)
```

### Examples

Run with default settings (both servers on port 80):

```bash
./echo-server
```

Run with custom ports for each server:

```bash
./echo-server -http-port 8080 -udp-port 9090
```

## Docker Usage

Build the Docker image:

```bash
docker build -t echo-server .
```

Run the container:

```bash
docker run -p 80:80/tcp -p 80:80/udp echo-server
```

With custom ports:

```bash
docker run -p 8080:8080/tcp -p 9090:9090/udp echo-server -http-port 8080 -udp-port 9090
```

## Testing

### Mac OS X

#### HTTP Testing on Mac

```bash
# Using curl with IPv4
curl -4 http://localhost:80/

# Using curl with IPv6
curl -6 http://localhost:80/

# Using wget
wget -O- http://localhost:80/

# Using httpie (if installed)
http GET http://localhost:80/
```

#### UDP Testing on Mac

```bash
# Using netcat
echo "Hello" | nc -u localhost 80

# Using socat with IPv4
echo "Hello" | socat - UDP4:localhost:80

# Using socat with IPv6
echo "Hello" | socat - UDP6:[::1]:80
```

### Linux

#### HTTP Testing on Linux

```bash
# Using curl with IPv4
curl -4 http://localhost:80/

# Using curl with IPv6
curl -6 http://localhost:80/

# Using wget
wget -O- http://localhost:80/

# Using httpie (if installed)
http GET http://localhost:80/
```

#### UDP Testing on Linux

```bash
# Using netcat
echo "Hello" | nc -u localhost 80

# Using socat with IPv4
echo "Hello" | socat - UDP4:localhost:80

# Using socat with IPv6
echo "Hello" | socat - UDP6:[::1]:80

# Using ncat (part of nmap)
echo "Hello" | ncat -u localhost 80
