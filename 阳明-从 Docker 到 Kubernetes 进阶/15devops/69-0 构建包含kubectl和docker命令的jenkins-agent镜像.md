

1. 在构建agent镜像的过程中可能出现拉取"jenkins/inbound-agent:4.3-4"镜像失败,解决方法如下:

```javascript
# 以下命令在node节点执行
docker pull hub-mirror.c.163.com/jenkins/inbound-agent:4.3-4
docker tag hub-mirror.c.163.com/jenkins/inbound-agent:4.3-4 jenkins/inbound-agent:4.3-4
```

参考文档:

Docker必备六大国内镜像

https://segmentfault.com/a/1190000023117518



2. 构建 agent 镜像都是在node节点操作,因为jenkins的job任务都是在node节点创建Pod执行,下面是构建 agent 镜像的两种方式:



方式1：不推荐使用这种方式

[jenkins-agent-docker.Dockerfile](attachments/08C40C2D5CED426CB4D91839417DC468jenkins-agent-docker.Dockerfile)

[kubectl](attachments/893ADEE84D55459F900E0F8D22D8B6C1kubectl)

```javascript
# jenkins-agent-docker.Dockerfile

FROM jenkins/inbound-agent:4.3-4

# ARG表示设置编译镜像时加入的参数
ARG user=jenkins

USER root

# 容器中安装kubectl的方式一,需要把kubectl下载下来
COPY kubectl /usr/local/bin/kubectl
RUN mkdir -p /root/.kube \
    # 不加这一行会出现"kubectl: Permission denied"
    && chmod +x /usr/local/bin/kubectl \
    && apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --assume-yes apt-utils apt-transport-https ca-certificates curl gnupg lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    # 在容器中安装docker,只需要安装docker-ce就可以了 
    && DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce \
    #&& DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce docker-ce-cli containerd.io \
    && apt-get install -y subversion \
    # 这里的组名可以和宿主机不一样,但是组ID一定要和宿主机一样,否则会出现"dial unix /var/run/docker.sock: connect: permission denied"
    # 注意:在容器中安装docker-ce也会新建一个名为docker的组,但是这个组的id和宿主机docker组的id不一定一样,不一样也会导致"permission denied",因为组名冲突会导致添加组失败,所以组名要重命名
    && groupadd -g 994 host-docker \
    # 把jenkins这个用户加入到组id为994这个docker这个组,这样jenkins就有执行"docker.sock"这个文件的权限
    && usermod -a -G host-docker jenkins

# 容器中安装kubectl的方式二
#RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
#    && chmod +x ./kubectl \
#    && mv ./kubectl /usr/local/bin/kubectl \
#    && mkdir -p /root/.kube


# 容器启动后用jenkins这个用户执行操作，因为上面定义了"ARG user=jenkins"
# USER ${user}

# 容器启动后使用root执行操作
USER root

# 设置指令的工作目录,这个工作目录不能随便设置,要设置就和"jenkins/inbound-agent:4.3-4"这个镜像一样,因为是在这个镜像基础纸上构建的.
# 如果设置的和"jenkins/inbound-agent:4.3-4"不一样,会出现"Waiting for agent to connect",因为不能正常运行jenkins-agent(也就是jenkins-slave)这个程序
# WORKDIR /home/jenkins

# 设置容器的入口程序,因为"jenkins/inbound-agent:4.3-4"这个镜像已经设置过了,所以这里不用设置了
# ENTRYPOINT ["jenkins-agent"]

# 出现"dial unix /var/run/docker.sock: connect: permission denied"的三种解决方式:
#   第一种:在本机新建一个组,组id和宿主机一样,名称不要和容器中已存在的组一样，否则会添加失败
#       groupadd -g ${宿主机docker组的ID} ${名称可以自定义}
#       usermod -a -G ${名称和上面保持一致} jenkins
#   第二种:容器中使用root执行操作, dockerfile中定义:
#       USER root
#   第三种:在jenkins的"configureClouds"的"Pod Template details..."中配置"Run As User ID"或"Run As Group ID"
#       Run As User ID: 0   # UserID=0代表的是root帐号Id,表示用root账号执行操作
#       Run As Group ID: 1000  # GroupID代表是一个组的ID,表示把执行容器的这个用户添加到组id为1000这个组
                               # 比如是jenkins这个普通用户操作容器,现在要执行一个属于docker组的文件,就要把jenkins这个用户加入到docker组,否则就会提示没有权限 

```





