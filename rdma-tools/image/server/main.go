package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

// Environment variable constants
const (
	ENV_LOCAL_NODE_NAME = "ENV_LOCAL_NODE_NAME"
	ENV_LOCAL_NODE_IP   = "ENV_LOCAL_NODE_IP"
)

// Global counter for tracking requests
var (
	httpCounter uint64
	udpCounter  uint64
	localNodeName string
	localNodeIP   string
)

// Response represents the structure of the response
type Response struct {
	SourceIP        string            `json:"source_ip"`
	DestinationIP   string            `json:"destination_ip"`
	SourcePort      string            `json:"source_port"`
	DestinationPort string            `json:"destination_port"`
	Counter         uint64            `json:"counter"`
	Message         string            `json:"message,omitempty"`
	Headers         map[string]string `json:"headers,omitempty"`
	Protocol        string            `json:"protocol,omitempty"` // IPv4 or IPv6
	ServerTime      string            `json:"server_time"`        // Server timestamp
	ServerHostname  string            `json:"server_hostname"`    // Server hostname
	LocalNodeName   string            `json:"server_node_name"`    // Kubernetes node name
	LocalNodeIP     string            `json:"server_node_ip"`      // Kubernetes node IP
}

func main() {
	// Configure logging
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)
	log.SetOutput(os.Stdout)

	// Read environment variables
	localNodeName = os.Getenv(ENV_LOCAL_NODE_NAME)
	localNodeIP = os.Getenv(ENV_LOCAL_NODE_IP)
	
	log.Printf("[MAIN] Local node name: %s, Local node IP: %s", localNodeName, localNodeIP)

	// Parse command line flags
	httpPort := flag.Int("http-port", 80, "HTTP server port")
	udpPort := flag.Int("udp-port", 80, "UDP server port")
	flag.Parse()

	log.Printf("[MAIN] Starting echo servers - HTTP on port %d, UDP on port %d", *httpPort, *udpPort)

	// Print network interfaces for debugging
	printNetworkInterfaces()

	// Start servers in separate goroutines
	var wg sync.WaitGroup
	wg.Add(2)

	// Start HTTP server
	go func() {
		defer wg.Done()
		if err := startHTTPServer(*httpPort); err != nil {
			log.Fatalf("[MAIN] HTTP server error: %v", err)
		}
	}()

	// Start UDP server
	go func() {
		defer wg.Done()
		if err := startUDPServer(*udpPort); err != nil {
			log.Fatalf("[MAIN] UDP server error: %v", err)
		}
	}()

	wg.Wait()
}

// printNetworkInterfaces logs all available network interfaces and their addresses
func printNetworkInterfaces() {
	interfaces, err := net.Interfaces()
	if err != nil {
		log.Printf("[DEBUG] Error getting network interfaces: %v", err)
		return
	}

	log.Printf("[DEBUG] Available network interfaces:")
	for _, iface := range interfaces {
		addrs, err := iface.Addrs()
		if err != nil {
			log.Printf("[DEBUG]   Error getting addresses for interface %s: %v", iface.Name, err)
			continue
		}

		addrStrings := make([]string, 0, len(addrs))
		for _, addr := range addrs {
			addrStrings = append(addrStrings, addr.String())
		}
		log.Printf("[DEBUG]   %s (index: %d, flags: %v): %v", 
			iface.Name, iface.Index, iface.Flags, strings.Join(addrStrings, ", "))
	}
}

