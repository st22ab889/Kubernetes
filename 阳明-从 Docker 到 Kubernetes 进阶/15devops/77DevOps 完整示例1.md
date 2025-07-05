1. 介绍

这节使⽤ Jenkins + Gitlab + Harbor + Helm + Kubernetes 来实现⼀个完整的 CI/CD 流⽔线作业。

前⾯已经实现 Jenkins Pipeline 与 Kubernetes 的完美结合，利⽤ Kubernetes 来动态运⾏ Jenkins 的 Slave 节点，可以很好的解决传统 Jenkins Slave 浪费⼤量资源的缺点。之前的示例中是将项⽬放置在 Github 仓库，将 Docker 镜像推送到了 Docker Hub，这节使⽤ Jenkins、Gitlab、Harbor、 Helm、k8s 来实现⼀个完整的持续集成和持续部署的流⽔线作业。

由于本地集群资源不足：所以使用 Jenkins + Gitee + Harbor + Helm + k8s



流程

示例的流程图如下：

![](images/E447B2047FC3417DB765783F097EF741clipboard.png)

- 开发人员提交代码到 Gitlab 代码仓库

- 通过 Gitlab 配置的 Jenkins Webhook 触发 Pipeline 自动构建

- Jenkins 触发构建构建任务，根据 Pipeline 脚本定义分步骤构建

- 先进行代码静态分析，单元测试

- 然后进行 Maven 构建（Java 项目）

- 根据构建结果构建 Docker 镜像

- 推送 Docker 镜像到 Harbor 仓库

- 触发更新服务阶段，使用 Helm 安装/更新 Release

- 查看服务是否更新成功



2 项目

本次示例项目是一个完整的基于 Spring Boot、Spring Security、JWT、React 和 Ant Design 构建的一个开源的投票应用，项目地址如下：

https://gitee.com/st22ab889/spring-security-react-ant-design-polls-app.git



项目运行效果图：

![](images/8C531F311250432A939BCD42F8763C38clipboard.png)

将会在该项⽬的基础上添加部分代码，并实践 CI/CD 流程。



2.1 服务端

首先需要更改的是服务端配置，需要将数据库链接的配置更改成环境变量的形式，这样才能定制，将下面的数据库配置部分修改成如下形式：

```javascript
# 修改服务端文件 src/main/resources/application.properties
spring.datasource.url= jdbc:mysql://${DB_HOST:localhost}:${DB_PORT:3306}/${DB_NAME:polling_app}?useSSL=false&serverTimezone=UTC&useLegacyDatetimeCode=false
spring.datasource.username= ${DB_USER:root}
spring.datasource.password= ${DB_PASSWORD:root}
```

当环境变量中有上面的数据配置的时候，就会优先使用环境变量中的值，没有的时候就会用默认的值进行数据库配置。



由于要将项目部署到 Kubernetes 集群中去，所以需要将服务端进行容器化，所以在项目根目录下面添加一个Dockerfile文件进行镜像构建：

```javascript
# DockerfileForK8s
FROM openjdk:8-jdk-alpine

MAINTAINER aaron <kkk_en@163.com>

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TZ=Asia/Shanghai

RUN mkdir /app

WORKDIR /app

COPY target/polls-0.0.1-SNAPSHOT.jar /app/polls.jar

EXPOSE 8080

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar","/app/polls.jar"]
```

由于服务端代码是基于 Spring Boot 构建，所以这里使用一个 openjdk 的基础镜像，将打包过后的 jar 包放入镜像之中，然后用过 java -jar 命令直接启动即可，这里就存在一个问题，这里是在 Jenkins 的 Pipeline 中去进行构建镜像，这时候项目中并没有打包好的 jar 包文件，那么应该如何获取打包好的 jar 包文件？这里可以使用两种方法：



第一种就是如果用于镜像打包的 Docker 版本大于 17.06 ，那么强烈推荐使用 Docker 的多阶段构建功能来完成镜像的打包过程，只需将上面的Dockerfile 文件稍微更改下即可，将使用 maven 进行构建的工作放到同一个文件中：

