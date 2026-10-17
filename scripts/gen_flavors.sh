#!/bin/bash
if [ ! -d "scripts" ]; then
  cd ..
fi

scripts/gen_flavor_libre.sh
