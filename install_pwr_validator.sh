#!/bin/bash

# Update dan gunakan JDK 22 saja
echo "Checking and setting up JDK 22..."
if [ ! -d "/usr/lib/jvm/jdk-22.0.1+8" ]; then
    echo "JDK 22 not found, installing..."
    sudo apt update
    sudo apt install -y wget
    sudo mkdir -p /usr/lib/jvm
    sudo wget -O /tmp/jdk-22.tar.gz "https://github.com/adoptium/temurin22-binaries/releases/download/jdk-22.0.1%2B8/OpenJDK22U-jdk_x64_linux_hotspot_22.0.1_8.tar.gz"
    sudo tar -xzf /tmp/jdk-22.tar.gz -C /usr/lib/jvm
    sudo rm /tmp/jdk-22.tar.gz
    sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-22.0.1+8/bin/java 2000
    sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-22.0.1+8/bin/javac 2000
    sudo update-alternatives --set java /usr/lib/jvm/jdk-22.0.1+8/bin/java
    sudo update-alternatives --set javac /usr/lib/jvm/jdk-22.0.1+8/bin/javac
else
    echo "JDK 22 already installed."
fi

# Set up env Java
export JAVA_HOME=/usr/lib/jvm/jdk-22.0.1+8
export PATH=$JAVA_HOME/bin:$PATH

# Konfigurasi firewall
echo "Configuring firewall rules..."
sudo ufw allow 8231/tcp
sudo ufw allow 8085/tcp
sudo ufw allow 7621/udp
sudo iptables -A INPUT -p tcp --dport 8085 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8231 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 7621 -j ACCEPT
sudo ufw reload

# Auto unduh versi terbaru validator.jar
echo "Fetching the latest version of validator.jar..."
latest_version=$(curl -s https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
sudo wget -O /root/validator.jar "https://github.com/pwrlabs/PWR-Validator/releases/download/$latest_version/validator.jar"

# Unduh atau buat config.json
echo "Creating or downloading config.json..."
sudo wget -O /root/config.json https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json

# Buat skrip startup di /usr/local/bin
echo "Creating start-up script..."
sudo tee /usr/local/bin/start-pwr-validator.sh > /dev/null <<EOL
#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/jdk-22.0.1+8
export PATH=\$JAVA_HOME/bin:\$PATH

# Jalankan validator dengan konfigurasi
exec /usr/bin/java -jar /root/validator.jar password <YOUR_SERVER_IP> --compression-level 3 --config /root/config.json
EOL

# Ganti <YOUR_SERVER_IP> dengan alamat IP server VPS
sudo sed -i "s|<YOUR_SERVER_IP>|$(curl -s ifconfig.me)|" /usr/local/bin/start-pwr-validator.sh

# Berikan izin eksekusi untuk skrip startup
sudo chmod +x /usr/local/bin/start-pwr-validator.sh

# Membuat file layanan systemd untuk PWR Validator
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/pwr.service > /dev/null <<EOL
[Unit]
Description=PWR Validator Service
After=network.target

[Service]
User=root
WorkingDirectory=/root
Environment="JAVA_HOME=/usr/lib/jvm/jdk-22.0.1+8"
Environment="PATH=/usr/lib/jvm/jdk-22.0.1+8/bin:/usr/bin"
ExecStart=/usr/local/bin/start-pwr-validator.sh
Restart=on-failure
StandardOutput=journal
StandardError=journal

MemoryLimit=2G
CPUQuota=100%
TasksMax=10000

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
