#!/bin/bash

# Usage run.sh -h db_host 
#              -i db_port 
#              -u db_admin_user 
#              -p db_admin_pass 
#              -n container_name 
#              -m image_name
#              -x central_server_db_pass
#
# Description of required command line arguments:
#
#   -h: remote database host
#   -i: remote database port
#   -u: remote database admin user
#   -p: remote database admin password
#   -n: container name
#   -m: image_name
#   -x: password of the user
#

DOCKER_IMG="centralserver"

usage() {
  echo "Usage: run.sh"
  echo " -h db_host"
  echo " -i db_port"
  echo " -u db_admin_user"
  echo " -p db_admin_pass"
  echo " -n container_name"
  echo " -m image_name"
  echo " -x central_server_db_pass"
}

exit_abnormal() {
  usage
  exit 1
}


build_docker() {
    host=$1
    port=$2
    adm_user=$3
    adm_pass=$4
    pass=$5
    
    ./init_context.sh
    docker build \
    --build-arg DIST=jammy-current \
    --build-arg REMOTE_DB_HOST=$host \
    --build-arg REMOTE_DB_PORT=$port \
    --build-arg REMOTE_DB_USER=$adm_user \
    --build-arg REMOTE_DB_PASS=$adm_pass \
    --build-arg CENTRAL_SERVER_DB_PASS=$pass \
    -t $DOCKER_IMG \
    -f Dockerfile .

}

run_docker() {
    container_name=$1
    docker run -p 4000:4000 -p 4001:80 -p 4002:9998 --name $container_name $DOCKER_IMG
}

create_new_image() {
    container_name=$1
    image_name=$2
    while [ $(docker inspect -f {{.State.Running}} $container_name) != "true" ];
    do
       echo "tere"
       sleep 1
    done
    container_id=$(docker ps -f name=$container_name --format '{{.ID}}')
    docker commit $container_id $image_name
}


while getopts ":h:i:u:p:n:m:x:" options; do
  case "${options}" in
    h )
      HOST=${OPTARG}
      ;;
    i )
      PORT=${OPTARG}
      ;;
    u )
      ADMUSER=${OPTARG}
      ;;
    p )
      ADMPASS=${OPTARG}
      ;;
    n )
      CONTAINER_NAME=${OPTARG}
      ;;  
    m )
      IMAGE_NAME=${OPTARG}
      ;;            
    x )
      PASS=${OPTARG}
      ;;
    \? )
        exit_abnormal
      ;;
  esac
done


if [[ $HOST == "" ]] | [[ $PORT == "" ]] | [[ $ADMUSER == "" ]] | [[ $ADMPASS == "" ]] | [[ $CONTAINER_NAME == "" ]] | [[ $IMAGE_NAME == "" ]] | [[ $PASS == "" ]]; then
    exit_abnormal
fi

#build_docker "$HOST" "$PORT" "$ADMUSER" "$ADMPASS" "$PASS"
run_docker "$CONTAINER_NAME"
#create_new_image "$CONTAINER_NAME" "$IMAGE_NAME"
#push_image_to_aws_ecr
