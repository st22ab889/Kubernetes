1.Docker Compose介绍



Docker Compose 是 Docker 官⽅编排（Orchestration）项⽬之⼀，负责快速的部署分布式应⽤。其代 码⽬前在https://github.com/docker/compose上开源。Compose 定位是 「定义和运⾏多个 Docker 容 器的应⽤（Defining and running multi-container Docker applications）」，其前身是开源项⽬ Fig 。

 前⾯我们已经学习过使⽤⼀个 Dockerfile 模板⽂件，可以很⽅便的定义⼀个单独的应⽤容器。然⽽， 在⽇常⼯作中，经常会碰到需要多个容器相互配合来完成某项任务的情况。例如要实现⼀个 Web 项 ⽬，除了 Web 服务容器本身，往往还需要再加上后端的数据库服务容器或者缓存服务容器，甚⾄还包 括负载均衡容器等。Compose 恰好满⾜了这样的需求。它允许⽤户通过⼀个单独的 dockercompose.yml 模板⽂件（YAML 格式）来定义⼀组相关联的应⽤容器为⼀个项⽬（project）。 Compose 中有两个重要的概念：

- 服务 (service)：⼀个应⽤的容器，实际上可以包括若⼲运⾏相同镜像的容器实例。 

- 项⽬ (project)：由⼀组关联的应⽤容器组成的⼀个完整业务单元，在 docker-compose.yml ⽂件中 定义。 

Compose 的默认管理对象是项⽬，通过⼦命令对项⽬中的⼀组容器进⾏便捷地⽣命周期管理。 Compose 项⽬由 Python 编写，实现上调⽤了 Docker 服务提供的 API 来对容器进⾏管理。所以只要 所操作的平台⽀持 Docker API，就可以在其上利⽤ Compose 来进⾏编排管理。



2.Docker Compose安装与卸载

Compose ⽀持 Linux、macOS、Windows 10 三⼤平台。Compose 可以通过 Python 的包管理⼯ 具 pip 进⾏安装，也可以直接下载编译好的⼆进制⽂件使⽤，甚⾄能够直接在 Docker 容器中运⾏。 前两种⽅式是传统⽅式，适合本地环境下安装使⽤；最后⼀种⽅式则不破坏系统环境，更适合云计算 场景。Docker for Mac 、Docker for Windows ⾃带 docker-compose ⼆进制⽂件，安装 Docker 之后 可以直接使⽤.



```javascript
#通过 Python 的包管理工具pip进行安装
pip install docker-compose
#卸载
pip uninstall docker-compose
```



```javascript
#如果系统没有安装pip或对pip不熟悉就可以直接安装二进制包 
打开"https://github.com/docker/compose",点击release下载与系统对应的安装包即可.
#卸载
卸载二进制文件
```



```javascript
#Docker for Mac 、Docker for Windows 自带 docker-compose 二进制文件,安装Docker之后可以直接使用.
#windows点击右下角docker小图标点击"About Docker Desktop"就可以看到目前使用的compose版本号.
#也可以使用如下命令查看compose版本号.
docker-compose --version
```



3.使用Docker Compose

示例:⽤ Python 来建⽴⼀个能够记录⻚⾯访问次数的 web ⽹站.



- "docker-compose"命令运行的前提是所在终端进入到有"docker-compose.yml"这个文件的目录下,或者运行命令时指定"docker-compose.yml"文件的所在路径.

- "docker-compose"默认是对project进行操作.



[ComposeDemo.zip](attachments/CA651EF197C74EE69E391DFBED871210ComposeDemo.zip)

- app.py

```javascript
import time
import redis
from flask import Flask

app = Flask(__name__)
cache = redis.Redis(host = 'redis', port = 6379)


def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)
        
@ app.route('/')
def hello():
    count = get_hit_count()
    return 'Hello World! I have been seen {} times.\n'.format(count)
    
if __name__ == "__main__":
    app.run(host = "0.0.0.0", debug = True)

```



- Dockerfile

```javascript
#用一个基础镜像, "python:3.6-alpine"是一个比较简单、轻量级和小的镜像
FROM python:3.6-alpine
#把当前文件夹的文件添加到容器的code目录下."."表示当前目录.
ADD . /code
#指定工作目录,直接定位到容器的code目录下,接下来的所有操作都是在这个目录下进行操作.
WORKDIR /code
#安装依赖. 运行python的pip包管理工具下载redis和flask.
RUN pip install redis flask
#正在在终端直接运行"python app.py",但是在dockerfile中需要用CMD这个命令
CMD ["python", "app.py"]
```



- docker-compose.yml

```javascript
# 版本2和3有很大的区别,很多地方不兼容. 
# "docker-compose.yml"对格式要求严格,行要有正确的缩进.
# yml和yaml都是yaml文件的格式,但是"docker-compose.yml"默认使用"yml"格式.
version: '3'
#定义服务，web服务和redis
services:
    web:
        #"."表示构把当前目录作为建上下文, 把上下文传到dockerd中去.
        #dockerd(Docker Damon:⽤来监听"Docker API"的请求和管理Docker对象，⽐如镜像、容器、⽹络和Volume)
        build: .
        ports:
        - "5000:5000"
        #挂载数据卷
        volumes:
        #把当前目录挂载到容器的code目录
        - .:/code
    redis:
        image: "redis:alpine"
```





运行docker-compose.yml文件

```javascript
#查看docker-compose命令的帮助文档
docker-compose help
#查看"docker-compose up"命令的帮助文档
docker-compose up help

#在终端中进入到"docker-compose.yml"文件所在的目录下并运行以下命令
docker-compose up

#验证
浏览器打开"127.0.0.1:5000"

#运行下面命令后,有composedemo_web_1和composedemo_redis_1两个容器(服务),它们被compose管理.
#这两个服务就叫它project
docker ps

=========================命令扩展=========================

#重新构建项目中的容器
docker-compose build   或   docker-compose up --build

#删除构建过程中的临时容器
docker-compose build --force-rm
#构建镜像过程当中不使用cache,就是说加上构建过程,不使用cache
docker-compose build --no-cache
#始终都会尝试拉去更新版本的镜像
docker-compose build --pull

#如果"docker-compose.yml"没有在当前目录下,可以使用"-f"参数指定路径或文件名
docker-compose -f docker-compose.yml up

#加"-d"参数让服务在后台运行
docker-compose -f docker-compose.yml up -d

#查看compose文件包含的惊醒
docker-compose images

#查看容器的日志,格式"docker-compose logs -f 服务名称"
docker-compose logs -f web

#查看compose管理的项目中的容器状态
docker-compose ps
#查看compose管理的项目中的容器ID
docker-compose ps -q

#使用这个命令查看服务容器运行的进程
docker-compose top

#进入到"composedemo_web_1"这个容器
docker exec -it composedemo_web_1 /bin/sh

#使用"docker-compose exec"进入到"composedemo_web_1"这个容器
#默认exec就分配了一个TTY的伪终端,所以不需要加"-it"
docker-compose exec web /bin/sh

#验证"docker-compose.yml"这个文件的格式是否正确
docker-compose config

#停止刚刚启动的所有容器,并且会移除网络
docker-compose down

#docker的镜像很多很多，这其中难免就会存在一些问题，比如镜像中的某个历史组件存在已知安全漏洞
#在部署docker 容器之前应该对镜像image做一些安全性扫描
docker scan 镜像名称

#把服务扩容到指定个数的实例,格式"docker-compose up --scale SERVICE=数量"
docker-compose up --scale SERVICE=2
```







