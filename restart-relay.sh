#!/bin/bash -e

if [ "$1" == "help" ]; then

echo Usage:
echo "  $0 provider - Connect to external provider with relayhub Addr and other params too"
echo "  $0      - (no args) start HttpRelayServer with ganache and default parameters, and wait"
exit 1

else 
	echo "use '$0 help' for usage."
fi

function onexit() {
	echo onexit
	pkill -f ganache
	pkill -f RelayHttpServer
}

trap onexit EXIT

dir=`dirname $0`
root=`cd $dir;pwd`

cd $root
#todo: should compile the server elsewhere.
gobin=$root/build/server/bin/
export GOPATH=$root/server/:$root/build/server
echo "Using GOPATH=" $GOPATH
# cd $gobin
./scripts/extract_abi.js
make -C server 
#todo: run if changed..
blocktime=${T=0}

pkill -f ganache-cli && echo killed old ganache.
pkill -f RelayHttpServer && echo kill old relayserver

if [ "$withOutGanache" != "true" ]; then

GANACHE="$root/node_modules/.bin/ganache-cli -l 8000000 -b $blocktime -a 11 -h 0.0.0.0 "

if [ -n "$DEBUG" ]; then
	$GANACHE -d --verbose &
else
	#just display ganache version
	sh -c "$GANACHE -d |grep ganache-core" &
fi

sleep 2

if ! pgrep  -f ganache > /dev/null ; then
	echo FATAL: failed to start ganache.
	exit 1
fi

hubaddr=`truffle migrate | tee /dev/stderr | grep -A 4 "RelayHub" | grep "contract address" | grep "0x.*" -o`

echo $hubaddr

if [ -z "$hubaddr" ]; then
echo "FATAL: failed to detect RelayHub address"
exit 1
fi

#fund relay:
relayurl=http://localhost:8090
( sleep 5 ; ./scripts/fundrelay.js $hubaddr $relayurl 0 ) &


$gobin/RelayHttpServer -RelayHubAddress $hubaddr -Workdir $root/build/server -RegistrationURL http://localhost:8090

else
if [ -z "$registrationURL" ]; then
	registrationURL="http://localhost:8090"
fi

if [ -z "$provider" ]; then
	provider="http://localhost:8545"
fi

if [ -z "$gasLimit" ]; then
	gasLimit="100000"
fi

if [ -z "$defaultGasPrice" ]; then
	defaultGasPrice="10000000000"
fi
	

$gobin/RelayHttpServer -RelayHubAddress $hubaddr -Workdir $root/build/server -RegistrationURL $registrationURL -EthereumNodeUrl $provider -GasLimit $gasLimit -DefaultGasPrice $defaultGasPrice
	
fi