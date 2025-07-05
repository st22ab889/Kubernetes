1.介绍

Docker 的⼝号是 Build,Ship,and Run Any App,Anywhere，在我们使⽤ Docker 的⼤部分时候，的确 能感觉到其优越性，但是往往在我们 Build ⼀个应⽤的时候，是将我们的源代码也构建进去的，这对于 类似于 golang 这样的编译型语⾔肯定是不⾏的，因为实际运⾏的时候我只需要把最终构建的⼆进制包 给你就⾏，把源码也⼀起打包在镜像中，需要承担很多⻛险，即使是脚本语⾔(比如python、js等)，在构建的时候也可能 需要使⽤到⼀些上线的⼯具，这样⽆疑也增⼤了我们的镜像体积。



示例, ⽐如我们现在有⼀个最简单的 golang 服务，需要构建⼀个最⼩的 Docker 镜像，源码如下：

```javascript
package main
import (
	"github.com/gin-gonic/gin"
	"net/http"
)
func main() {
	router := gin.Default()
	router.GET("/ping", func(c *gin.Context) {
		c.String(http.StatusOK, "PONG")
	})
	router.Run(":8080")
}
```



最终的⽬的都是将最终的可执⾏⽂件放到⼀个最⼩的镜像(⽐如 alpine，scratch )中去执⾏.，怎样得到最终 的编译好的⽂件呢？



2.解决方案



方案一 ：

基于 Docker 的指导思想，我们需要在⼀个标准的容器中编译，⽐如在⼀个 Ubuntu 镜像中先安装编译的环境，然后编译，最后也在该容器中执⾏即可.

这种方式的缺点是镜像会非常大.



方案二：

把编译后的⽂件放置到 alpine 镜像中执⾏呢？我们就得通过方案一的 Ubuntu 镜像将 编译完成的⽂件通过 volume 挂载到我们的主机上，然后我们再将这个⽂件挂载到 alpine 镜像中去。

这种解决⽅案理论上肯定是可⾏的，但是这样的话在构建镜像的时候我们就得定义两步了，第⼀步是 先⽤⼀个通⽤的镜像编译镜像，第⼆步是将编译后的⽂件复制到 alpine 镜像中执⾏，⽽且通过镜像编译后的⽂件在 alpine 镜像中不⼀定能执⾏。



定义编译阶段的 Dockerfile ：(保存为Dockerfile.build)

```javascript
FROM golang 
WORKDIR /go/src/app 
ADD . /go/src/app 
RUN go get -u -v github.com/kardianos/govendor 
RUN govendor sync 
RUN GOOS=linux GOARCH=386 go build -v -o /go/src/app/app-server
```





定义 alpine 镜像：(保存为Dockerfile.old)

```javascript
FROM alpine:latest 
RUN apk add -U tzdata 
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 
WORKDIR /root/ 
COPY app-server . 
CMD ["./app-server"]
```





根据我们的执⾏步骤，我们还可以简单定义成⼀个脚本：(保存为build.sh)

```javascript
#!/bin/sh
echo Building cnych/docker-multi-stage-demo:build

docker build -t cnych/docker-multi-stage-demo:build . -f Dockerfile.build

#创建容器不运行, 所以用"docker ps"看不到容器信息
docker create --name extract cnych/docker-multi-stage-demo:build
#从创建的容器里面拷贝出编译好的文件到宿主机,所以创建容器不运行同样可以拷贝出文件
docker cp extract:/go/src/app/app-server ./app-server
#删除创建的容器
docker rm -f extract

echo Building cnych/docker-multi-stage-demo:old

#"--no-cache"表示不要使用刚刚构建过的缓存
docker build --no-cache -t cnych/docker-multi-stage-demo:old . -f Dockerfile.old
rm ./app-server

```



当我们执⾏完上⾯的构建脚本后，就实现了我们的⽬标.



方案三：

[docker-multi-stage-demo-master.zip](attachments/0EC286D800BF4F20A214EE0C41F836C3docker-multi-stage-demo-master.zip)

多阶段构建,Docker 17.05版本以后，官⽅就提供了⼀ 个新的特性： Multi-stage builds （多阶段构建）。 使⽤多阶段构建，你可以在⼀个 Dockerfile 中使⽤多个 FROM 语句。每个 FROM 指令都可以使⽤不同的基础镜像，并表示开始⼀个新的构建阶 段。你可以很⽅便的将⼀个阶段的⽂件复制到另外⼀个阶段，在最终的镜像中保留下你需要的内容即可.



调整方案二的 Dockerfile 来使⽤多阶段构建：(保存为Dockerfile)

```javascript
FROM golang AS build-env
ADD . /go/src/app
WORKDIR /go/src/app
RUN go get -u -v github.com/kardianos/govendor
RUN govendor sync
RUN GOOS=linux GOARCH=386 go build -v -o /go/src/app/app-server

FROM alpine
RUN apk add -U tzdata
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY --from=build-env /go/src/app/app-server /usr/local/bin/app-server
#"EXPOSE"命令表示暴露端口
EXPOSE 8080
CMD [ "app-server" ]
```



现在只需要⼀个 Dockerfile ⽂件即可，也不需要拆分构建脚本了，只需要执⾏ build 命令即可：

```javascript
docker build -t cnych/docker-multi-stage-demo:latest .
```



运⾏容器测试：

```javascript
docker run --rm -p 8080:8080 cnych/docker-multi-stage-demo:latest
#运⾏成功后在浏览器中打开"http://127.0.0.1:8080/ping",可以看到PONG返回.
#这样就把两个镜像的⽂件最终合并到⼀个镜像⾥⾯了.
#代码可以前往github查看：https://github.com/cnych/docker-multi-stage-demo
```





默认情况下，构建阶段是没有命令的，我们可以通过它们的索引来引⽤它们，第⼀个 FROM 指令 从 0 开始，我们也可以⽤ AS 指令为阶段命令，⽐如我们这⾥的将第⼀阶段命名为 build-env ，然后 在其他阶段需要引⽤的时候使⽤ --from=build-env 参数即可。







3. 附:scratch是一个虚拟的镜像,占用的空间非常小.该镜像是一个空的镜像，可以用于构建busybox等超小镜像，可以说是真正的从零开始构建属于自己的镜像.



关于docker的scratch镜像与helloworld：

https://www.cnblogs.com/uscWIFI/p/11917662.html





