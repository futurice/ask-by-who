#!/bin/bash

# Grab the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DOCKER_FILE="${PWD}"/docker-compose-pc1.yaml

if [ -z ${CHANNEL_NAME+x} ]; then
  echo "CHANNEL_NAME env variable is not set. exiting..."
  exit 1
else
  echo "channel name: '$CHANNEL_NAME'"
fi

docker-compose -f "${DOCKER_FILE}" down
docker-compose -f "${DOCKER_FILE}" up -d

# wait for Hyperledger Fabric to start
# in case of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
DEFAULT_TIMEOUT=15
echo "sleeping for ${FABRIC_START_TIMEOUT-$DEFAULT_TIMEOUT} seconds to wait for fabric to complete start up"
sleep ${FABRIC_START_TIMEOUT-$DEFAULT_TIMEOUT}s

# Windows/Git-bash specific hack, no effect elsewhere. Details:
# https://stackoverflow.com/questions/44921180/cannot-run-peer-because-cannot-init-crypto
export MSYS_NO_PATHCONV=1

# Create the channel
docker exec cli peer channel create -o orderer.abw.com:7050 -c $CHANNEL_NAME -f /etc/hyperledger/configtx/channel.tx

# Join cli to the channel.
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.abw.com/msp" cli peer channel join -b $CHANNEL_NAME.block