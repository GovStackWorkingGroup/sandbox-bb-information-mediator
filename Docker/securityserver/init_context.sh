#!/bin/bash

DIR="../../X-Road"
if [ ! -d "$DIR" ]; then
  echo "Cloning X-Road source code from Github repository"
  git clone https://github.com/nordic-institute/X-Road.git $DIR
fi

