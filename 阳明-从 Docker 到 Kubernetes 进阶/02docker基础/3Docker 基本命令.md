 镜像的获取: 

1.docker提供的公共镜像仓库:  Docker Hub Container Image Library | App Containerization，默认会从公共镜像仓库获取镜像.



2.获取镜像的命令:

docker pull [选项] [Docker Registry 地址[:端⼝]/]仓库名[:标签]

Docker 镜像仓库地址：地址的格式⼀般是 <域名/IP>[:端⼝号]，默认地址是 Docker Hub。

仓库名：这⾥的仓库名是两段式名称，即 <⽤户名>/<软件名>。对于 Docker Hub，如果不给出⽤ 户名，则默认为 library，也就是官⽅镜像.



如下示例:

- docker pull registry.docker-cn.com/rancher/heapster-grafana-amd64:v4.4.3

- docker pull registry.cn-hangzhou.aliyuncs.com/rancher/heapster-grafana-amd64:v4.4.3

- docker pull 127.0.0.1:5000/nginx:v2 



3.示例:

docker pull ubuntu:16.04

上⾯的命令中没有给出 Docker 镜像仓库地址，因此将会从 Docker Hub 获取镜像。⽽镜像名称是 ubuntu:16.04，因此将会获取官⽅镜像 library/ubuntu 仓库中标签为 16.04 的镜像。 从下载过程中 可以看到我们之前提及的分层存储的概念，镜像是由多层存储所构成。下载也是⼀层层的去下 载，并⾮单⼀⽂件。下载过程中给出了每⼀层的 ID 的前 12 位。并且下载结束后，给出该镜像完 整的 sha256 的摘要，以确保下载⼀致性



3.以镜像为基础运行一个容器

docker run -it --rm  ubuntu:16.04   /bin/bash

1. -it：这是两个参数，⼀个是 -i：交互式操作，⼀个是 -t 终端。我们这⾥打算进⼊ bash 执⾏⼀些命 令并查看返回结果，因此我们需要交互式终端。

1.  --rm：这个参数是说容器退出后随之将其删除。默认情况下，为了排障需求，退出的容器并不会⽴ 即删除，除⾮⼿动 docker rm。我们这⾥只是随便执⾏个命令，看看结果，不需要排障和保留结 果，因此使⽤ --rm 可以避免浪费空间。 

1. ubuntu:16.04：这是指⽤ ubuntu:16.04 镜像为基础来启动容器。 

1. bash：放在镜像名后的是命令，这⾥我们希望有个交互式 Shell，因此⽤的是 bash。

1. 进⼊容器后，我们可以在 Shell 下操作，执⾏任何所需的命令。这⾥，我们执⾏了 cat /etc/osrelease ，这是 Linux 常⽤的查看当前系统版本的命令，从返回的结果可以看到容器内是 Ubuntu 16.04.4 LTS 系统。最后我们通过 exit 退出了这个容器。



4.列出镜像：列表包含了仓库名、标签、镜像 ID、创建时间以及所占⽤的空间。镜像 ID 则是镜像的唯⼀标识，⼀ 个镜像可以对应多个标签

docker image ls

docker image

如果仔细观察，会注意到，这⾥标识的所占⽤空间和在 Docker Hub 上看到的镜像⼤⼩不同。⽐如， ubuntu:16.04 镜像⼤⼩，在这⾥是 127 MB，但是在Docker Hub显示的却是 43 MB。这是因为 Docker Hub 中显示的体积是压缩后的体积。在镜像下载和上传过程中镜像是保持着压缩状态的，因此 Docker Hub 所显示的⼤⼩是⽹络传输中更关⼼的流量⼤⼩。⽽ docker image ls 显示的是镜像下载到本地 后，展开的大小，准确说，是展开后的各层所占空间的总和，因为镜像到本地后，查看空间的时候， 更关⼼的是本地磁盘空间占⽤的⼤⼩。 另外⼀个需要注意的问题是， docker image ls 列表中的镜像体积总和并⾮是所有镜像实际硬盘消 耗。由于 Docker 镜像是多层存储结构，并且可以继承、复⽤，因此不同镜像可能会因为使⽤相同的基 础镜像，从⽽拥有共同的层。由于 Docker 使⽤ Union FS ，相同的层只需要保存⼀份即可，因此实际 镜像硬盘占⽤空间很可能要⽐这个列表镜像⼤⼩的总和要⼩的多



