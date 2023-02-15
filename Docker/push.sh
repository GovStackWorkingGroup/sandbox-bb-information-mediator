#!/bin/bash

# Usage push.sh -c container_name -i image_name
#
# Description of required command line arguments:
#
#   -c: container name
#   -e: aws_ecr
#   -i: image_name
#   -p: aws_profile_name
#

DOCKER_IMG="centralserver"

usage() {
  echo "Usage: push.sh -c container_name -e aws_ecr -i image_name -p aws_profile_name"
}

exit_abnormal() {
  usage
  exit 1
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

push_image_to_aws() {
    aws_profile=$1
    image_name=$2
    aws_ecr=$3
    aws ecr get-login-password --profile $aws_profile 
    docker tag $image_name:latest $aws_ecr:$image_name
    docker push $aws_ecr:$image_name
}


while getopts ":c:e:i:p:" options; do
  case "${options}" in
    c )
      CONTAINER_NAME=${OPTARG}
      ;;  
    e )
      AWS_ECR=${OPTARG}
      ;;        
    i )
      IMAGE_NAME=${OPTARG}
      ;;
    p )
      AWS_PROFILE=${OPTARG}
      ;;                  
    \? )
        exit_abnormal
      ;;
  esac
done


if [[ $CONTAINER_NAME == "" ]] | [[ $AWS_ECR == "" ]] | [[ $IMAGE_NAME == "" ]] | [[ $AWS_PROFILE == "" ]]; then
    exit_abnormal
fi

create_new_image "$CONTAINER_NAME" "$IMAGE_NAME"
push_image_to_aws "$AWS_PROFILE" "$IMAGE_NAME" "$AWS_ECR"
