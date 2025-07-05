1.docker的4种网络模式

- Bridge网络模式

- host网络模式

- Container 网络模式

- None网络模式

- overlay

- ipvlan

- macvlan

- Network plugins: You can install and use third-party network plugins with Docker.



```javascript
overlay
https://www.51cto.com/article/716550.html
https://blog.csdn.net/weixin_46398572/article/details/140179705
Overlay技术是一种网络虚拟化技术，它允许在现有的物理网络基础上构建一个或多个逻辑网络。
Overlay网络的核心在于数据包的封装和解封装。常见的封装技术包括VXLAN(Virtual eXtensible Local Area Network)、NVGRE和STT等。

==========================================================================================

macvlan和ipvlan的区别: https://blog.csdn.net/renchao7060/article/details/146284995

macvlan 允许在单个物理网络接口上创建多个虚拟网络接口，每个虚拟接口拥有 独立的 MAC 地址 和 IP 地址。

ipvlan 允许在单个物理接口上创建多个虚拟接口，共享物理接口的 MAC 地址，但使用 独立 IP 地址。
    L2 模式：虚拟接口在数据链路层（Layer 2）工作，共享广播域。 L2 是 MAC 协议
    L3 模式：虚拟接口在网络层（Layer 3）工作，独立路由表。 L3 是 IP 协议
```



2.Bridge网络模式

```javascript
#运行以下命令查看docker支持的网络模式
docker network ls

#docker默认的网络模式是Bridge

#BusyBox 是一个集成了三百多个最常用Linux命令和工具的软件。
#BusyBox 包含了一些简单的工具，例如ls、cat和echo等等，还包含了一些更大、更复杂的工具，例grep、find、mount以及telnet。有些人将 BusyBox 称为 Linux 工具里的瑞士军刀。
#简单的说BusyBox就好像是个大工具箱，它集成压缩了 Linux 的许多工具和命令，也包含了 Linux 系统的自带的shell。

#启动busybox容器
docker run --name testdockernet1 -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"
docker run --name testdockernet2 -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"
#进入容器内部,发现两个容器能互相ping通

#强制删除testdockernet2,使用"--link"参数使两个容器互通
#"--link"其实就是dns设置,进入容器在host文件中就可以看到
docker rm -f testdockernet2 
docker run --name testdockernet2 --link testdockernet1 -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"
#这样不仅可以ping IP，还可以ping容器名称,都可以拼通
#"--link"是单向的, 在testdockernet2容器中使用"ping testdockernet1"可以成功,但是在testdockernet1容器中使用"ping testdockernet2"失败,只能ping testdockernet2的IP.

#创建新的docker网络使网络互联互通.
#"-d"参数指定Docker⽹络类型，有bridge和overlay.其中overlay⽹络类型⽤于Swarm mode,在本⼩节中你可以忽略它.
docker network create -d bridge demoNet
docker network ls
#可以看到创建的demoNet网络信息,比如网关、子网等信息
docker network inspect demoNet

#给容器指定创网络,使用"--network"或--net"
#给testdockernet3和testdockernet4容器指定demoNet这个网络
docker run --name testdockernet3 --network demoNet -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"
docker run --name testdockernet4 --network demoNet -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"

#经过验证,testdockernet3和testdockernet4容器可以拼通,不仅可以互拼IP,还可以互拼容器名称.
#如果有多个容器需要互相连接,还是推荐使用"Docker Compose"
#运行如下命令可以看到在containers节点有使用demoNet这个网络的容器信息
docker network inspect demoNet 

#linux冲查看网络信息的命令
ip a
ifconfig -a
```



3.host网络模式

如果启动容器的时候使⽤ host 模式，那么这个容器将不会获得⼀个独⽴的 Network Namespace ，⽽是 和宿主机共⽤⼀个 Network Namespace。容器将不会虚拟出⾃⼰的⽹卡，配置⾃⼰的 IP 等，⽽是使 ⽤宿主机的 IP 和端⼝。但是，容器的其他⽅⾯，如⽂件系统、进程列表等还是和宿主机隔离的。

```javascript
#指定testdockernet5容器使用host网络
docker run --name testdockernet5 --network host -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"  

docker exec -it testdockernet5 /bin/sh
#发现容器和宿主机使用的是一样的网络
ifconfig -a
exit

```



4.Container 网络模式

这个模式指定新创建的容器和已经存在的⼀个容器共享⼀个 Network Namespace，⽽不是和宿主机共 享。新创建的容器不会创建⾃⼰的⽹卡，配置⾃⼰的 IP，⽽是和⼀个指定的容器共享 IP、端⼝范围 等。同样，两个容器除了⽹络⽅⾯，其他的如⽂件系统、进程列表等还是隔离的。两个容器的进程可 以通过 lo ⽹卡设备通信。

```javascript
#使用"--network container:容器名"指定要使用的目标容器
#testdockernet6和testdockernet4容器共用testdockernet4这个网络
docker run --name testdockernet6 --network container:testdockernet4 -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"  

docker ps

#运行下面的命令就会发现两个容器的网络信息是一样的,它们通过"lo(回环网络,也就是127.0.0.1)来通信"
docker exec -it testdockernet6 /bin/sh
if config -a
exit

docker exec -it testdockernet4 /bin/sh
if config -a
exit

```



5.None网络模式

使⽤ none 模式，Docker 容器拥有⾃⼰的 Network Namespace，但是，并不为Docker 容器进⾏任何 ⽹络配置。也就是说，这个 Docker 容器没有⽹卡、IP、路由等信息。需要我们⾃⼰为 Docker 容器添 加⽹卡、配置 IP 等.

```javascript
#创建一个容器使用none网络模式
docker run --name testdockernet7 --network none -d busybox /bin/sh -c "while true; do echo hello world; sleep 10; done"  
docker ps
docker exec -it testdockernet7 /bin/sh
#运行下面命令发现并没有生成eth0这个网卡,也没有自己的IP地址
if config -a

#Linux系统的route命令用于显示和操作IP路由表,"-n"表示不解析名字,列出速度会比route快.
#要实现两个不同的子网之间的通信,需要一台连接两个网络的路由器,或者同时位于两个网络的网关来实现.
route -n

exit
```



这种模式的容器不能进行网络通信,在某些特定的情况下还是有用的,比如需要在一些容器当中用来生成或存储一些密码,不想让外面的人来访问到这个容器,所以这种网络模式还是有必要的.



5.上面讲的都是单机的网络模式,假如有两个主机上面都有docker，这两台主机之间的docker如何通信,docker默认会用docker0分配一个子网,如果两个节点没有任何联系,那么节点与节点之间的容器的IP就容易冲突,这个时候可能就会用到分布式存储把容器的IP或子网信息存储下来,docker跨主机通信会在k8s中讲到这部分.





6.linux命令

```javascript
#列出历史命令中有包含"link"字符串的命令
history | grep link
```