```javascript
# Dockerfile
FROM maven:3.6-alpine as BUILD

COPY src /usr/app/src
COPY pom.xml /usr/app

RUN mvn -f /usr/app/pom.xml clean package -Dmaven.test.skip=true

FROM openjdk:8-jdk-alpine

MAINTAINER aaron <kkk_en@163.com>

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TZ=Asia/Shanghai

RUN mkdir /app

WORKDIR /app

COPY --from=BUILD /usr/app/target/polls-0.0.1-SNAPSHOT.jar /app/polls.jar

EXPOSE 8080

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar","/app/polls.jar"]
```

在前面章节已经介绍过 Docker 的多阶段构建，这里定义了两个阶段，第一个阶段利用 maven:3.6-alpine 这个基础镜像将项目进行打包，然后将该阶段打包生成的 jar 包文件复制到第二阶段进行最后的镜像打包，这样就可以很好的完成 Docker 镜像的构建工作。



第二种就是传统方式，在 Jenkins Pipeline 中添加一个 maven 构建阶段，然后在第二个 Docker 构建阶段就可以直接获取到前面的 jar 包，也可以很方便完成镜像的构建工作，为了更加清楚的说明 Jenkins Pipeline 的用法，这里采用这种方式，所以 Dockerfile 文件还是使用第一个。



现在将服务端的代码推送到 Gitee：(注意：这里只推送的服务端代码。)

https://gitee.com/st22ab889/polling-app-server.git



2.2 客户端

客户端需要修改 API 的链接地址，同样通过环境变量进行区分，如果有环境变量 APISERVER_URL，则优先使用这个环境变量来作为 API 请求的地址：

```javascript
# 修改文件 src/constants/index.js 中 API_BASE_URL 的地址
let API_URL = 'http://localhost:8080/api';
if (process.env.APISERVER_URL) {
    API_URL = `${process.env.APISERVER_URL}/api`;
}
export const API_BASE_URL = API_URL;
```



因为这里的项目使用的是前后端分离架构，所以同样需要将前端代码进行单独部署，同样要将项目部署到 k8s 环境中，所以也需要做容器化，同样在项目根目录下面添加一个 Dockerfile 文件：

```javascript
# DockerfileForK8s
FROM nginx:1.15.10-alpine
ADD build /usr/share/nginx/html

ADD nginx.conf
/etc/nginx/conf.d/default.conf
```



由于前端页面是单纯的静态页面，所以一般使用一个 nginx 镜像来运行，所以提供一个 nginx.conf 配置文件：

```javascript
# nginx.conf
server {
    gzip on;

    listen       80;
    server_name  localhost;

    root   /usr/share/nginx/html;
    location / {
        try_files $uri /index.html;
        expires 1h;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
```

从 nginx.conf 配置文件可以看到需要将前端页面打包到一个 build 目录，然后将该目录添加到 nginx 镜像中的 /usr/share/nginx/html 目录，这样当 nginx 镜像启动的时候就是直接使用的该文件夹下面的文件。所以现在需要获取打包后的 build 目录，同样的，和上面服务端项目一样，可以使用两种方式来完成这个工作。



第一种方式自然是推荐的 Docker 的多阶段构建，在一个 node 镜像的环境中就可以打包前端项目，所以可以更改 Dockerfile 文件，先进行 node 打包，然后再进行 nginx 启动：

```javascript
# Dockerfile
FROM node:alpine as BUILD

WORKDIR /usr/src/app

RUN mkdir -p /usr/src/app

ADD . /usr/src/app

RUN npm install && \
    npm run build

FROM nginx:1.15.10-alpine
MAINTAINER aaron <kkk_en@163.com>

COPY --from=BUILD /usr/src/app/build /usr/share/nginx/html

ADD nginx.conf
/etc/nginx/conf.d/default.conf
```



第二种方式和上面一样在 Jenkins Pipeline 中添加一个打包构建的阶段即可，这里采用这种方式，所以 Dockerfile 文件还是使用第一个就行。



现在可以将客户端的代码推送到 Gitee 上去，仓库地址为：

https://gitee.com/st22ab889/polling-app-client.git





3 Jenkins

```javascript
Jenkins：http://192.168.32.100:30001/
    用户名：aaron
    密 码：admin000
```



