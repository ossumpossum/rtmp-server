# RTMP Server

This project provides a configuration and setup for running an NGINX-based RTMP (Real-Time Messaging Protocol) server for personal use. 

## Overview

This RTMP server implementation uses NGINX with the RTMP module to enable video streaming capabilities. It can be used for:
- Personal streaming setups
- Local video streaming
- Testing streaming configurations
- Learning about RTMP streaming infrastructure

## Features
- NGINX-based RTMP server with RTMP module
- Support for HLS and DASH streaming
- Basic streaming configuration
- Easy to set up and customize
- Suitable for personal streaming needs
- Real-time streaming statistics

## Installation

1. Clone this repository:
```bash
git clone https://github.com/ossumpossum/rtmp-server.git
cd rtmp-server
```

2. Make the installation script executable (if not already):
```bash
chmod +x install.sh
```

3. Run the installation script:
```bash
sudo ./install.sh
```

The script will:
- Install required dependencies
- Download and compile NGINX with RTMP module
- Configure NGINX for RTMP streaming
- Set up HLS and DASH streaming support
- Create and start the NGINX service

## Usage

After installation, the server will be running and configured with the following endpoints:

### Streaming to the Server
- RTMP Streaming URL: `rtmp://your-server-ip/live/stream-key`
  - Replace `your-server-ip` with your server's IP address
  - Replace `stream-key` with your chosen stream key

### Watching Streams
- HLS Stream: `http://your-server-ip:8080/hls/stream-key.m3u8`
- DASH Stream: `http://your-server-ip:8080/dash/stream-key.mpd`
- Statistics Page: `http://your-server-ip:8080/stat`

### Streaming Software Configuration
1. In your streaming software (OBS, FFmpeg, etc.), set:
   - URL: `rtmp://your-server-ip/live`
   - Stream Key: Your chosen stream key

### Service Management
```bash
# Start the server
sudo systemctl start nginx-rtmp

# Stop the server
sudo systemctl stop nginx-rtmp

# Restart the server
sudo systemctl restart nginx-rtmp

# Check server status
sudo systemctl status nginx-rtmp
```

## Ports Used
- 1935: RTMP streaming
- 8080: HTTP (HLS/DASH streaming and statistics)

Make sure these ports are open in your firewall if you want to allow external access.
