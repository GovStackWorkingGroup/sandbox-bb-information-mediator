#!/bin/bash

# Usage run.sh -h db_host 
#              -i db_port 
#              -u db_admin_user 
#              -p db_admin_pass 
#              -n container_name 
#              -m image_name
#              -r serverconf_admin_pass 
#              -s messagelog_admin_pass 
#              -t opmon_admin_pass 
#              -v serverconf_pass 
#              -w messagelog_pass 
#              -x opmon_pass
#
# Description of required command line arguments:
#
#   -h: remote database host
#   -i: remote database port
#   -u: remote database admin user
#   -p: remote database admin password
#   -n: container name
#   -m: image name 
#   -r: serverconf db admin password 
#   -s: messagelog db admin password
#   -t: opmon db admin password
#   -v: serverconf db user password
#   -w: messagelog db user password
#   -x: opmon db user password

DOCKER_IMG="xroad-security-server"

usage() {
  echo "Usage run.sh -h db_host"
  echo "-i db_port"
  echo "-u db_admin_user" 
  echo "-p db_admin_pass"
  echo "-n container_name" 
  echo "-m image_name" 
  echo "-r serverconf_admin_pass" 
  echo "-s messagelog_admin_pass" 
  echo "-t opmon_admin_pass" 
  echo "-v serverconf_pass" 
  echo "-w messagelog_pass" 
  echo "-x opmon_pass"
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
    serverconf_adm_pass=$5
    opmon_adm_pass=$6
    messagelog_adm_pass=$7
    serverconf_pass=$8
    opmon_pass=$9
    messagelog_pass=$10
    
    ./init_context.sh
    docker build \
    --build-arg REMOTE_DB_HOST=$host \
    --build-arg REMOTE_DB_PORT=$port \
    --build-arg REMOTE_DB_USER=$adm_user \
    --build-arg REMOTE_DB_PASS=$adm_pass \
    --build-arg SERVERCONF_ADMIN_PASS=$serverconf_adm_pass \
    --build-arg OPMONITOR_ADMIN_PASS=$opmon_adm_pass \
    --build-arg MESSAGELOG_ADMIN_PASS=$messagelog_adm_pass \
    --build-arg SERVERCONF_PASS=$serverconf_pass \
    --build-arg OPMONITOR_PASS=$opmon_pass \
    --build-arg MESSAGELOG_PASS=$messagelog_pass \
    -t $DOCKER_IMG \
    -f Dockerfile .

}

run_docker() {
    container_name=$1
    docker run -d -p 4100:4000 -p 8081:8080 --name $container_name $DOCKER_IMG
}

create_new_image() {
    container_name=$1
    image_name=$2
    while [ $(docker inspect -f {{.State.Running}} $container_name) != "true" ];
    do
       sleep 1
    done
    container_id=$(docker ps -f name=$container_name --format '{{.ID}}')
    docker commit $container_id $image_name
}

while getopts ":h:i:u:p:n:m:r:s:t:v:w:x:" options; do
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
    r )
      SERVERCONF_ADM_PASS=${OPTARG}
      ;;
    s )
      MESSAGELOG_ADM_PASS=${OPTARG}
      ;;
    t )
      OPMON_ADM_PASS=${OPTARG}
      ;;
    v )
      SERVERCONF_PASS=${OPTARG}
      ;;
    w )
      MESSAGELOG_PASS=${OPTARG}
      ;;                                    
    x )
      OPMON_PASS=${OPTARG}
      ;;
    \? )
        exit_abnormal
      ;;
  esac
done


if [[ $HOST == "" ]] | [[ $PORT == "" ]] | [[ $ADMUSER == "" ]] | [[ $ADMPASS == "" ]] | \
   [[ $CONTAINER_NAME == "" ]] | [[ $IMAGE_NAME == "" ]] | [[ $SERVERCONF_ADM_PASS == "" ]] | [[ $MESSAGELOG_ADM_PASS == "" ]] | \
   [[ $OPMON_ADM_PASS == "" ]] | [[ $SERVERCONF_PASS == "" ]] | [[ $MESSAGELOG_PASS == "" ]] | [[ $OPMON_PASS == "" ]]; then
    exit_abnormal
fi

build_docker "$HOST" "$PORT" "$ADMUSER" "$ADMPASS" "$CONTAINER_NAME" "$SERVERCONF_ADM_PASS" "$MESSAGELOG_ADM_PASS" "$OPMON_ADM_PASS" "$SERVERCONF_PASS" "$MESSAGELOG_PASS" "$OPMON_PASS"
run_docker "$CONTAINER_NAME"
create_new_image "$CONTAINER_NAME" "$IMAGE_NAME"