准备好项目后，开始配置 Jenkins，前面在 Pipeline 结合 kubernetes 的示例中使用了一个 kubernetes 的 Jenkins 插件，但是之前使用的方式有一些不妥的地方，因为 Jenkins Pipeline 构建任务绑定到了一个固定的 Slave Pod 上面，这样一来就需要 Slave Pod 中必须包含一系列构建所需要的依赖，比如 docker、maven、node、java等，这样就难免需要定义一个很庞大的 Slave 镜像，所以可以直接在 Pipeline 中去自定义 Slave Pod 中所需要用到的容器模板，这样需要什么镜像只需要在 Slave Pod Template 中声明即可，完全不需要去定义一个庞大的 Slave 镜像。





第一步：

新建配置集群：Dashboard  => 系统管理 => 节点管理 => Configure Clouds => Add a new cloud，如下：

![](images/B81AA9EA6EE8406B9249502A1FB060BCclipboard.png)

注意：如果是在已有的配置上修改，如果这个配置已经添加了 Pod Template，那么就需要 Delete Pod Template





第二步：

然后新建一个名为 polling-app-server 类型为流水线(Pipeline)的任务：

![](images/6F8BABBEF63D4D709BBA47A6EAFB7BB5clipboard.png)





第三步：

然后在这里需要勾选触发远程构建的触发器，其中令牌可以随便写个字符串，然后记住下面的 URL，将 JENKINS_URL 替换成 Jenkins 的地址,这里的地址是：http://192.168.32.100:30001/job/polling-app-server/build?token=server。继续往下在流水线区域可以选择 Pipeline script，写好后还可以测试流水线脚本。这里选择 Pipeline script from SCM，意思是从代码仓库中通过Jenkinsfile文件获取 Pipeline script 脚本定义，然后选择 SCM 来源为Git，在出现的列表中配置仓库地址 https://gitee.com/st22ab889/polling-app-server.git，由于是在一个 Slave Pod 中进行构建，所以如果使用 SSH 方式访问 Gitlab 代码仓库，就需要频繁的去更新 SSH-KEY，所以这里直接使用用户名和密码的方式：

![](images/D7672EFF453A4AC8ADBE54E713241F17clipboard.png)



在Credentials区域点击添加按钮添加访问 Gitee 的用户名和密码：

![](images/D23602CF825749B99C0AAFBE767BF100clipboard.png)



然后需要配置用于构建的分支，如果所有的分支都想要进行构建的话，只需要将 Branch Specifier 区域留空即可，一般情况下不同的环境对应的分支才需要构建，比如 master、develop、test 等，平时开发的 feature 或者 bugfix 的分支没必要频繁构建，这里就只配置 master 和 develop 两个分支用户构建：

![](images/4C01357DCD5B4EFB9319CD90A87AA1ABclipboard.png)





第四步：

这里需要注意的是需要配置 Jenkins 的安全配置，否则这里的触发器没权限访问 Jenkins。Dashboard => 系统管理 => 全局安全配置：

![](images/5317AEB1B45842A3BDD1D5B70EF21EF1clipboard.png)



配置1：勾选上匿名用户具有可读权限，这里用一个示例来说明勾选和不勾选的区别：

![](images/67FD9CD486AE466F85B1EACD9210C56Aclipboard.png)



![](images/B598BC4D2AD64B9598A85B5E14C53461clipboard.png)



![](images/B740FC5A9E9146E3838644DCA840BCF2clipboard.png)

如果在浏览器上访问：http://192.168.32.100:30001/job/polling-app-server，其表现也是一样的，总结：

- 勾选：不用登录页可以访问

- 不勾选：登录才能访问



配置2：跨站请求伪造保护(Prevent Cross Site Request Forgery exploits，简称：CSRF)

- 低版本 jenkins 可以在这个界面把"防止跨站点请求伪造" 。

- 高版本 jenkins 认为这是必要的，所以就取消了这个选项。

```javascript
jenkins wiki 上有对 CSRF 的描述：
https://wiki.jenkins-ci.org/display/JENKINS/Remote+access+API#RemoteaccessAPI-CSRFProtection
其中关于对 CSRF 的描述截图如下：
```

![](images/FE69F7D5C2754BFEB5C2042D4A2AA071clipboard.png)

从截图上可以得出以下信息:

- 使用 API TOEKN 可以避免使用 CSRF token 

- 开启 CSRF 后 ，当发送 POST 请求就必须在 header 中加上 CSRF Token (当然可以使用 API TOEKN 来避免使用 CSRF Token )

- 获取 CSRF token 的方法



使用 API TOEKN 请求：

