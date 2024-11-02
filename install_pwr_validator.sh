#!/bin/bash

# Update sistem dan instal Java Development Kit (JDK)
echo "Updating system and installing Java..."
sudo apt update && sudo apt install -y openjdk-17-jdk

# Set up environment variables for Java
export JAVA_HOME=/usr/bin/java
export PATH=$PATH:$JAVA_HOME

# Mengatur firewall untuk membuka port yang diperlukan
echo "Configuring firewall rules..."
sudo ufw allow 8231/tcp
sudo ufw allow 8085/tcp
sudo ufw allow 7621/udp
sudo iptables -A INPUT -p tcp --dport 8085 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8231 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 7621 -j ACCEPT
sudo ufw reload

# Ambil versi terbaru dari validator.jar
echo "Fetching the latest version of validator.jar..."
latest_version=$(curl -s https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
sudo wget -O /root/validator.jar "https://github.com/pwrlabs/PWR-Validator/releases/download/$latest_version/validator.jar"

# Unduh config.json ke /root
echo "Creating or downloading config.json..."
sudo wget -O /root/config.json https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json

# Membuat skrip start-up di /usr/local/bin
echo "Creating start-up script..."
sudo tee /usr/local/bin/start-pwr-validator.sh > /dev/null <<EOL
#!/bin/bash

export JAVA_HOME=/usr/bin/java
export PATH=\$PATH:\$JAVA_HOME

# Jalankan validator dengan konfigurasi
exec /usr/bin/java -jar /root/validator.jar password <YOUR_SERVER_IP> --compression-level 3 --config /root/config.json
EOL

# Replace <YOUR_SERVER_IP> dengan alamat IP server yang sebenarnya
sudo sed -i "s|<YOUR_SERVER_IP>|$(curl -s ifconfig.me)|" /usr/local/bin/start-pwr-validator.sh

# Berikan izin eksekusi pada skrip start-up
sudo chmod +x /usr/local/bin/start-pwr-validator.sh

# Buat file layanan systemd untuk PWR Validator
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/pwr.service > /dev/null <<EOL
[Unit]
Description=PWR Validator Service
After=network.target

[Service]
User=root
WorkingDirectory=/root
Environment="JAVA_HOME=/usr/bin/java"
Environment="PATH=/usr/bin:/root"
ExecStart=/usr/local/bin/start-pwr-validator.sh
Restart=on-failure
StandardOutput=journal
StandardError=journal

# Batasan Penggunaan CPU dan RAM
MemoryLimit=2G
CPUQuota=100%

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd dan aktifkan layanan
echo "Enabling and starting PWR Validator service..."
sudo systemctl daemon-reload
sudo systemctl enable pwr.service
sudo systemctl start pwr.service

# Menampilkan status layanan
echo "PWR Validator service status:"
sudo systemctl status pwr.service
sudo journalctl -u pwr.service -f