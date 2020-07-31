#!/bin/bash
export GOOS=linux
export GOARCH=amd64
# Set to use static linking
export CGO_ENABLED=0

# Build accountservice
cd accountservice;go get;go build -o accountservice-$GOOS-$GOARCH; echo built `pwd`;cd ..
# builds the healthchecker binary
cd healthchecker;go get;go build -o healthchecker-$GOOS-$GOARCH; echo built `pwd`;cd ..
# Build vipservice
cd vipservice;go get;go build -o vipservice-$GOOS-$GOARCH; echo built `pwd`;cd ..

# Image accountservice
cp healthchecker/healthchecker-$GOOS-$GOARCH accountservice/
docker build -t unusedprefix/accountservice accountservice/
# Image vipservice
cp healthchecker/healthchecker-$GOOS-$GOARCH vipservice/
docker build -t unusedprefix/vipservice vipservice/
# Image imageservice
cp healthchecker/healthchecker-$GOOS-$GOARCH imageservice/
docker build -t unusedprefix/imageservice imageservice/

docker service rm quotes-service
docker service rm accountservice
docker service rm vipservice
docker service rm imageservice

#GELF_ADDRESS=udp://192.168.50.3:12202
if [ ! -z ${GELF_ADDRESS+x}] 
then
	docker service create \
		--log-driver=gelf --log-opt gelf-address=$GELF_ADDRESS \
		--log-opt gelf-compression-type=none \
		--name=quotes-service --replicas=1 --network=my_network eriklupander/quotes-service
	docker service create \
		--log-driver=gelf --log-opt gelf-address=$GELF_ADDRESS \
		--log-opt gelf-compression-type=none \
		--name=accountservice --replicas=1 --network=my_network -p=6767:6767 unusedprefix/accountservice
	docker service create \
		--log-driver=gelf --log-opt gelf-address=$GELF_ADDRESS \
		--log-opt gelf-compression-type=none \
		--name=vipservice --replicas=1 --network=my_network unusedprefix/vipservice
	docker service create \
		--log-driver=gelf --log-opt gelf-address=$GELF_ADDRESS \
		--log-opt gelf-compression-type=none \
		--name=imageservice --replicas=1 --network=my_network unusedprefix/imageservice
else
	docker service create \
		--name=quotes-service --replicas=1 --network=my_network eriklupander/quotes-service
	docker service create \
		--name=accountservice --replicas=1 --network=my_network -p=6767:6767 unusedprefix/accountservice
	docker service create \
		--name=vipservice --replicas=1 --network=my_network unusedprefix/vipservice
	docker service create \
		--name=imageservice --replicas=1 --network=my_network unusedprefix/imageservice
fi