![](images/6A3AF69E568640AEB86DFB766DC68DC6clipboard.png)



![](images/46E0A9A002914793AF899AFA176B5D46clipboard.png)



```javascript
// 以下是使用命令行触发:
//  curl -i -X POST JENKINS_URL/job/polling-app-server/build  --user USERNAME:API_TOKEN
[aaron@centos7 ~]$ curl -i -X POST http://192.168.32.100:30001/job/polling-app-server/build  --user aaron:110e295d1d61e44c028e977b216cf510b1
HTTP/1.1 201 Created
Date: Wed, 16 Mar 2022 15:20:18 GMT
X-Content-Type-Options: nosniff
Location: http://192.168.32.100:30001/queue/item/34/
Content-Length: 0
Server: Jetty(9.4.42.v20210604)

// curl -i -X POST http://USERNAME:API_TOKEN@IP或Host:port/job/polling-app-server/build
[aaron@centos7 ~]$ curl -i -X POST http://aaron:110e295d1d61e44c028e977b216cf510b1@192.168.32.100:30001/job/polling-app-server/build
HTTP/1.1 201 Created
Date: Wed, 16 Mar 2022 15:28:19 GMT
X-Content-Type-Options: nosniff
Location: http://192.168.32.100:30001/queue/item/35/
Content-Length: 0
Server: Jetty(9.4.42.v20210604)

// 注意：这里是使用 API_TOKEN 去访问接口
// 这里触发流水线的完整 URL 是：
//    http://192.168.32.100:30001/job/polling-app-server/build?token=server
// 可以看到这里没有使用"token=server"的参数也能触发
```



使用 CSRF Token 请求  并且 不勾选匿名用户具有可读权限：

![](images/2C74ED0C190E49DCB2D868C444DAC437clipboard.png)



```javascript
// 以下是使用命令行触发:
    
// 在命令行中获取 CSRF Token
// 格式：wget -q --auth-no-challenge --user USERNAME --password PASSWORD --output-document - 'JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
[aaron@centos7 ~]$ wget -q --auth-no-challenge --user aaron --password admin000 --output-document - 'http://192.168.32.100:30001/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
Jenkins-Crumb:89a22c5db280bbe595b0938a7416b2e4d0664caeca4ad2de316b49bed50631aa

// 这里在header 中加上 Jenkins-Crumb token 仍然报 403 错误,原因是缺少 Cookie
//   当获取 CSRF Token 时, Jenkins 服务会返回一个 Cookie。
//   当使用  CSRF Token 去访问 Jenkins API 时必须要带上这个 Cookie,否则就会报如下错误   
[aaron@centos7 ~]$ curl -X POST http://aaron:admin000@192.168.32.100:30001/job/polling-app-server/build?token=server -H "Jenkins-Crumb:89a22c5db280bbe595b0938a7416b2e4d0664caeca4ad2de316b49bed50631aa"
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
<title>Error 403 No valid crumb was included in the request</title>
</head>
<body><h2>HTTP ERROR 403 No valid crumb was included in the request</h2>
<table>
<tr><th>URI:</th><td>/job/polling-app-server/build</td></tr>
<tr><th>STATUS:</th><td>403</td></tr>
<tr><th>MESSAGE:</th><td>No valid crumb was included in the request</td></tr>
<tr><th>SERVLET:</th><td>Stapler</td></tr>
</table>
<hr><a href="https://eclipse.org/jetty">Powered by Jetty:// 9.4.42.v20210604</a><hr/>

</body>
</html>

// 所以这里使用 curl 工具访问 Jenkins 时需要带上获取 CSRF Token 时返回的 Cookie
// 用curl设置cookies:
//    使用--cookie "COKKIES"选项来指定cookie,多个cookie使用分号分隔,示例如下:
//    curl http://man.linuxde.net --cookie "user=root;pass=123456"
```



使用 CSRF Token 请求  并且 勾选匿名用户具有可读权限

![](images/6AD1CECDFFE8456F8A3826DB8F68F50Cclipboard.png)



![](images/D6EFA8F230404002B7A9B6DAD85C8011clipboard.png)



