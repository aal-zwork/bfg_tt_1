#### Run for test result:
```bash
./make.sh

ansible-playbook -i inventory.yml install.yml
```

#### Tools


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