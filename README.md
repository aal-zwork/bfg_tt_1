### Run for test result
```bash
sudo usermod -aG docker $USER # Need docker rights

./make.sh # Create image and container

ansible-playbook -i inventory.yml install.yml
```

```
systemctl -t service
ls /opt/sos
ls /opt/sos/log
ls /opt/sos/venv
```


### Tools


```bash
./make.sh info # info container
./make.sh ssh # Connect via ssh to container
./make.sh exec # Connect via docker exec to container
```

```bash
./make.sh init # rebuild container
./make.sh stop # stop container
./make.sh remove # remove container
./make.sh # restart container
```