方式2：推荐使用这种方式，轻量级实现

[jenkins-agent-docker2.Dockerfile](attachments/7AD3F7DA20F848EF846ADA8F7C6CFA2Ajenkins-agent-docker2.Dockerfile)

```javascript
# jenkins-agent-docker2.Dockerfile

FROM jenkins/inbound-agent:4.3-4

ARG user=jenkins

# 构建镜像时运行的shell命令,也就是说设置运行RUN、CMD、ENTRYPOINT的用户名
USER root

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && mkdir -p /root/.kube \
    && apt-get update -q \
    # DockerInDocker的轻量级实现方法,不安装Docker程序,只需要安装Docker执行需要的库文件libltdl7
    # 这种方式需要挂载宿主机的两个目录,分别是"/var/run/docker.sock"、"/usr/bin/docker"
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq libltdl7

# 如果要让容器启动后不用root直接操作容器,可以在这里切换用户,这里表示切换为jenkins这个用户,因为上面定义了"ARG user=jenkins"
#USER ${user}

# 这里为了方便就直接用root,原则上说容器启动后不应该用root直接操作容器,因为上面已经定义了"USER root",这里可以不用重复定义
#USER root
```





教程中的方式：里面的写法可以参考一下

[jenkins-slave.Dockerfile](attachments/E3052F4874F34864AAFC6EE1BD3DBEFCjenkins-slave.Dockerfile)

```javascript
# jenkins-slave.Dockerfile

FROM debian:stretch

ENV JAVA_HOME=/usr/local/newhope/java1.8 \
    PATH=/usr/local/newhope/java1.8/bin:$PATH \
    TIMEZONE=Asia/Shanghai \
    LANG=zh_CN.UTF-8

RUN echo "${TIMEZONE}" > /etc/timezone \
    && echo "$LANG UTF-8" > /etc/locale.gen \
    && apt-get update -q \
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && mkdir -p /usr/local/newhope/java1.8 \
    && mkdir -p /home/jenkins/.jenkins \
    && mkdir -p /home/jenkins/agent \
    && mkdir -p /usr/share/jenkins \
    && mkdir -p /root/.kube

COPY java1.8 /usr/local/newhope/java1.8
COPY kubectl /usr/local/bin/kubectl
COPY jenkins-slave /usr/local/bin/jenkins-slave
COPY slave.jar /usr/share/jenkins

# java/字符集/DinD/svn/jnlp
RUN  mkdir /usr/java/jdk1.8.0_121/bin -p \
     && ln -s /usr/local/newhope/java1.8 /usr/java/jdk1.8.0_121 \
     && DEBIAN_FRONTEND=noninteractive apt-get install -yq curl apt-utils dialog locales  apt-transport-https build-essential bzip2 ca-certificates  sudo jq unzip zip gnupg2 software-properties-common \
     && update-locale LANG=$LANG \
     && locale-gen $LANG \
     && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
     &&curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg |apt-key add - \
     && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" \
     && apt-get update -y \
     && apt-get install -y docker-ce=17.09.1~ce-0~debian \
     && sudo apt-get install -y subversion \
     && groupadd -g 10000 jenkins \
     && useradd -c "Jenkins user" -d $HOME -u 10000 -g 10000 -m jenkins \
     && usermod -a -G docker jenkins \
     && sed -i '/^root/a\jenkins    ALL=(ALL:ALL) NOPASSWD:ALL' /etc/sudoers

USER root

WORKDIR /home/jenkins

ENTRYPOINT ["jenkins-slave"]

```





