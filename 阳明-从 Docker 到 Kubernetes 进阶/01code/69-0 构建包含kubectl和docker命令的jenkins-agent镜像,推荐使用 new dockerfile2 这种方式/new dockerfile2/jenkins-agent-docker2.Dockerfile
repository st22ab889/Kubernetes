FROM jenkins/inbound-agent:4.3-4

ARG user=jenkins

# 构建镜像时运行的shell命令,也就是说设置运行RUN、CMD、ENTRYPOINT的用户名
USER root

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && mkdir -p /root/.kube \
    && apt-get update -q \
    # DockerInDocker的轻量级实现方法,不安装Docker程序,只需要安装Docker执行需要的库文件libltdl7
    # 这种方式需要挂载宿主机的两个目录,分别是"/var/run/docker.sock"、"/usr/bin/docker"
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq libltdl7

# 如果要让容器启动后不用root直接操作容器,可以在这里切换用户,这里表示切换为jenkins这个用户,因为上面定义了"ARG user=jenkins"
#USER ${user}

# 这里为了方便就直接用root,原则上说容器启动后不应该用root直接操作容器,因为上面已经定义了"USER root",这里可以不用重复定义
#USER root