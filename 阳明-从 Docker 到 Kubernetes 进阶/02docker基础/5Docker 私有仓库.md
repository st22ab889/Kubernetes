1.docker的登录和退出登录

```javascript
docker login
docker logout
```

⽬前 Docker 官⽅维护了⼀个公共仓库 Docker Hub ，⼤部分需求都可以通过在 Docker Hub 中直接下 载镜像来实现。如果你觉得拉取 Docker Hub 的镜像⽐较慢的话，我们可以配置⼀个镜像加速 器：http://docker-cn.com/，当然国内⼤部分云⼚商都提供了相应的加速器，简单配置即可。



2.搜索镜像

```javascript
#比如搜索cendos镜像
docker search centos
```

可以看到返回了很多包含关键字的镜像，其中包括镜像名字、描述、收藏数（表示该镜像的受关注程 度）、是否官⽅创建、是否⾃动创建。

官⽅的镜像说明是官⽅项⽬组创建和维护的， automated 资源允许⽤户验证镜像的来源和内容。 根据是否是官⽅提供，可将镜像资源分为两类。 

- ⼀种是类似 centos 这样的镜像，被称为基础镜像或根镜像。这些基础镜像由 Docker 公司创建、 验证、⽀持、提供。这样的镜像往往使⽤单个单词作为名字。 

- 还有⼀种类型，⽐如 tianon/centos 镜像，它是由 Docker 的⽤户创建并维护的，往往带有⽤户名 称前缀。可以通过前缀 username/ 来指定使⽤某个⽤户提供的镜像，⽐如 tianon ⽤户。

 另外，在查找的时候通过 --filter=stars=N 参数可以指定仅显示收藏数量为 N 以上的镜像。下载官⽅ centos 镜像到本地.



3.推送镜像.

```javascript
#首先查找到一个镜像,然后选中一个镜像推送，
docker images

#"docker tag "表示标记本地镜像,将其归入某一仓库 
#格式: "docker tag 镜像名:TAG 用户名/镜像名:TAG",以推送"nginx:v2"为例:
docker tag nginx:v2 st22ab889/test-nginx:v2.1
#使用“docker images”查看可以看到多了一个名为“st22ab889/test-nginx”,TAG为“v2.1”的镜像.

#把镜像PUSH到公共的docker hub:
docker push st22ab889/test-nginx:v2.1   
```





4.私有仓库 (Docker Registry | Docker Documentation)

a.有时候使⽤ Docker Hub 这样的公共仓库可能不⽅便，⽤户可以创建⼀个本地仓库供私⼈使⽤。 docker-registry 是官⽅提供的⼯具，可以⽤于构建私有的镜像仓库。本⽂内容基于 docker-registry v2.x 版本。你可以通过获取官⽅ registry 镜像来运⾏(在使用一个镜像的时候最好使用一个指定的TAG，不要使用"latest"这样的TAG，因为最新的一直在变化.)。

```javascript
#注意以下三个命令的区别:

#a.这将使⽤官⽅的 registry 镜像来启动私有仓库。默认情况下，仓库会被创建在容器 的 /var/lib/registry ⽬录下.
docker run --name myregistry -d -p 5000:5000 registry:2.7.1
#运行"docker ps"可以看到私有仓库是否创建好.

#b.通过-v 参数来将镜像⽂件存放在本地的指定路径。例如下⾯的例⼦将上传的镜像放到本地的 /opt/data/registry ⽬录
$ docker run -d \ 
            -p 5000:5000 \ 
            -v /opt/data/registry:/var/lib/registry \ 
            registry

#c.添加参数"--restart=always",当 Docker 重启时，容器会自动启动。
docker run --name myregistry -d -p 5000:5000 --restart=always registry:2.7.1
```



b.把镜像推进私有仓库中.

```javascript
#使用"docjer iamges"查看有哪些镜像,选中一个镜像使⽤"docker tag"来标记，以"nginx:v2"为例:
#例如私有仓库地址为127.0.0.1:5000
#格式为 docker tag IMAGE[:TAG] [REGISTRY_HOST[:REGISTRY_PORT]/]REPOSITORY[:TAG] 
docker tag nginx:v2 127.0.0.1:5000/nginx:v2

#使用"docker images"查看是否多了一个“127.0.0.1:5000/nginx”这样的镜像.然后使⽤"docker push"上传标记的镜像.
docker push 127.0.0.1:5000/nginx:v2

#通过registry的api接口来查看当前的镜像.可以使用以下两种方式:
a.浏览器中打开"127.0.0.1:5000/v2/_catalog",如果看到"repositories"中有nginx说明镜像上传成功了.
b.使用命令"curl 127.0.0.1:5000/v2/_catalog"
```