```javascript
总结：
1.如果使用 API TOEKN 可以避免使用 CSRF Token
2.如果使用 post 请求, 不管有没有开启"匿名用户具有可读权限" 都要满足以下两点：
  (1) 获取 CSRF TOKEN 时 Jenkins 返回的 Cookie 不能删(Cookie保存在客户端,当再次访问相同域名的时候就会自动带上这个Cookie)
  (2) header 中添加  CSRF Token, header 名称为 Jenkins-Crumb , 值为 CSRF TOKEN
3.如果使用 post 请求, 开启了"匿名用户具有可读权限"：
  (1)获取 CSRF TOKEN 时如果使用了 Basic Auth, 那么在使用 Post 接口时也要使用 Basic Auth
  (2)获取 CSRF TOKEN 时如果没使用 Basic Auth, 那么在使用 Post 接口时也不要使用 Basic Auth
4.如果使用 post 请求, 没开启"匿名用户具有可读权限",那么获取 CSRF TOKEN 和使用 Post 接口时都要使用 Basic Auth

//获取 CSRF TOKEN 
Get 请求: http://192.168.32.100:30001/crumbIssuer/api/xml
//示例:触发自动化流水线
Post 请求: http://192.168.32.100:30001/job/polling-app-server/build?token=server

5. CSRF TOKEN 只是针对 POST 请求,如果对于 get 请求：
	(1) 开启了"匿名用户具有可读权限",直接访问
	(2) 没开启"匿名用户具有可读权限",需要设置 Basic Auth,让后再访问
//示例:触发自动化流水线
Get 请求: http://192.168.32.100:30001/job/polling-app-server/build?token=server

// 扩展资料:
IntelliJ配置jenkins服务的Crumb Data
https://blog.csdn.net/weixin_30855761/article/details/98074695   

// jenkins 关闭 CSRF 参考如下资料:
Error 403 No valid crumb was included in the request 报错解决 容器化jenkins关闭CSRF
https://blog.csdn.net/qq_33909098/article/details/113242437    

```



在这里只需勾选"匿名用户具有可读权限"，然后浏览器中访问以下 URL 就可以触发自动构建：

http://192.168.32.100:30001/job/polling-app-server/build?token=server





第五步：

情况一：如果代码苍仓库是使用的是公网仓库，例如 Gitee、GitHub 等

然后到 Gitee 中配置项目 polling-app-server 的 Webhook。注意：这里代码仓库使用 Gitee，但是 jekins 是部署在本地的，所以 Gitee 并不能通过 Webhook 触发 pipeline 的流水线，这里只是说明设置方法。 

![](images/932CA1F07FFA4AD5AFD4074158BB1A3Dclipboard.png)



情况二：代码仓库使用的是本地搭建的仓库,比如 GitLab

如果项目 polling-app-server 是放在本地的 GitLab中，，填写上面得到的 trigger 地址。进入到项目 => Settings => Webhook，配置如下：

![](images/1D70B9536F574FD1B5B63F48724D5E55clipboard.png)

保存 Webhook 配置后，可以直接点击 Test => Push events 测试是否可以正常访问 Webhook 地址，如果测试出现 Hook executed successfully: HTTP 201则证明 Webhook 配置成功，否则就需要检查 Jenkins 的安全配置是否正确。



配置成功后只需要往 Gitee 仓库推送代码就会触发 Pipeline 构建。接下来直接在服务端代码仓库的根目录添加 Jenkinsfile 文件，用于描述流水线构建流程。



注意：当前使用的是  Gitee，而 jenkins 部署在本地，所以需要手动触发，在浏览器中访问以下 URL 即可触发流水线(自动构建): 

http://192.168.32.100:30001/job/polling-app-server/build?token=server





第六步：

首先定义最简单的流程，这里使用 podTemplate 来定义不同阶段使用的容器，有如下阶段：(要注意这里和之前定义 pipeline 的不同之处)

Clone 代码 -> 代码静态分析 -> 单元测试 -> Maven 打包 -> Docker 镜像构建/推送 -> Helm 更新服务。

- Clone 代码在默认的 Slave 容器中即可；

- 静态分析和单元测试这里忽略，有需要这个阶段自己添加上即可；

- Maven 打包肯定就需要 Maven 的容器了；

- Docker 镜像构建/推送需要 Docker 环境；

- 最后的 Helm 更新服务需要一个有 Helm 的容器环境；

所以这里就可以很简单的定义 podTemplate，如下定义：(添加一个 kubectl 工具用于测试)

