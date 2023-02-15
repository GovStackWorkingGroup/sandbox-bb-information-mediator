#!/bin/bash

DIR="../../X-Road"
if [ ! -d "$DIR" ]; then
  echo "Cloning X-Road source code from Github repository"
  git clone https://github.com/nordic-institute/X-Road.git $DIR
fi

echo "Initializing files for Docker"

rm -rf ./build
mkdir -p ./build

cp -r $DIR/ansible/roles/xroad-ca/files/etc ./build/
cp -r $DIR/ansible/roles/xroad-ca/files/home ./build/
cp -r ./files ./build/
