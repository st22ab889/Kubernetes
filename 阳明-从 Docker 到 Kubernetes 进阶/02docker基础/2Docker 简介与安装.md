1.docker安装



2.安装后代开docker命令窗口简单测试

docker version 

docker info



docker images   //查看当前docker有哪些镜像

docker image ls



docker run hello-world //运行一个"hello-world"的容器,现在本地找" hello-world"这个镜像，如果没有就去远程找,找到后就会拉取.



docker container ls //查看运行中的容器

docker container ls --all //查看所有的容器(包括退出的)，不包括删除的容器



docker ps  //查看运行中的容器

docker  ps -a//查看所有的容器(包括退出的)，不包括删除的容器.

docker ps -qa   //列出所有容器的ID(之显示出ID)

docker rm -f $(docker ps -qa)  // 删除所有容器,这个命令再				  windown下的cmd窗口中不起作用,可能不识别 $符号







容器三种状态:运行，退出，删除



镜像是容器的基础，每次执行"docker run"都会指定哪个镜像作为容器运行的基础.



镜像是分层存储的,每一层实在前一层的基础上进行加工的，容器同样也是多层存储，是在镜像作为基础层之上加了一层作为容器运行的存储层.



https://docs.microsoft.com/zh-cn/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package





