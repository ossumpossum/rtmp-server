#!/bin/bash

# Exit on any error
set -e

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "FFmpeg is required but not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y ffmpeg
fi

# Get server IP (same method as install script)
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -n 1)

echo "Testing RTMP Server at $SERVER_IP"
echo "================================"

# Create a test video pattern
echo "1. Generating a test stream (10 second video pattern)..."
echo "   This will stream a test pattern to: rtmp://$SERVER_IP/stream"
ffmpeg -re -f lavfi -i testsrc=duration=10:size=1280x720:rate=30 \
       -f lavfi -i sine=frequency=1000:duration=10 \
       -c:v libx264 -b:v 1M -c:a aac -b:a 128k \
       -f flv rtmp://$SERVER_IP/stream &

# Store the FFmpeg process ID
FFMPEG_PID=$!

echo "2. Waiting for stream to start..."
sleep 2

echo "3. Testing stream access points..."
echo "   - RTMP: rtmp://$SERVER_IP/stream"
echo "   - HLS:  http://$SERVER_IP:8080/hls/stream.m3u8"
echo "   - DASH: http://$SERVER_IP:8080/dash/stream.mpd"

# Test RTMP endpoint
echo -n "   Checking RTMP endpoint: "
if nc -z $SERVER_IP 1935; then
    echo "OK (Port 1935 is open)"
else
    echo "Failed (Port 1935 is not accessible)"
fi

# Test HTTP endpoint
echo -n "   Checking HTTP endpoint: "
if nc -z $SERVER_IP 8080; then
    echo "OK (Port 8080 is open)"
else
    echo "Failed (Port 8080 is not accessible)"
fi

# Test HLS stream
echo -n "   Checking HLS stream: "
if curl -s "http://$SERVER_IP:8080/hls/stream.m3u8" | grep -q "#EXTM3U"; then
    echo "OK (HLS playlist is available)"
else
    echo "Failed (HLS playlist not found)"
fi

echo "4. Checking NGINX RTMP status..."
if curl -s "http://$SERVER_IP:8080/stat" | grep -q "nginx"; then
    echo "   Status page is accessible"
else
    echo "   Status page is not accessible"
fi

echo "5. Stream will continue for a few more seconds..."
sleep 5

# Clean up
echo "6. Cleaning up..."
kill $FFMPEG_PID
wait $FFMPEG_PID 2>/dev/null || true

echo "Test complete!"
echo "To view the stream while it's running, you can:"
echo "1. Open VLC and go to Media -> Open Network Stream"
echo "2. Enter one of these URLs:"
echo "   - rtmp://$SERVER_IP/stream"
echo "   - http://$SERVER_IP:8080/hls/stream.m3u8"
echo "Or visit http://$SERVER_IP:8080/stat to see the server statistics"
