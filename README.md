# openwrt-nanopi-r5s

docker network create \
-d macvlan \
--subnet=172.16.0.0/16 \
--ip-range=172.16.100.0/24 \
--gateway=172.16.0.1 \
-o macvlan_mode=bridge \
-o parent=eth1 vnet

docker network create \
--driver=macvlan \
--gateway=172.16.0.1 \
--subnet=172.16.0.0/16  \
--ip-range=172.16.10.0/24 \
-o parent=br-lan \
vnet


docker run -d --name=wxedge --restart=always --privileged --network my-macvlan-net --tmpfs /run --tmpfs /tmp -v /data/wxy:/storage:rw onething1/wxedge:3.0.2



---
cat docker-compose.yaml 
version: '3'
services:
  otc101:
    image: onething1/amd64-wxedge:2.4.3
    container_name: otc101
    restart: always
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1024M
        reservations:
          cpus: '1'
          memory: 1024M
    privileged: true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /data/otc/101:/storage:rw
    tmpfs:
      - /run
      - /tmp
    networks:
      enp3s0-network:
        ipv4_address: 192.168.5.101
    dns: 
      - 223.5.5.5
      - 119.29.29.29
  otc102:
    image: onething1/amd64-wxedge:2.4.3
    container_name: otc102
    restart: always
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1024M
        reservations:
          cpus: '1'
          memory: 1024M
    privileged: true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /data/otc/102:/storage:rw
    tmpfs:
      - /run
      - /tmp
    networks:
      enp3s0-network:
        ipv4_address: 192.168.5.102
    dns: 
      - 223.5.5.5
      - 119.29.29.29
  otc103:
    image: onething1/amd64-wxedge:2.4.3
    container_name: otc103
    restart: always
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1024M
        reservations:
          cpus: '1'
          memory: 1024M
    privileged: true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /data/otc/103:/storage:rw
    tmpfs:
      - /run
      - /tmp
    networks:
      enp3s0-network:
        ipv4_address: 192.168.5.103
    dns: 
      - 223.5.5.5
      - 119.29.29.29
  yykjonething:
    image: registry.cn-hangzhou.aliyuncs.com/yunyikj/onething:1.2
    container_name: yykjonething
    restart: always
    networks:
      enp3s0-network:
        ipv4_address: 192.168.5.10
    dns:
      - 192.168.3.1
      - 223.5.5.5
      - 119.29.29.29

networks:
  enp3s0-network:
    driver: macvlan
    driver_opts:
      parent: enp3s0
    ipam:
      config:
        - subnet: 192.168.5.0/24
          gateway: 192.168.5.1