5.的查看 镜像、容器、数据卷所占⽤的空间

docker system df



6.退出的容器重新起动

第1步查看退出状态的容器名称(容器ID): docker container ls --all

第2步启动容器: docker start [容器名称(容器ID)]

例如: docker start bd42f0507514

第3步查看容器是否启动,可以查看日志: docker logs [容器名称(容器ID)]

例如: docker logs bd42f0507514



重启容器:  docker restart [容器名称(容器ID)]

停止/退出容器 : docker stop [容器名称(容器ID)]



删除容器 ：docker container rm [容器名称(容器ID)]

 		    docker rm [容器名称(容器ID)]

      		    docker rm -f  [容器名称(容器ID)]

运行中的容器不能被删除,加上"-f"表示强制删除.



7.镜像操作 

查看所有镜像的信息 ：docker images



根据镜像名称(REPOSITORY)删除：

docker image rm  REPOSITORY:[TAG]

docker image rm  REPOSITORY  //也可以不要TAG

docker rmi  REPOSITORY:[TAG]



根据镜像ID(IMAGE ID)删除：

docker image rm 镜像ID

docker rmi  镜像ID



8.后台运行容器,"docker run"是执行一次就退出了.更多的时候，需要让 Docker 在后台运⾏⽽不是直接把执⾏命令的结果输出在当前宿主机下。此时，可 以通过添加 -d 参数来实现



a. 容器会把输出的结果 (STDOUT) 打印到宿主机上⾯

docker run ubuntu:16.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"

-c 表示执行后面的脚本



b.使⽤了 -d 参数运⾏容器,此时容器会在后台运⾏并不会把输出的结果 (STDOUT) 打印到宿主机上⾯(输出结果可以⽤ docker logs 查看)

docker run -d ubuntu:16.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"



注：“docker logs -f 容器ID”可以让日志一直在宿主机上面打印



注： 容器是否会⻓久运⾏，是和 docker run 指定的命令有关，和 -d 参数⽆关。



使⽤ -d 参数启动后会返回⼀个唯⼀的 id，也可以通过 docker container ls 命令来查看容器信息



9.进入到容器中

docker exec -it  容器名称或ID /bin/bash

进去后退出使用“exit”.



10.定制镜像

A.用nginx的镜像启动一个容器,这个容器的名称叫webservice 

docker run --name webservice -d -p 80:80 nginx

--name: 给制定的容器指定一个名字

-d:表示后台执行

-p:端口映射

    -p 80:80:把宿主机的80端口映射到容器的80端口

    nginx:使用nginx这样的一个容器 



启动起来后用"docker ps"查看是否启动成功.

可以在浏览器中输入 "localhost:80"访问nginx.



B.定制镜像, 例如 “修改nginx的默认页面”,依次输入以下4个命令:

docker exec -it webservice  /bin/bash

ls /usr/share/nginx/html/index.html

echo '<h1>hello nginx</h1>' > /usr/share/nginx/html/index.html

exit

修改了容器的文件,也就是修改了容器的存储层



C.查看容器的具体改动

docker diff 容器名称或ID



D.把改动的容器保存下来形成一个镜像。单纯运行一个容器做的任何的文件修改,都会被记录在容器的存储层中.



E. "docker commit"命令可以将容器的存储层保存下来形成一个新的镜像,就是说在原有镜像的基础上再叠加上容器存储层的改变,这样就可以构成一个新的镜像,以后就可以用新的镜像来生成容器(类似于虚拟机中快照的概念).

docker commit --author "Aaron" --message "update nginx index.html" webservice nginx:v2

--author: 做这个

--message: 做了哪些改动

webservice是容器名称,也可以是容器ID

nginx是仓库名

v2是tag



F.查看镜像是否创建成功

docker images



G.查看镜像的历史记录

docker history nginx:v2



H:运行测试定制的镜像

docker run --name webservice2 -d -p 8082:80 nginx:v2

--name表示给运行的容器指定一个名称

docker ps

浏览器访问 “localhost:8082”



注意： "docker commit"主要是用来学习使用的,不过也有一些特殊的应用场合,比如容器被入侵了，需要保存容器运行的一个现场，可以用 "docker commit"保存下来,方便日后的排查.但是不要使用"docker commit"来定制镜像,因为定制镜像应该使用"Dockerfile"来完成





































