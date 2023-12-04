#!/bin/bash
# Builds preconfigured Sandbox X-Road images

cd "$(dirname -- "$0")"

REGISTRY=
PUSH=false
TAG=
VARIANTS=( ss1 ss2 ss3 )
DIGESTS=false

while getopts "r:t:pd" opt; do
  case "${opt}" in
    r)
      REGISTRY="${OPTARG}"
      ;;
    p)
      PUSH=true
      ;;
    t)
      TAG="${OPTARG}"
      ;;
    d)
      DIGESTS=true
      ;;
    *)
      echo "Usage: $0 -r <registry base url> [-t tag] [-p]"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

set -eo pipefail

IMAGE_BASE=${IMAGE:-bb/im/sandbox-x-road}
if [[ -z $REGISTRY ]]; then
  REPO=IMAGE_BASE
else
  REPO=${REGISTRY}/${IMAGE_BASE}
fi
TAG=${TAG:-latest}

if [[ $DIGESTS = "true" ]]; then
  tmp=$(docker inspect --format='{{index .RepoDigests 0}}' $REPO/central-server:$TAG-cs)
  echo "IMAGE_cs=$REPO/${tmp##*/}"
  for s in "${VARIANTS[@]}"; do
    tmp=$(docker inspect --format='{{index .RepoDigests 0}}' $REPO/security-server:$TAG-$s)
    echo "IMAGE_$s=$REPO/${tmp##*/}"
  done
  exit 0
fi

echo "Building Central Server images $REPO/central-server:$TAG"
docker build -q -t $REPO/central-server:$TAG sandbox-xroad-cs
docker build -q -t $REPO/central-server:$TAG-cs \
  --build-arg IMAGE=$REPO/central-server:$TAG \
  -f sandbox-xroad-cs/Dockerfile.preconf \
  sandbox-xroad-cs

echo -e "\nBuilding Security Server image $REPO/security-server:$TAG"
docker build -q -t $REPO/security-server:$TAG sandbox-xroad-ss

for s in "${VARIANTS[@]}"; do
echo -e "\nBuilding Security Server image $REPO/security-server:$TAG-$s"
docker build -q \
  -t $REPO/security-server:$TAG-$s \
  --build-arg IMAGE=$REPO/security-server:$TAG \
  --build-arg CONFIG="${s}_conf_backup.tar" \
  -f sandbox-xroad-ss/Dockerfile.preconf \
  sandbox-xroad-ss
done

if [[ -n $REGISTRY && $PUSH = true ]]; then
  echo -e "\nPushing images to $REGISTRY..."

  docker push $REPO/security-server:$TAG
  for s in "${VARIANTS[@]}"; do
    docker push $REPO/security-server:$TAG-$s
  done
  docker push $REPO/central-server:$TAG
  docker push $REPO/central-server:$TAG-cs
fi
