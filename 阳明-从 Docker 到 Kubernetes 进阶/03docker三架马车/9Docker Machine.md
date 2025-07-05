

 ker 1.介绍

Docker Machine 是 Docker 官⽅编排（Orchestration）项⽬之⼀，负责在多种平台上快速安装 Docker 环境。 

Docker Machine 项⽬基于 Go 语⾔实现，⽬前在Github上进⾏维护。 

Docker Machine 是 Docker 官⽅提供的⼀个⼯具，它可以帮助我们在远程的机器上安装 Docker，或者 在虚拟机 host 上直接安装虚拟机并在虚拟机中安装 Docker。我们还可以通过 docker-machine 命令来 管理这些虚拟机和 Docker。



2.Docker Machine安装

如果把远程的docker也用docker-machine管理起来也是可以的,一般来说在实际的项目中用docker-machine管理线上的docker还不是很多,所以docker-machine可以了解一下.但如果是个人用户,可以用docker-machine来管理虚拟主机上的、云主机上的、本地的docker都可以.



```javascript
#使用如下命令可以查看docker的client和server的版本, 但是当前client和server都是在本地,但是可以把server改为远程主机.
docker version

#安装. windows和mac版本已经自带Docker Machine, linux.  
#linux可以通过如下地址获取安装命令或文件,同时也提供了其它的系统的安装命令或文件
https://github.com/docker/machine/releases
#docker for windows 的3.5.2版本没有docker machine,需要手动安装

#在windons使用如下方式(On Windows with git bash)安装只能在git bash中使用docker-machine命令
$ if [[ ! -d "$HOME/bin" ]]; then mkdir -p "$HOME/bin"; fi && \
curl -L https://github.com/docker/machine/releases/download/v0.16.2/docker-machine-Windows-x86_64.exe > "$HOME/bin/docker-machine.exe" && \
chmod +x "$HOME/bin/docker-machine.exe" 

#查看docker machine的版本
docker-machine -v

```





docker-machine支持多种后端驱动,包括虚拟机、本地主机、很多云平台.

```javascript
#使用docker-machine管理虚拟机上的docker

#主板开启 VT-X/AMD-v
#创建本地virtualbox虚拟主机在windows上首先要下载安装virtualbox软件,否则会报: Error with pre-create check: "VBoxManage not found. Make sure VirtualBox is installed and VBoxManage is in the path"
#如果主板开启VT-X/AMD-v,运行命令报错：Error with pre-create check: "This computer doesn't have VT-X/AMD-v enabled. Enabling it in the BIOS is mandatory"
#	管理员权限打开cmd,检查Hyper-V设置，执行命令: bcdedit , 查看hypervisorlaunchtype值为“Auto”
#	关闭hypervisorlaunchtype,执行命令: bcdedit /set hypervisorlaunchtype off，设置后"Docker Desktop"不能启动,要启动要重启设置hypervisorlaunchtype值为“Auto”
#	重启计算机.  参考:https://www.freesion.com/article/5478234919/
#创建本地虚拟机."-d"意思是"--driver",这个命令在"git bash"中运行
#之前没有创建过,第一步会去网站下载boot2docker.iso. 也可以离线下载下来拷贝到"C:\Users\WuJun\.docker\machine\cache\"目录(不同的系统目录不同),接下来会创建SSH认证,网络等.
docker-machine create -d virtualbox virtualboxTest

#To see how to connect your Docker Client to the Docker Engine running on this virtual machine(不同的系统命令不同), run:
#这个命令要在CMD下运行.
C:\Users\WuJun\bin\docker-machine.exe env virtualboxTest
#运行上面命令得出如下结果:
	SET DOCKER_TLS_VERIFY=1
	SET DOCKER_HOST=tcp://192.168.99.100:2376
	SET DOCKER_CERT_PATH=C:\Users\WuJun\.docker\machine\machines\virtualboxTest	#证书文件
	SET DOCKER_MACHINE_NAME=virtualboxTest
	SET COMPOSE_CONVERT_WINDOWS_PATHS=true
	REM Run this command to configure your shell:		#执行如下命令配置shell
	REM     @FOR /f "tokens=*" %i IN ('"C:\Users\WuJun\bin\docker-machine.exe" env virtualboxTest') DO @%i

#执行配置shell的命令(CMD中运行)
@FOR /f "tokens=*" %i IN ('"C:\Users\WuJun\bin\docker-machine.exe" env virtualboxTest') DO @%i

#查看docker版本,client仍然是本地的client版本,但server版本是刚刚启动的virtualbox虚拟主机中的docker版本.
docker version

#登录到docker-machine
docker-machine ssh virtualboxTest

#登录到docker-machine可以运行一些命令
cat log.log

#查看虚拟主机内部有哪些镜像
docker iamges

#在虚拟主机中拉取一个镜像
docker pull alpine

#查看虚拟主机内部docker的client和server版本
docker version

#把virtualbox这个虚拟主机的8000端口映射到容器中的80端口
docker run -d --name mynginx -p 8000:80 nginx

#查看容器是否启动
docker ps

#打开一个新的"git bash"窗口或使用"exit"退出当前连接的虚拟主机
#使用"docker-machine ip virtualboxTest"查看virtualboxTest这个machine的IP地址

#验证
#在命令行窗口中输入"curl 192.168.99.100:8000"，看是否返回nginx的主页
#在浏览器中输入"192.168.99.100:8000"，看是否能打开nginx的主页

#退出virtualboxTest这个虚拟主机
exit

```





