#!/bin/bash

export FABRIC_CFG_PATH=${PWD}

function generateCerts() {
  # Check if cryptogen is set
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi

  # Check if NS var is set
  # Nevermind, Apparently env variables arent't being resolved for some reason :/
  # if [ -z ${NS+x} ]; then
  #   echo "variable for determining namespace is unset. exiting"
  #   exit 1
  # else
  #   echo "generating certificates with a namespace of '$NS'"
  # fi

  # Start cryptogen
  echo 
  echo "● GENERATING CERTIFICATES USING CRYPTOGEN TOOL"

  if [ -d "crypto-config" ]; then
    echo "crypto-config/ already exists. removing"
    rm -Rf crypto-config
  fi

  cryptogen generate \
  --output="crypto-config" \
  --config=./crypto-config.yaml

  if [ "$?" -ne 0 ]; then
    echo "failed to generate certificates"
    exit 1
  fi
  
  echo
}

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo
  echo "● GENERATING ORDERER GENESIS BLOCK"
  configtxgen -profile TwoOrgsOrdererGenesis \
  -outputBlock ./channel-artifacts/genesis.block
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

  echo
  echo "● GENERATING CHANNEL CONFIGURATION TRANSACTION [ channel.tx ]"
  configtxgen -profile TwoOrgsChannel \
  -outputCreateChannelTx ./channel-artifacts/channel.tx \
  -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel config transaction. exiting..."
    exit 1
  fi

  echo
  echo "● GENERATING ANCHOR PEER UPDATE [ Org1 ]"
  configtxgen -profile TwoOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx \
  -channelID $CHANNEL_NAME \
  -asOrg Org1
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1. exiting"
    exit 1
  fi

  echo
  echo "● GENERATING ANCHOR PEER UPDATE [ Org2 ]"
  configtxgen -profile TwoOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx \
  -channelID $CHANNEL_NAME \
  -asOrg Org2
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org2. exiting"
    exit 1
  fi
}

if [ -z ${CHANNEL_NAME+x} ]; then
  echo "CHANNEL_NAME env variable is not set. exiting..."
  exit 1
else
  echo "channel name: '$CHANNEL_NAME'"
fi

generateCerts
generateChannelArtifacts