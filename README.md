```
curl -o install_pwr_validator.sh -L "https://raw.githubusercontent.com/arcxteam/pwrlabs-node/main/install_pwr_validator.sh" && chmod +x install_pwr_validator.sh
```

run node validator

```
sudo ./install_pwr_validator.sh
```

Update version

```
sudo systemctl stop pwr.service && \
sudo rm -rf /root/validator.jar /root/config.json /root/blocks /root/rocksdb && \
latest_version=$(curl -s https://api.github.com/repos/pwrlabs/PWR-Validator/releases/latest | grep -Po '"tag_name": "\K.*?(?=")') && \
wget -O /root/validator.jar "https://github.com/pwrlabs/PWR-Validator/releases/download/$latest_version/validator.jar" && \
wget -O /root/config.json https://github.com/pwrlabs/PWR-Validator/raw/refs/heads/main/config.json && \
sudo ufw allow 8231/tcp && \
sudo ufw allow 8085/tcp && \
sudo ufw allow 7621/udp && \
sudo iptables -A INPUT -p tcp --dport 8085 -j ACCEPT && \
sudo iptables -A INPUT -p tcp --dport 8231 -j ACCEPT && \
sudo iptables -A INPUT -p udp --dport 7621 -j ACCEPT && \
sudo ufw reload && \
sudo pkill -f java && \
sudo systemctl restart pwr.service && \
sudo journalctl -u pwr.service -f
```

**Note**: V 13.0.0 introduced validator checks before the node starts. Make sure ports 8085 and 8231 are open for TCP and port 7621 is open for UDP.
**Note**: If port 7621 is open for UDP but the node is saying that it's offline, then just try starting the node over and over agin, because detecting UDP ports can sometimes be hard.


sudo systemctl start pwr.service

sudo systemctl restart pwr.service

sudo systemctl status pwr.service

sudo journalctl -u pwr.service -f

sudo systemctl daemon-reload