```javascript
# Jenkinsfile
def label = "slave-${UUID.randomUUID().toString()}"

podTemplate(label: label, serviceAccount: 'jenkins', containers: [
  containerTemplate(name: 'maven', image: 'maven:3.6-alpine', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'docker', image: 'docker', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'kubectl', image: 'st22ab889/kubectl:1.22.1-0', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'helm', image: 'st22ab889/helm-kubectl:3.7.1', command: 'cat', ttyEnabled: true)
], volumes: [
  hostPathVolume(mountPath: '/root/.m2', hostPath: '/var/run/m2'),
  hostPathVolume(mountPath: '/home/jenkins/.kube', hostPath: '/root/.kube'),
  hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
]) {
  node(label) {
    def myRepo = checkout scm
    def gitCommit = myRepo.GIT_COMMIT
    def gitBranch = myRepo.GIT_BRANCH

    stage('单元测试') {
      echo "测试阶段"
    }
    stage('代码编译打包') {
      container('maven') {
        echo "代码编译打包阶段"
      }
    }
    stage('构建 Docker 镜像') {
      container('docker') {
        echo "构建 Docker 镜像阶段"
      }
    }
    stage('运行 Kubectl') {
      container('kubectl') {
        echo "查看 K8S 集群 Pod 列表"
        sh "kubectl get pods"
      }
    }
    stage('运行 Helm') {
      container('helm') {
        echo "查看 Helm Release 列表"
        sh "helm list"
      }
    }
  }
}
```

上面这段 groovy 脚本比较简单，需要注意的是 volumes 区域的定义：

- 将容器中的 /root/.m2 目录挂载到宿主机上是为了给Maven构建添加缓存的，不然每次构建的时候都需要去重新下载依赖，这样就非常慢；

- 挂载 .kube 目录是为了能够让 kubectl 和 helm 两个工具可以读取 k8s 集群的连接信息，不然没办法访问到集群；

- 最后挂载 /var/run/docker.sock 文件是为了能够让 docker 这个容器获取到 Docker Daemon 的信息，因为 docker 这个镜像里面只有客户端的二进制文件，但需要使用宿主机的 Docker Daemon 来构建镜像，

当然也需要在运行 Slave Pod 的节点上拥有能够访问集群的文件，然后在每个Stage 阶段使用特定需要的容器来进行任务的描述即可，所以这几个 volumes都非常重要:

```javascript
volumes: [
  hostPathVolume(mountPath: '/root/.m2', hostPath: '/var/run/m2'),
  hostPathVolume(mountPath: '/home/jenkins/.kube', hostPath: '/root/.kube'),
  hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
]
```



另外一个值得注意的就是label标签的定义，这里使用 UUID 生成一个随机的字符串，这样可以让 Slave Pod 每次的名称都不一样，而且这样就不会被固定在一个 Pod 上面，以后有多个构建任务的时候就不会存在等待的情况，这和之前的说到的固定在一个 label 标签上有所不同。然后将上面的Jenkinsfile文件提交到 Gitlab 代码仓库上：

```javascript
$ git add Jenkinsfile
$ git commit -m "添加 Jenkinsfile 文件"
$ git push origin master
```





第七步：

假如代码仓库能正常连接到 Jenkins 的 Webhook 才能够自动触发流水线 ，这时回到 Jenkins 页面，正常情况可以看到流水线任务 polling-app-server 已经被触发构建。

当前环境是用的 Gitee 作为代码仓库，Jenkins 部署在本地，所以把代码推送到后需要手动触发，有两种方式：

- 在 Jenkins 中的任务页面点击“立即构建”。

![](images/0B3AE460A92E4A0CBAF1D4B51D908A18clipboard.png)

- 在浏览器中访问调用触发自动流水线的 URL，模拟 Webhook 触发。

```javascript
//  浏览器中访问调用触发自动流水线
http://192.168.32.100:30001/job/polling-app-server/build?token=server
```



到 k8s 集群中可以看到多了一个 slave 开头的 Pod，里面有 5 个容器，就是上面 podTemplate 中定义的4个容器和一个默认的 jenkins slave 容器，同样的，构建任务完成后，这个 Pod 也会被自动销毁掉：

