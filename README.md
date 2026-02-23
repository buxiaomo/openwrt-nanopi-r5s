# openwrt-nanopi-r5s

```
docker network create \
--driver=macvlan \
--subnet=172.16.0.0/16 \
--gateway=172.16.1.1 \
--ip-range=172.16.10.0/24 \
-o parent=br-lan \
vnet

ip link add macvlan0 link br-lan type macvlan mode bridge
ip addr add 172.16.10.1/16 dev macvlan0

ip link set macvlan0 up


docker run -d \
--name h5ai \
--restart=always \
--network vnet \
--ip 172.16.10.2 \
-v /data/Container/volume/h5ai:/var/www/html \
ghcr.io/buxiaomo/h5ai:0.30.1

docker run -d \
--privileged \
--name=xunlei \
-p 5055:5055 \
-v /data/Container/volume/xunlei:/opt/data \
-v /data/Videos:/downloads \
-e XUNLEI_AUTH_USER=admin \
-e XUNLEI_AUTH_PASSWORD=admin \
gngpp/xunlei:latest
```
