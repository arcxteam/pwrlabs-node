```
curl -o install_pwr_validator.sh -L "https://raw.githubusercontent.com/arcxteam/pwrlabs-node/main/install_pwr_validator.sh" && chmod +x install_pwr_validator.sh
```

run node validator

```
sudo ./install_pwr_validator.sh
```

sudo systemctl start pwr.service
sudo systemctl status pwr.service
sudo journalctl -u pwr.service -f

sudo systemctl restart pwr.service
sudo systemctl status pwr.service
sudo journalctl -u pwr.service -f

sudo systemctl daemon-reload
sudo systemctl restart pwr.service