```javascript
[root@centos7 ~]# kubectl -n kube-ops get pod
NAME                                                     READY   STATUS    RESTARTS     AGE
jenkins-85db8588bd-tjsn5                                 1/1     Running   8 (8h ago)   167d
slave-1f29459f-5c23-4e58-b486-daffddceea21-kndk3-d2fhx   5/5     Running   0            19s
[root@centos7 ~]#
```



正常可以看到 Jenkins 中的任务构建成功了：

![](images/8D4756C327B84521A0B22EB1D84CFE1Dclipboard.png)



接下来就是实现上面具体的 Pipeline 脚本。





总结:

构建时遇到的问题1：

![](images/F0170EF7304C42619A4CCC4BE63B0141clipboard.png)

问题原因：

之前在配置 k8s 集群的时候可以在 Pod Template 中指定 Service Account，但现在是直接在 Pipeline 中去自定义 Slave Pod 中所需要用到的容器模板，所以就没法配置 ServiceAccount。如果没有配置 ServiceAccount，就会使用一个自动生成的默认的 ServiceAccount，这个默认的 ServiceAccount 没权限访问资源。注: 这个默认的 ServiceAccount 是删不掉的。

```javascript
[root@centos7 aaron]# kubectl -n kube-ops get sa
NAME      SECRETS   AGE
default   1         59s
jenkins   1         173d
```



解决方法：

在 Jenkinsfile 中指定 ServiceAccount，如下：

```javascript
# Jenkinsfile
def label = "slave-${UUID.randomUUID().toString()}"

podTemplate(label: label, serviceAccount: 'jenkins', containers: [
  containerTemplate(name: 'maven', image: 'maven:3.6-alpine', command: 'cat', ttyEnabled: true),
//......
```





构建时遇到的问题2：

![](images/F7E94F917C404817ACDBE4EB5A8644E1clipboard.png)

问题原因：

当前所使用的名为 jenkins 的 serviceAccount 没有 secrets 资源的 list 权限。



解决方法1：修改 ClusterRole，给 secrets 资源添加 list 权限。

[rbac-update.yaml](attachments/C2AFD5D565914DD08C69D69C83037EC7rbac-update.yaml)

```javascript
# rbac-update.yaml

//......
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get","list","watch"]
  - apiGroups: ["networking.k8s.io", "extensions"]
    resources: ["ingresses","ingressclasses","ingresses/status"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    #verbs: ["get"]
    verbs: ["create","delete","get","list","patch","update","watch"]
//......    
```



解决方法2：给当前所使用的名为 jenkins 的 serviceAccount 绑定一个现成的 ClusterRole，这个 ClusterRole 对于 secrets 资源已经有 list 权限。比如名为  system:node 这个 ClusterRole 对象。

```javascript
[root@centos7 aaron]# kubectl get ClusterRoleBinding system:node -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  //......
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node

// 可以看到 system:node 这个 ClusterRole 对象已经有 secrets 资源的 list 权限    
[root@centos7 aaron]# kubectl get ClusterRole system:node -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
//......
- apiGroups:
  - ""
  resources:
  - configmaps
  - secrets
  verbs:
  - get
  - list
  - watch
//......
```



```javascript
# CRB-jenkins.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-system-node-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: kube-ops
```



ClusterRoleBinding 对于同一个 ServiceAccount 来说可以存在多个，比如对于名为 jenkins 的这个 ServiceAccount，可以用两个  ClusterRoleBinding ，一个关联到名为 system:node 这个ClusterRole 对象，另一个关联到名为 jenkins 这个ClusterRole 对象。



对于 system:node 的更多信息：

![](images/9A9A40E462BD49508A58842763675EEDclipboard.png)

使用 Node 鉴权(官网文档):

https://kubernetes.io/zh/docs/reference/access-authn-authz/node/



RBAC鉴权-通过聚合clusterrole实现集群权限控制

https://www.cnblogs.com/bixiaoyu/p/14794646.html



构建时遇到的问题3：jenkins 控制台乱码问题

![](images/37FDA228A013405AA2A994B9491A9C0Aclipboard.png)

问题原因：需要设置 jenkins 的编码。



解决方法参考如下资料：

- jenkins乱码问题  https://www.jianshu.com/p/84c19058f65b





构建时使用到的容器镜像:

- dtzar/helm-kubectl：https://hub.docker.com/r/dtzar/helm-kubectl

- Docker in Docker：https://hub.docker.com/_/docker