```javascript
#管理远程机器(首先远程要有一个主机,可以是windows、linux、unix等系统)
#"--generic-ip-address"指定IP;"--generic-ssh-user"指定用户,如果是普通用户还可以加权限;"--generic-ssh-key"指定SSH密钥
docker-machine create -d generic --generic-ip-address=123.59.188.19 --generic-ssh-user=root --generic-ssh-key ~/.ssh/id_rsa dev 

#运行以下命令发现name为dev的machine的state是TIMEOUT,这是因为远程没有这样一个机器,所以连不上.
#连上了可以查看machine的IP地址、状态等信息
docker-machine ls

#移除docker-machine
docker-machine rm dev
```





附 ：docker-machine相关的一些命令:

```javascript
#启动machine(git bash中才可执行),每次启动可能重新分配IP地址,可以使用"docker-machine env virtualboxTest查看"
docker-machine start virtualboxTest

#停止machine(git bash中才可执行)
docker-machine stop virtualboxTest

#查看virtualboxTest这个machine的环境信息
docker-machine env virtualboxTest

#如果不指定machine的名称或默认指定一个
docker-machine env

#获取virtualboxTest这个虚拟主机的url
docker-machine url virtualboxTest

#查看virtualboxTest这个machine的连接信息
docker-machine config virtualboxTest

#查看virtualboxTest这个machine的更多信息(元数据)
docker-machine inspect virtualboxTest

#查看查看virtualboxTest这个machine的IP地址
docker-machine ip virtualboxTest

#查看virtualboxTest这个虚拟主机的状态
docker-machine status virtualboxTest

#查看docker-machine的help
docker-machine help
```



3.使用docker-machine管理虚拟机上的docker注意事项.



如果主板开启VT-X/AMD-v,运行命令报错：Error with pre-create check: "This computer doesn't have VT-X/AMD-v enabled. Enabling it in the BIOS is mandatory", 有以下两种解决办法,推荐使用第二种方法:



第一种(参考:https://www.freesion.com/article/5478234919/):

- 管理员权限打开cmd,检查Hyper-V设置，执行命令: bcdedit , 查看hypervisorlaunchtype值为“Auto”.

- 关闭hypervisorlaunchtype,执行命令: bcdedit /set hypervisorlaunchtype off，设置后"Docker Desktop"不能启动,要启动要重启设置hypervisorlaunchtype值为“Auto”

- 重启计算机.



第二种(参考:https://zhangxueliang.blog.csdn.net/article/details/114684466):

添加"--virtualbox-no-vtx-check"参数,以下两种格式都可以:

- docker-machine create virtualboxTest --virtualbox-no-vtx-check

- docker-machine create -d virtualbox --virtualbox-no-vtx-check virtualboxTest

