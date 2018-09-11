# HYPERLEDGER FABRIC ABW NETWORK
> Hyperledger Fabric network shenanigans

## THIS IS NOT WORKING, ONLY PATHETIC SHENANIGANS

```bash
export CHANNEL_NAME=abw

# Make sure you have the `cryptogen` and `configtxgen` binaries
# in your PATH before proceeding.
# read: https://hyperledger-fabric.readthedocs.io/en/release-1.2/install.html

# Generates crypto-config and channel-artifacts
./generate.sh

# Start fabric containers and create channel
./startFabric.pc1.sh
```