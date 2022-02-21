#!/usr/bin/env bash
set -e

INSTANCE_NAME=bfg_test_instance
IMAGE_NAME=bfg_test

INVENTORY_PATH=inventory.yml
INVENTORY_GROUP=.all
export DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}

stage=${1:-auto}

function staging() {
  stage=${1:-auto}
  if [ "$stage" = 'build' ]; then
    echo ">>Building..." 1>&2
    docker build -t $IMAGE_NAME ./
    echo
  elif [ "$stage" = 'init' ]; then
    echo ">>Init..." 1>&2
    docker build -t $IMAGE_NAME ./
    docker rm -vf $INSTANCE_NAME 1>/dev/null 2>&1
    docker run --mount type=bind,source=/sys/fs/cgroup,target=/sys/fs/cgroup \
      --mount type=bind,source=/sys/fs/fuse,target=/sys/fs/fuse \
      --mount type=tmpfs,destination=/run \
      --mount type=tmpfs,destination=/run/lock \
      --name $INSTANCE_NAME -d $IMAGE_NAME
  elif [ "$stage" = 'start' ]; then
    echo ">>Starting..." 1>&2
    docker start $INSTANCE_NAME
  elif [ "$stage" = 'stop' ]; then
    echo ">>Stopping..." 1>&2
    docker stop $INSTANCE_NAME
  elif [ "$stage" = 'ssh' ]; then
    docker_ip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' bfg_test_instance)
    ssh -i id_rsa_bfg_1 root@$docker_ip
  elif [ "$stage" = 'exec' ]; then
    docker exec -it bfg_test_instance bash
  elif [ "$stage" = 'remove' ]; then
    docker rm -vf $INSTANCE_NAME 1>/dev/null 2>&1
  elif [ "$stage" = 'info' ]; then
    docker_ip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' bfg_test_instance)
    yq -iy "${INVENTORY_GROUP}.hosts.${INSTANCE_NAME}.ansible_host=\"$docker_ip\"" $INVENTORY_PATH
    echo
    echo "Your APP:"
    echo "########################"
    echo "# http://$docker_ip"
    echo "# ssh -i id_rsa_bfg_1 root@$docker_ip"
    echo "########################"
    echo
  else
    echo "Error: type($stage) mast be build, init, start, stop, remove" 1>&2
    exit 1
  fi
}

if [ "$stage" = 'auto' ]; then
  [ "$(docker images -q $IMAGE_NAME)" = "" ] && staging build
  # staging build
  if [ "$(docker images -q $IMAGE_NAME)" = "" ]; then
    echo "Error: check build stage manualy (cant auto build)" 1>&2
    exit 2
  else
    if docker ps | grep -Eq "$INSTANCE_NAME\$"; then
      staging stop
      if docker ps | grep -Eq "$INSTANCE_NAME\$"; then
        echo "Error: check stop stage manualy (cant auto stop)" 1>&2
        exit 3
      else staging start; fi
    elif docker ps -a | grep -Eq "$INSTANCE_NAME\$"; then
      staging start
    else staging init; fi

  fi
else staging $stage; fi