3. 遇到的问题以及解决方式:

问题1: 

运行jenkins的agent节点,出现"Waiting for agent to connect"

解决方式：  

这里的 WORKDIR 要和jenkins/inbound-agent:4.3-4 这个镜像中的 WORKDIR 一样。

分析原因:

https://hub.docker.com/layers/jenkins/inbound-agent/4.3-4/images/sha256-62f48a12d41e02e557ee9f7e4ffa82c77925b817ec791c8da5f431213abc2828?context=explore , 从这个衔接可以看出镜像的WORKDIR是 /home/jenkins，所以jenkins的云节点上的WORKDIR 也应该是" /home/jenkins",或者不设置云节点上的WORKDIR ,因为镜像中已经指定了WORKDIR是 /home/jenkins



问题2：

jenkins的agent节点运行kubectl 命令出现如下错误:

```javascript
+ kubectl get pods -n kube-ops
/tmp/jenkins8815295408102648686.sh: 6: /tmp/jenkins8815295408102648686.sh: kubectl: Permission denied
```

解决方式： 

dockerfile中加 "chmod +x /usr/local/bin/kubectl"



问题3:

jenkins的agent节点运行docker命令出现如下错误:

```javascript
dial unix /var/run/docker.sock: connect: permission denied
```

解决方式:

```javascript
# 出现"dial unix /var/run/docker.sock: connect: permission denied"的三种解决方式:
#   第一种:在本机新建一个组,组id和宿主机一样,名称不要和容器中已存在的组一样，否则会添加失败
#       groupadd -g ${宿主机docker组的ID} ${名称可以自定义}
#       usermod -a -G ${名称和上面保持一致} jenkins
#   第二种:容器中使用root执行操作, dockerfile中定义:
#       USER root
#   第三种:在jenkins的"configureClouds"的"Pod Template details..."中配置"Run As User ID"或"Run As Group ID"
#       Run As User ID: 0   # UserID=0代表的是root帐号Id,表示用root账号执行操作
#       Run As Group ID: 1000  # GroupID代表是一个组的ID,表示把执行容器的这个用户添加到组id为1000这个组
                               # 比如是jenkins这个普通用户操作容器,现在要执行一个属于docker组的文件,就要把jenkins这个用户加入到docker组,否则就会提示没有权限 
```





注1: 重要的参考资料:



Jenkins节点配置-K8S云节点

https://www.cnblogs.com/zhaobowen/p/13731624.html



docker in docker 的一种轻量级实现方法——docker 嵌套技术

https://blog.csdn.net/shida_csdn/article/details/79812817



如何通过Docker镜像在Kubernetes容器中安装Kubectl

https://www.itbaoku.cn/post/1535444/do



Jenkins agent Docker 镜像重新命名了，你知道吗？

https://baijiahao.baidu.com/s?id=1667061189191985964&wfr=spider&for=pc



Docker中none:none镜像

https://blog.csdn.net/chengyinwu/article/details/109257281



Docker镜像列表中的none:none是什么

https://blog.csdn.net/boling_cavalry/article/details/90727359



k8s进入容器

https://blog.csdn.net/king__12/article/details/115247033



jenkinsci/docker-inbound-agent Public

https://github.com/jenkinsci/docker-inbound-agent



Dockerfile常用指令说明

https://www.cnblogs.com/hbxZJ/p/10250060.html

https://www.cnblogs.com/ringwang/p/11967632.html



制作最小linux镜像,Docker镜像的无中生有：使用scratch制作自定义最小镜像

https://blog.csdn.net/weixin_42469649/article/details/116895532



k8s进入到容器:

kubectl exec -it $pod [-c $container] [-n $namespace] -- /bin/bash

kubectl exec -it $pod [-c $container] [-n $namespace] -- bash

kubectl exec -it $pod [-c $container] [-n $namespace] -- /bin/sh  #不推荐使用

