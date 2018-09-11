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
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
echo "sleeping for ${FABRIC_START_TIMEOUT} seconds to wait for fabric to complete start up"
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec peer0.org1.abw.com peer channel create -o orderer.abw.com:7050 -c $CHANNEL_NAME -f /etc/hyperledger/configtx/channel.tx

# Join peer0.org1.abw.com to the channel.
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.abw.com/msp" peer0.org1.abw.com peer channel join -b $CHANNEL_NAME.block