c.从私有仓库中拉取镜像

```javascript
#删除本地镜像:
docker rmi 127.0.0.1:5000/nginx:v2

#拉取镜像(拉取镜像先看本地仓库有没有,本地仓库没有再去远程仓库找，本地有的话拉取镜像的速度相当快.如果多个镜像的层一样，那么它们的"IMAGE ID"也一样.)
docker pull 127.0.0.1:5000/nginx:v2 
```



5.如果你不想使⽤ 127.0.0.1:5000 作为仓库地址，⽐如想让本⽹段的其他主机也能把镜像推送到私有仓 库。你就得把例如 192.168.1.9:5000 这样的内⽹地址作为私有仓库地址，这时你会发现⽆法成功 推送镜像。 这是因为 Docker 默认不允许⾮ HTTPS ⽅式推送镜像。我们可以通过 Docker 的配置选项来取消这个 限制。



```javascript
#使用“ifconfig”(linux)、"ipconfig"(windows)查看内网IP.
docker tag nginx:v2 192.168.1.9:5000/nginx:v2

#运行下面的命令发现推送不成功,这是因为docker默认不允许用非https的方式推送镜像
docker push 192.168.1.9:5000/nginx:v2   
#通过配置取消https的限制，每种系统的方式不一样, windows的配置路径为: 打开docker -> 设置 ->Docker Engine
#在"registry-mirrors"中配置镜像加速器. example: "registry-mirrors": ["https://registry.docker-cn.com"]
#在"insecure-registries"中配置私有镜像仓库的IP和PORT.example: "insecure-registries": ["192.168.1.9:5000"]

#配置好后重新启动后容器会退出,所以要重新启动容器.
docker ps -a
docker start myregistry
docker push 192.168.1.9:5000/nginx:v2
#打开浏览器"127.0.0.1:5000/v2/_catalog"看到看到"repositories"中有nginx说明镜像上传成功了.

#验证,删除本地的镜像,如果根据IMAGEID删除,如果多个镜像的IMAGEID一样,则可以同时删除多个,但是命令中必须要加"-f"来强制删除
docker rmi -f cab41c5c9b05

docker pull 192.168.1.9:5000/nginx:v2
#成功的话可以看到镜像已经拉下来了
docker images
```



```javascript
#仓库持久化

#删除私有仓库容器
docker rm -f myregistry
#让后再启动,浏览器打开"127.0.0.1:5000/v2/_catalog"发现之前保存的nginx镜像没有了.
docker run --name myregistry -d -p 5000:5000 registry:2.7.1
#运行"docker images"发现本地的镜像还是有

#删除本地"192.168.1.9:5000/nginx:v2"镜像
docker rmi -f  192.168.1.9:5000/nginx:v2

#再次拉取
docker pull 192.168.1.9:5000/nginx:v2
#再次拉取发现没有了,这是因为默认情况下仓库会被创建到容器当中的"/var/lib/registry"下面
#容器删掉以后,"/var/lib/registry"这个目录也被删掉了,也就是说"/var/lib/registry"这个目录没有被持久化

#持久化"/var/lib/registry"目录(加-v参数,挂载数据卷)，也就是这个目录映射到宿主机。
docker rm -f myregistry
docker run --name myregistry -d -p 5000:5000  -v D:\MyDockerRegistryHub:/var/lib/registry registry:2.7.1
docker ps
docker tag nginx:v1 192.168.1.9:5000/nginx:v2
docker images
docker push 192.168.1.9:5000/nginx:v2
#可以看到"D:\MyDockerRegistryHub"中多了一些文件

验证:
docker rmi 192.168.1.9:5000/nginx:v2
docker rm -f myregistry
docker images
docker ps
#运行下面命令后打开"127.0.0.1:5000/v2/_catalog"发现nginx仍然在说明持久化成功.
docker run --name myregistry -d -p 5000:5000  -v D:\MyDockerRegistryHub:/var/lib/registry registry:2.7.1
#运行下面命令发现"192.168.1.9:5000/nginx:v2"又回来了.
docker pull 192.168.1.9:5000/nginx:v2

```



6.dockerhub镜像加速器,

a. 如果拉取镜像缓慢可以配置dockhub镜像加速器,有以下两种方式:

- http://docker-cn.com/

- 大部分云厂商也提供了镜像加速器，比如阿里云,创建阿里云账号后,在容器镜像服务中会专门生成“专属加速器地址”.

- 

b. 每种系统的方式不一样, windows的配置路径为: 打开docker -> 设置 ->Docker Engine，在"registry-mirrors"中配置镜像加速器,如下:

"registry-mirrors": ["https://registry.docker-cn.com"]