kubectl exec -it jnlp-9gxt9 -n kube-ops -- /bin/bash



docker拉取镜像:

docker pull hub-mirror.c.163.com/jenkins/inbound-agent:4.3-4

docker pull jenkins/inbound-agent



docker构建镜像:

docker build -t inbound-agent-docker:4.3-4 -f jenkins-agent-docker2.Dockerfile .





注2: linux命令相关文档



Linux newgrp命令

https://www.runoob.com/linux/linux-comm-newgrp.html



Linux groupadd 命令

https://www.runoob.com/linux/linux-comm-groupadd.html



newgrp命令

http://lnmp.ailinux.net/newgrp



sudo配置文件/etc/sudoers详解及实战用法

https://blog.csdn.net/heli200482128/article/details/77833881



Linux如何查看所有的用户和组信息

https://www.cnblogs.com/selectztl/p/9523151.html



Linux命令ls -l详细信息说明

https://blog.csdn.net/weixin_44903147/article/details/102480711



Centos7安装apt-get

https://www.cnblogs.com/-wenli/p/13552402.html



yum install -y 是什么意思_yum 命令讲解

https://blog.csdn.net/weixin_39872044/article/details/111136727



sudo配置文件/etc/sudoers详解及实战用法

https://blog.csdn.net/heli200482128/article/details/77833881



cat /etc/passwd     	#可以查看所有用户的列表

w                   	 	#可以查看当前活跃的用户列表

cat /etc/group      	#查看用户组

groups   			#查看当前登录用户的组内成员

groups   			# 查看当前用户所在的组，以及组内成员

whoami   			#查看当前登录用户名



```javascript
# 当用户执行sudo时，系统会主动寻找/etc/sudoers文件，判断该用户是否有执行sudo的权限
# 该文件允许特定用户像root用户一样使用各种各样的命令，而不需要root用户的密码 
cat /etc/sudoers
```



```javascript
# 循环运行脚本,不让容器挂掉
while true; do echo hello world; sleep 20; done
```





注3: 安装docker时,docker会默认创建一个组id为994的docker组.

```javascript
// master节点执行
[root@centos7 aaron]# cat /etc/group  | grep docker
docker:x:994:

// node节点执行
[root@centos7 ~]# cat /etc/group  | grep docker
docker:x:994:
```





注4: jenkins镜像中有一个id为1000的jenkins用户,以及一个组id为1000的jenkins组.

```javascript
// 进入 jenkins-master-pod 中执行
root@jenkins-85db8588bd-tjsn5:/# cat /etc/group | grep jenkins
jenkins:x:1000:
root@jenkins-85db8588bd-tjsn5:/# cat /etc/passwd | grep jenkins
jenkins:x:1000:1000::/var/jenkins_home:/bin/bash

// 进入 jenkins-agent-pod 中执行
root@jenkins-85db8588bd-tjsn5:/# cat /etc/group  | grep jenkins
jenkins:x:1000:
root@jenkins-85db8588bd-tjsn5:/# cat /etc/passwd | grep jenkins
jenkins:x:1000:1000::/var/jenkins_home:/bin/bash
```



jenkins-master:

https://hub.docker.com/layers/jenkins/jenkins/lts/images/sha256-5f0af64a0524f82fbde03795a2223ddc251ff7329855dc810f80056fde50d390?context=explore，从"jenkins/jenkins:lts"这个镜像的dockerfile中可以看到这里创建了一个名为 jenkins 的用户, 用户Id被定义为  1000，jenkins 这个组id定义为  1000



jenkins-agent:

https://hub.docker.com/layers/jenkins/inbound-agent/4.3-4/images/sha256-62f48a12d41e02e557ee9f7e4ffa82c77925b817ec791c8da5f431213abc2828?context=explore，从"jenkins/inbound-agent:4.3-4"这个镜像的dockerfile中可以看到这里创建了一个名为 jenkins 的用户, 用户Id被定义为  1000，jenkins 这个组id定义为  1000