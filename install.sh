#!/bin/bash

# Exit on any error
set -e

echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev

# Create working directory
WORK_DIR=$(mktemp -d)
cd $WORK_DIR

echo "Downloading NGINX and RTMP module..."
# Download and extract NGINX
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar -xf nginx-1.24.0.tar.gz

# Download and extract NGINX-RTMP module
git clone https://github.com/arut/nginx-rtmp-module.git

echo "Building NGINX with RTMP module..."
cd nginx-1.24.0
./configure --with-http_ssl_module --add-module=../nginx-rtmp-module
make
sudo make install

echo "Creating NGINX configuration..."
sudo tee /usr/local/nginx/conf/nginx.conf > /dev/null << 'EOL'
worker_processes auto;
events {
    worker_connections 1024;
}

# RTMP configuration
rtmp {
    server {
        listen 1935; # Standard RTMP port
        chunk_size 4096;

        application live {
            live on;
            record off;
            
            # Enable HLS
            hls on;
            hls_path /tmp/hls;
            hls_fragment 3;
            hls_playlist_length 60;
            
            # Enable DASH
            dash on;
            dash_path /tmp/dash;
            dash_fragment 3;
            dash_playlist_length 60;
        }
    }
}

# HTTP configuration for accessing HLS/DASH streams
http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 8080;
        server_name localhost;

        # HLS stream
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            root /tmp;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }

        # DASH stream
        location /dash {
            root /tmp;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }

        # Status page
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
    }
}
EOL

echo "Creating NGINX systemd service..."
sudo tee /etc/systemd/system/nginx-rtmp.service > /dev/null << 'EOL'
[Unit]
Description=NGINX RTMP Server
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL

echo "Setting up directories and permissions..."
sudo mkdir -p /tmp/hls /tmp/dash
sudo chmod 777 /tmp/hls /tmp/dash

echo "Enabling and starting NGINX RTMP service..."
sudo systemctl daemon-reload
sudo systemctl enable nginx-rtmp
sudo systemctl start nginx-rtmp

echo "NGINX RTMP server installation complete!"
echo "Stream URL: rtmp://your-server-ip/live/stream-key"
echo "HLS URL: http://your-server-ip:8080/hls/stream-key.m3u8"
echo "DASH URL: http://your-server-ip:8080/dash/stream-key.mpd"
echo "Status Page: http://your-server-ip:8080/stat"

# Cleanup
cd
rm -rf $WORK_DIR
