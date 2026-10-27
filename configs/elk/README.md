# configs/elk

```
# Tren Ubuntu ELK (192.168.50.20)
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-elk.conf
docker compose up -d

# Nap index template (chay mot lan, truoc khi co du lieu)
curl -X PUT 'localhost:9200/_index_template/pfsense-parsed' \
  -H 'Content-Type: application/json' \
  -d @elasticsearch/index-template.json
```