// startHTTPServer initializes and starts the HTTP server
func startHTTPServer(port int) error {
	// Define the handler for all incoming requests
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Get hostname
		hostname, err := os.Hostname()
		if err != nil {
			hostname = "unknown"
		}

		// Increment counter
		counter := atomic.AddUint64(&httpCounter, 1)
		log.Printf("[HTTP] Received request #%d from %s to %s %s", counter, r.RemoteAddr, r.Host, r.URL.Path)

		// Log request details for debugging
		log.Printf("[HTTP] Request details: Method=%s, Proto=%s, ContentLength=%d", 
			r.Method, r.Proto, r.ContentLength)
		
		// Log all headers for debugging
		log.Printf("[HTTP] Request headers:")
		for name, values := range r.Header {
			log.Printf("[HTTP]   %s: %s", name, strings.Join(values, ", "))
		}

		// Extract IP and port information
		sourceIP, sourcePort := extractIPAndPort(r.RemoteAddr)
		destIP, destPort := extractIPAndPort(r.Host)

		// Determine protocol (IPv4 or IPv6)
		protocol := "IPv4"
		if strings.Contains(sourceIP, ":") {
			protocol = "IPv6"
		}

		log.Printf("[HTTP] Connection details: Source=%s:%s (%s), Destination=%s:%s", 
			sourceIP, sourcePort, protocol, destIP, destPort)

		// Create a map for headers
		headers := make(map[string]string)
		for name, values := range r.Header {
			headers[name] = strings.Join(values, ", ")
		}

		// Create response object
		response := Response{
			SourceIP:        sourceIP,
			DestinationIP:   destIP,
			SourcePort:      sourcePort,
			DestinationPort: destPort,
			Counter:         counter,
			Headers:         headers,
			Protocol:        protocol,
			ServerTime:      time.Now().Format(time.RFC3339),
			ServerHostname:  hostname,
			LocalNodeName:   localNodeName,
			LocalNodeIP:     localNodeIP,
		}

		// Marshal to JSON
		jsonResponse, err := json.MarshalIndent(response, "", "  ")
		if err != nil {
			log.Printf("[HTTP] Error marshaling response: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		// Send response
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Connection", "close") // Ensure connection is closed after response
		w.WriteHeader(http.StatusOK)
		_, err = w.Write(jsonResponse)
		if err != nil {
			log.Printf("[HTTP] Error writing response: %v", err)
		}

		log.Printf("[HTTP] Sent response #%d to %s", counter, r.RemoteAddr)
	})

	// Start the server on all interfaces for both IPv4 and IPv6
	addr := fmt.Sprintf(":%d", port)
	
	// Create custom server with timeouts
	server := &http.Server{
		Addr:              addr,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
	
	log.Printf("[HTTP] Server listening on %s (IPv4 and IPv6)", addr)
	return server.ListenAndServe()
}

// startUDPServer initializes and starts the UDP server
func startUDPServer(port int) error {
	// Start IPv4 and IPv6 UDP servers
	var wg sync.WaitGroup
	wg.Add(2)
	
	errChan := make(chan error, 2)
	
	// Start IPv4 UDP server
	go func() {
		defer wg.Done()
		if err := startUDPServerForProtocol(port, "udp4"); err != nil {
			errChan <- fmt.Errorf("IPv4 UDP server error: %w", err)
		}
	}()
	
	// Start IPv6 UDP server
	go func() {
		defer wg.Done()
		if err := startUDPServerForProtocol(port, "udp6"); err != nil {
			// Don't fail if IPv6 is not supported, just log it
			if strings.Contains(err.Error(), "address family not supported") {
				log.Printf("[UDP] IPv6 not supported on this system")
			} else {
				errChan <- fmt.Errorf("IPv6 UDP server error: %w", err)
			}
		}
	}()
	
	// Wait for errors or completion
	go func() {
		wg.Wait()
		close(errChan)
	}()
	
	// Return first error if any
	for err := range errChan {
		return err
	}
	
	return nil
}

// startUDPServerForProtocol starts a UDP server for a specific protocol (udp4 or udp6)
func startUDPServerForProtocol(port int, network string) error {
	addr := fmt.Sprintf(":%d", port)
	udpAddr, err := net.ResolveUDPAddr(network, addr)
	if err != nil {
		return fmt.Errorf("failed to resolve %s address: %w", network, err)
	}

	conn, err := net.ListenUDP(network, udpAddr)
	if err != nil {
		return fmt.Errorf("failed to start %s server: %w", network, err)
	}
	defer conn.Close()

	protocolName := "IPv4"
	if network == "udp6" {
		protocolName = "IPv6"
	}
	
	log.Printf("[UDP] %s server listening on %s", protocolName, addr)

	buffer := make([]byte, 1024)
	for {
		n, addr, err := conn.ReadFromUDP(buffer)
		if err != nil {
			log.Printf("[UDP] Error reading from %s: %v", network, err)
			continue
		}

		// Increment counter
		counter := atomic.AddUint64(&udpCounter, 1)
		log.Printf("[UDP] Received %s request #%d from %s", protocolName, counter, addr.String())

		// Extract IP and port information
		sourceIP, sourcePortStr := extractIPAndPort(addr.String())
		
		// Get local address information
		localAddr := conn.LocalAddr().(*net.UDPAddr)
		destIP := localAddr.IP.String()
		destPort := localAddr.Port

		// Get hostname
		hostname, err := os.Hostname()
		if err != nil {
			hostname = "unknown"
		}

		// Create response
		response := Response{
			SourceIP:        sourceIP,
			DestinationIP:   destIP,
			SourcePort:      sourcePortStr,
			DestinationPort: fmt.Sprintf("%d", destPort),
			Counter:         counter,
			Message:         string(buffer[:n]),
			Protocol:        protocolName,
			ServerTime:      time.Now().Format(time.RFC3339),
			ServerHostname:  hostname,
			LocalNodeName:   localNodeName,
			LocalNodeIP:     localNodeIP,
		}

		// Marshal to JSON
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			log.Printf("[UDP] Error marshaling response: %v", err)
			continue
		}

		// Send response
		_, err = conn.WriteToUDP(jsonResponse, addr)
		if err != nil {
			log.Printf("[UDP] Error sending response: %v", err)
			continue
		}

		log.Printf("[UDP] Sent %s response #%d to %s", protocolName, counter, addr.String())
	}
}

// extractIPAndPort splits an address string into IP and port components
func extractIPAndPort(addr string) (string, string) {
	// Handle IPv6 addresses which are enclosed in square brackets
	if strings.HasPrefix(addr, "[") {
		// Format: [IPv6]:port
		parts := strings.Split(addr, "]:")
		if len(parts) == 2 {
			return strings.TrimPrefix(parts[0], "["), parts[1]
		}
		return strings.TrimPrefix(strings.TrimSuffix(addr, "]"), "["), ""
	}

	// Handle IPv4 addresses
	parts := strings.Split(addr, ":")
	if len(parts) == 2 {
		return parts[0], parts[1]
	}
	return addr, ""
}
