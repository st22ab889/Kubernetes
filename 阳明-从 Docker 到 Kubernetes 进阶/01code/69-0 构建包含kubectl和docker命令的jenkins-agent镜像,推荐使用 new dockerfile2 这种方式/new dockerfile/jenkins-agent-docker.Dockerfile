FROM jenkins/inbound-agent:4.3-4

# ARG表示设置编译镜像时加入的参数
ARG user=jenkins

USER root

# 容器中安装kubectl的方式一,需要把kubectl下载下来
COPY kubectl /usr/local/bin/kubectl
RUN mkdir -p /root/.kube \
    # 不加这一行会出现"kubectl: Permission denied"
    && chmod +x /usr/local/bin/kubectl \
    && apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --assume-yes apt-utils apt-transport-https ca-certificates curl gnupg lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    # 在容器中安装docker,只需要安装docker-ce就可以了 
    && DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce \
    #&& DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce docker-ce-cli containerd.io \
    && apt-get install -y subversion \
    # 这里的组名可以和宿主机不一样,但是组ID一定要和宿主机一样,否则会出现"dial unix /var/run/docker.sock: connect: permission denied"
    # 注意:在容器中安装docker-ce也会新建一个名为docker的组,但是这个组的id和宿主机docker组的id不一定一样,不一样也会导致"permission denied",因为组名冲突会导致添加组失败,所以组名要重命名
    && groupadd -g 994 host-docker \
    # 把jenkins这个用户加入到组id为994这个docker这个组,这样jenkins就有执行"docker.sock"这个文件的权限
    && usermod -a -G host-docker jenkins

# 容器中安装kubectl的方式二
#RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
#    && chmod +x ./kubectl \
#    && mv ./kubectl /usr/local/bin/kubectl \
#    && mkdir -p /root/.kube


# 容器启动后用jenkins这个用户执行操作，因为上面定义了"ARG user=jenkins"
# USER ${user}

# 容器启动后使用root执行操作
USER root

# 设置指令的工作目录,这个工作目录不能随便设置,要设置就和"jenkins/inbound-agent:4.3-4"这个镜像一样,因为是在这个镜像基础纸上构建的.
# 如果设置的和"jenkins/inbound-agent:4.3-4"不一样,会出现"Waiting for agent to connect",因为不能正常运行jenkins-agent(也就是jenkins-slave)这个程序
# WORKDIR /home/jenkins

# 设置容器的入口程序,因为"jenkins/inbound-agent:4.3-4"这个镜像已经设置过了,所以这里不用设置了
# ENTRYPOINT ["jenkins-agent"]

# 出现"dial unix /var/run/docker.sock: connect: permission denied"的三种解决方式:
#   第一种:在本机新建一个组,组id和宿主机一样,名称不要和容器中已存在的组一样，否则会添加失败
#       groupadd -g ${宿主机docker组的ID} ${名称可以自定义}
#       usermod -a -G ${名称和上面保持一致} jenkins
#   第二种:容器中使用root执行操作, dockerfile中定义:
#       USER root
#   第三种:在jenkins的"configureClouds"的"Pod Template details..."中配置"Run As User ID"或"Run As Group ID"
#       Run As User ID: 0   # UserID=0代表的是root帐号Id,表示用root账号执行操作
#       Run As Group ID: 1000  # GroupID代表是一个组的ID,表示把执行容器的这个用户添加到组id为1000这个组
                               # 比如是jenkins这个普通用户操作容器,现在要执行一个属于docker组的文件,就要把jenkins这个用户加入到docker组,否则就会提示没有权限 
