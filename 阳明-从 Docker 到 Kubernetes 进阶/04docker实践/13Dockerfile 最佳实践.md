1.介绍

Docker 官⽅关于 Dockerfile 最佳实践原⽂链接地址：https://docs.docker.com/develop/developimages/dockerfile_best-practices/ 



Docker 可以通过从 Dockerfile 包含所有命令的⽂本⽂件中读取指令⾃动构建镜像，以便构建给定镜像。 



Dockerfiles 使⽤特定的格式并使⽤⼀组特定的指令。您可以在Dockerfile Reference(Dockerfile reference | Docker Documentation)⻚⾯上了解基础知 识 。如果你是新⼿写作 Dockerfile ，你应该从那⾥开始。 



本⽂档介绍了由 Docker，Inc. 和 Docker 社区推荐的⽤于构建⾼效镜像的最佳实践和⽅法。要查看许多实践和建议，请查看Dockerfile for buildpack-deps(https://github.com/docker-library/buildpack-deps/blob/master/jessie/Dockerfile)。 ⼀般准则和建议

```javascript
# Dockerfile 最佳实践官方文档：
https://docs.docker.com/develop/develop-images/dockerfile_best-practices
```



2.⼀般准则和建议



2.1 ⼀般准则和建议

通过 Dockerfile 构建的镜像所启动的容器应该尽可能短暂（⽣命周期短）。「短暂」意味着可以停⽌ 和销毁容器，并且创建⼀个新容器并部署好所需的设置和配置⼯作量应该是极⼩的。我们可以查看下 12 Factor(12要素)应⽤程序⽅法(https://12factor.net/zh_cn/processes)的进程部分，可以让我们理解这种⽆状态⽅式运⾏容器的动机。



2.2 建⽴上下⽂

当你发出⼀个 docker build 命令时，当前的⼯作⽬录被称为构建上下⽂。默认情况下，Dockerfile 就 位于该路径下，当然您也可以使⽤-f参数来指定不同的位置。⽆论 Dockerfile 在什么地⽅，当前⽬录中 的所有⽂件内容都将作为构建上下⽂发送到 Docker 守护进程中去。

下⾯是⼀个构建上下⽂的示例，为构建上下⽂创建⼀个⽬录并 cd 放⼊其中。将“hello”写⼊⼀个⽂本⽂ 件hello，然后并创建⼀个 Dockerfile 并运⾏ cat 。从构建上下⽂（.）中构建图像：

```javascript
mkdir myproject && cd myproject
echo "hello" > hello
echo -e "FROM busybox\nCOPY /hello /\nRUN cat /hello" > Dockerfile
docker build -t helloapp:v1 .
```



现在移动 Dockerfile 和 hello 到不同的⽬录，并建⽴了图像的第⼆个版本（不依赖于缓存中的最后⼀个 版本）。使⽤ -f 指向 Dockerfile 并指定构建上下⽂的⽬录，这样就避免把Dockerfile这个文件也发送到Docker 守护进程中去。

```javascript
mkdir -p dockerfiles context
mv Dockerfile dockerfiles && mv hello context
docker build --no-cache -t helloapp:v2 -f dockerfiles/Dockerfile context
```



在构建的时候包含不需要的⽂件会导致更⼤的构建上下⽂和更⼤的镜像⼤⼩。这会增加构建时间，拉 取和推送镜像的时间以及容器的运⾏时间⼤⼩。要查看您的构建环境有多⼤，请在构建您的系统时查 找这样的消息.

```javascript
Dockerfile：
Sending build context to Docker daemon 187.8MB
```



2.3 使⽤ .dockerignore ⽂件

使⽤ Dockerfile 构建镜像时最好是将 Dockerfile 放置在⼀个新建的空⽬录下。然后将构建镜像所需要 的⽂件添加到该⽬录中。为了提⾼构建镜像的效率，你可以在⽬录下新建⼀个 .dockerignore ⽂件来 指定要忽略的⽂件和⽬录。.dockerignore ⽂件的排除模式语法和 Git 的 .gitignore ⽂件相似。



2.4 使⽤多阶段构建

在 Docker 17.05 以上版本中，你可以使⽤ 多阶段构建 来减少所构建镜像的⼤⼩.



2.5 避免安装不必要的包

为了降低复杂性、减少依赖、减⼩⽂件⼤⼩和构建时间，应该避免安装额外的或者不必要的软件包。 例如，不要在数据库镜像中包含⼀个⽂本编辑器。



2.6 ⼀个容器只专注做⼀件事情

应该保证在⼀个容器中只运⾏⼀个进程。将多个应⽤解耦到不同容器中，保证了容器的横向扩展和复 ⽤。例如⼀个 web 应⽤程序可能包含三个独⽴的容器：web应⽤、数据库、缓存，每个容器都是独⽴ 的镜像，分开运⾏。但这并不是说⼀个容器就只跑⼀个进程，因为有的程序可能会⾃⾏产⽣其他进 程，⽐如 Celery 就可以有很多个⼯作进程。虽然“每个容器跑⼀个进程”是⼀条很好的法则，但这并不 是⼀条硬性的规定。我们主要是希望⼀个容器只关注意⻅事情，尽量保持⼲净和模块化。 

如果容器互相依赖，你可以使⽤Docker 容器⽹络来把这些容器连接起来，我们前⾯已经跟⼤家讲解过 Docker 的容器⽹络模式了。



2.7 最⼩化镜像层数

在 Docker 17.05 甚⾄更早 1.10之 前，尽量减少镜像层数是⾮常重要的，不过现在的版本已经有了⼀ 定的改善了：

- 在 1.10 以后，只有 RUN、COPY 和 ADD 指令会创建层，其他指令会创建临时的中间镜像，但是 不会直接增加构建的镜像⼤⼩了。

- 17.05 版本以后增加了多阶段构建的⽀持，允许我们把需要的数据直接复 制到最终的镜像中，这就允许我们在中间阶段包含⼀些⼯具或者调试信息了，⽽且不会增加最终 的镜像⼤⼩。 

 当然减少 RUN、COPY、ADD 的指令仍然是很有必要的，但是我们也需要在 Dockerfile 可读性（也包括⻓ 期的可维护性）和减少层数之间做⼀个平衡。



2.7 对多⾏参数排序

只要有可能，就将多⾏参数按字⺟顺序排序（⽐如要安装多个包时）。这可以帮助你避免重复包含同 ⼀个包，更新包列表时也更容易，也更容易阅读和审查。建议在反斜杠符号 \ 之前添加⼀个空格，可 以增加可读性。 下⾯是来⾃ buildpack-deps 镜像的例⼦：

```javascript
RUN apt-get update && apt-get install -y \
	bzr \
	cvs \
	git \
	mercurial \
	subversion
```



2.8 构建缓存

在镜像的构建过程中，Docker 根据 Dockerfile 指定的顺序执⾏每个指令。在执⾏每条指令之前， Docker 都会在缓存中查找是否已经存在可重⽤的镜像，如果有就使⽤现存的镜像，不再重复创建。当 然如果你不想在构建过程中使⽤缓存，你可以在 docker build 命令中使⽤ --no-cache=true 选项。 

如果你想在构建的过程中使⽤了缓存，那么了解什么时候可以什么时候⽆法找到匹配的镜像就很重要 了，Docker中缓存遵循的基本规则如下：

- 从⼀个基础镜像开始（FROM 指令指定），下⼀条指令将和该基础镜像的所有⼦镜像进⾏匹配， 检查这些⼦镜像被创建时使⽤的指令是否和被检查的指令完全⼀样。如果不是，则缓存失效。

-  在⼤多数情况下，只需要简单地对⽐ Dockerfile 中的指令和⼦镜像。然⽽，有些指令需要更多的 检查和解释。 

- 对于 ADD 和 COPY 指令，镜像中对应⽂件的内容也会被检查，每个⽂件都会计算出⼀个校验 值。这些⽂件的修改时间和最后访问时间不会被纳⼊校验的范围。在缓存的查找过程中，会将这 些校验和和已存在镜像中的⽂件校验值进⾏对⽐。如果⽂件有任何改变，⽐如内容和元数据，则 缓存失效。 

- 除了 ADD 和 COPY 指令，缓存匹配过程不会查看临时容器中的⽂件来决定缓存是否匹配。例 如，当执⾏完 RUN apt-get -y update 指令后，容器中⼀些⽂件被更新，但 Docker 不会检查这些 ⽂件。这种情况下，只有指令字符串本身被⽤来匹配缓存。 

- ⼀旦缓存失效，所有后续的 Dockerfile 指令都将产⽣新的镜像，缓存不会被使⽤。



3. Dockerfile 指令

下⾯是⼀些常⽤的 Dockerfile 指令，我们也分别来总结下，根据上⾯的建议和下⾯这些指令的合理使 ⽤，可以帮助我们编写⾼效且易维护的 Dockerfile ⽂件。



3.1 FROM

尽可能使⽤当前官⽅仓库作为你构建镜像的基础。推荐使⽤Alpine镜像，因为它被严格控制并保持最⼩ 尺⼨（⽬前⼩于 5 MB），但它仍然是⼀个完整的发⾏版。



3.2 LABEL

你可以给镜像添加标签来帮助组织镜像、记录许可信息、辅助⾃动化构建等。每个标签⼀⾏，由 LABEL 开头加上⼀个或多个标签对。

下⾯的示例展示了各种不同的可能格式。 # 开头的⾏是注释内容。

注意：如果你的字符串包含空格，那么它必须被引⽤或者空格必须被转义。如果您的字符串包含 内部引号字符（"），则也可以将其转义。

```javascript
# Set one or more individual labels
LABEL com.example.version="0.0.1-beta"
LABEL vendor="ACME Incorporated"
LABEL com.example.release-date="2015-02-12"
LABEL com.example.version.is-production=""
```



⼀个镜像可以包含多个标签，在 1.10 之前，建议将所有标签合并为⼀条 LABEL 指令，以防⽌创建额 外的层，但是现在这个不再是必须的了，以上内容也可以写成下⾯这样:

```javascript
# Set multiple labels at once, using line-continuation characters to break long lines
LABEL vendor=ACME\ Incorporated \
	com.example.is-production="" \
	com.example.version="0.0.1-beta" \
	com.example.release-date="2015-02-12"
```



关于标签可以接受的键值对，参考Understanding object labels(https://docs.docker.com/config/labels-custom-metadata/)。



3.3 RUN

为了保持 Dockerfile ⽂件的可读性，以及可维护性，建议将⻓的或复杂的 RUN 指令⽤反斜杠 \ 分割成 多⾏。 

RUN 指令最常⻅的⽤法是安装包⽤的 apt-get 。因为 RUN apt-get 指令会安装包，所以有⼏个问题 需要注意。

- 不要使⽤ RUN apt-get upgrade 或 dist-upgrade，如果基础镜像中的某个包过时了，你应该联系 它的维护者。如果你确定某个特定的包，⽐如 foo，需要升级，使⽤ apt-get install -y foo 就⾏， 该指令会⾃动升级 foo 包。

- 永远将 RUN apt-get update 和 apt-get install 组合成⼀条 RUN 声明，例如：

```javascript
RUN apt-get update && apt-get install -y \
	package-bar \
	package-baz \
	package-foo
```



将 apt-get update 放在⼀条单独的 RUN 声明中会导致缓存问题以及后续的 apt-get install 失败。⽐ 如，假设你有⼀个 Dockerfile ⽂件：

```javascript
FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y curl
```

构建镜像后，所有的层都在 Docker 的缓存中。假设你后来⼜修改了其中的 apt-get install 添加了⼀个 包：

```javascript
FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y curl nginx
```

Docker 发现修改后的 RUN apt-get update 指令和之前的完全⼀样。所以，apt-get update 不会执⾏， ⽽是使⽤之前的缓存镜像。因为 apt-get update 没有运⾏，后⾯的 apt-get install 可能安装的是过时的 curl 和 nginx 版本。

使⽤RUN apt-get update && apt-get install -y可以确保你的 Dockerfiles 每次安装的都是包的最新的 版本，⽽且这个过程不需要进⼀步的编码或额外⼲预。这项技术叫作 cache busting(缓存破坏) 。你也 可以显示指定⼀个包的版本号来达到 cache-busting，这就是所谓的固定版本，例如：

```javascript
RUN apt-get update && apt-get install -y \
	package-bar \
	package-baz \
	package-foo=1.3.*
```

固定版本会迫使构建过程检索特定的版本，⽽不管缓存中有什么。这项技术也可以减少因所需包中未 预料到的变化⽽导致的失败。

下⾯是⼀个 RUN 指令的示例模板，展示了所有关于 apt-get 的建议。

```javascript
RUN apt-get update && apt-get install -y \
	aufs-tools \
	automake \
	build-essential \
	curl \
	dpkg-sig \
	libcap-dev \
	libsqlite3-dev \
	mercurial \
	reprepro \
	ruby1.9.1 \
	ruby1.9.1-dev \
	s3cmd=1.1.* \
&& rm -rf /var/lib/apt/lists/*
```

其中 s3cmd 指令指定了⼀个版本号 1.1.*。如果之前的镜像使⽤的是更旧的版本，指定新的版本会导 致 apt-get udpate 缓存失效并确保安装的是新版本。 另外，清理掉 apt 缓存 var/lib/apt/lists 可以减⼩ 镜像⼤⼩。因为 RUN 指令的开头为 apt-get udpate，包缓存总是会在 apt-get install 之前刷新。

注意：官⽅的 Debian 和 Ubuntu 镜像会⾃动运⾏ apt-get clean，所以不需要显式的调⽤ apt-get clean。



3.4 CMD

CMD 指令⽤于执⾏⽬标镜像中包含的软件和任何参数。CMD ⼏乎都是以 CMD ["executable", "param1", "param2"...] 的形式使⽤。因此，如果创建镜像的⽬的是为了部署某个服务(⽐如 Apache)，你可能会执⾏类似于 CMD ["apache2", "-DFOREGROUND"] 形式的命令。 

多数情况下，CMD 都需要⼀个交互式的 shell (bash, Python, perl 等)，例如 CMD ["perl", "-de0"]，或 者 CMD ["PHP", "-a"]。使⽤这种形式意味着，当你执⾏类似 docker run -it python 时，你会进⼊⼀ 个准备好的 shell 中。 

CMD 在极少的情况下才会以 CMD ["param", "param"] 的形式与 ENTRYPOINT 协同使⽤，除⾮你和你的 镜像使⽤者都对 ENTRYPOINT 的⼯作⽅式⼗分熟悉。



3.5 EXPOSE

EXPOSE 指令⽤于指定容器将要监听的端⼝。因此，你应该为你的应⽤程序使⽤常⻅的端⼝。

 例如，提供 Apache web 服务的镜像应该使⽤ EXPOSE 80，⽽提供 MongoDB 服务的镜像使⽤ EXPOSE 27017。 

对于外部访问，⽤户可以在执⾏ docker run 时使⽤⼀个标志来指示如何将指定的端⼝映射到所选择的 端⼝。



3.6 ENV

为了⽅便新程序运⾏，你可以使⽤ ENV 来为容器中安装的程序更新 PATH 环境变量。例如使⽤ENV PATH /usr/local/nginx/bin:$PATH来确保 CMD ["nginx"] 能正确运⾏。

 ENV 指令也可⽤于为你想要容器化的服务提供必要的环境变量，⽐如 Postgres 需要的 PGDATA。 最 后，ENV 也能⽤于设置常⻅的版本号，⽐如下⾯的示例：

```javascript
ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.4
RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress
&& …ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH
```

类似于程序中的常量，这种⽅法可以让你只需改变 ENV 指令来⾃动的改变容器中的软件版本。



3.7 ADD 和 COPY

虽然 ADD 和 COPY 功能类似，但⼀般优先使⽤ COPY。因为它⽐ ADD 更透明。COPY 只⽀持简单将 本地⽂件拷⻉到容器中，⽽ ADD 有⼀些并不明显的功能（⽐如本地 tar 提取和远程 URL ⽀持）。因 此，ADD的最佳⽤例是将本地 tar ⽂件⾃动提取到镜像中，例如ADD rootfs.tar.xz。

如果你的 Dockerfile 有多个步骤需要使⽤上下⽂中不同的⽂件。单独 COPY 每个⽂件，⽽不是⼀次性 的 COPY 所有⽂件，这将保证每个步骤的构建缓存只在特定的⽂件变化时失效。例如：

```javascript
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
COPY . /tmp/
```

如果将 COPY . /tmp/ 放置在 RUN 指令之前，只要 . ⽬录中任何⼀个⽂件变化，都会导致后续指令的 缓存失效。

为了让镜像尽量⼩，最好不要使⽤ ADD 指令从远程 URL 获取包，⽽是使⽤ curl 和 wget。这样你可以 在⽂件提取完之后删掉不再需要的⽂件来避免在镜像中额外添加⼀层。⽐如尽量避免下⾯的⽤法：

```javascript
ADD http://example.com/big.tar.xz /usr/src/things/
RUN tar -xJf /usr/src/things/big.tar.xz -C /usr/src/things
RUN make -C /usr/src/things all
```

⽽是应该使⽤下⾯这种⽅法：

```javascript
RUN mkdir -p /usr/src/things \
	&& curl -SL http://example.com/big.tar.xz \
	| tar -xJC /usr/src/things \
	&& make -C /usr/src/things all
```

上⾯使⽤的管道操作，所以没有中间⽂件需要删除。 对于其他不需要 ADD 的⾃动提取功能的⽂件或 ⽬录，你应该使⽤ COPY。



3.8 ENTRYPOINT

ENTRYPOINT 的最佳⽤处是设置镜像的主命令，允许将镜像当成命令本身来运⾏（⽤ CMD 提供默认选 项）。

 例如，下⾯的示例镜像提供了命令⾏⼯具 s3cmd

```javascript
ENTRYPOINT ["s3cmd"]
CMD ["--help"]
```

现在直接运⾏该镜像创建的容器会显示命令帮助：

```javascript
docker run s3cmd
```

或者提供正确的参数来执⾏某个命令：

```javascript
docker run s3cmd ls s3://mybucket
```

这样镜像名可以当成命令⾏的参考。ENTRYPOINT 指令也可以结合⼀个辅助脚本使⽤，和前⾯命令⾏ ⻛格类似，即使启动⼯具需要不⽌⼀个步骤。

例如，Postgres 官⽅镜像使⽤下⾯的脚本作为 ENTRYPOINT：

```javascript
#!/bin/bash
set -e
if [ "$1" = 'postgres' ]; then
	chown -R postgres "$PGDATA"
	
	if [ -z "$(ls -A "$PGDATA")" ]; then
		gosu postgres initdb
	fi
	
	exec gosu postgres "$@"fi
exec "$@"
```

注意：该脚本使⽤了 Bash 的内置命令 exec，所以最后运⾏的进程就是容器的 PID 为 1 的进 程。这样，进程就可以接收到任何发送给容器的 Unix 信号了。

该辅助脚本被拷⻉到容器，并在容器启动时通过 ENTRYPOINT 执⾏：

```javascript
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
```

该脚本可以让⽤户⽤⼏种不同的⽅式和 Postgres 交互。你可以很简单地启动 Postgres：

```javascript
docker run postgres
```

也可以执⾏ Postgres 并传递参数：

```javascript
docker run postgres postgres --help
```

最后，你还可以启动另外⼀个完全不同的⼯具，⽐如 Bash：

```javascript
docker run --rm -it postgres bash
```



3.9 VOLUME

VOLUME 指令⽤于暴露任何数据库存储⽂件，配置⽂件，或容器创建的⽂件和⽬录。强烈建议使⽤ VOLUME来管理镜像中的可变部分和⽤户可以改变的部分。



3.10 USER

如果某个服务不需要特权执⾏，建议使⽤ USER 指令切换到⾮ root ⽤户。先在 Dockerfile 中使⽤类似 RUN groupadd -r postgres && useradd -r -g postgres postgres 的指令创建⽤户和⽤户组。

注意：在镜像中，⽤户和⽤户组每次被分配的 UID/GID 都是不确定的，下次重新构建镜像时被分 配到的 UID/GID 可能会不⼀样。如果要依赖确定的 UID/GID，你应该显示的指定⼀个 UID/GID。

你应该避免使⽤ sudo，因为它不可预期的 TTY 和信号转发⾏为可能造成的问题⽐它能解决的问题还 多。如果你真的需要和 sudo 类似的功能（例如，以 root 权限初始化某个守护进程，以⾮ root 权限执 ⾏它），你可以使⽤ gosu。

 最后，为了减少层数和复杂度，避免频繁地使⽤ USER 来回切换⽤户。



3.11 WORKDIR

为了清晰性和可靠性，你应该总是在 WORKDIR 中使⽤绝对路径。另外，你应该使⽤ WORKDIR 来替代 类似于 RUN cd ... && do-something 的指令，后者难以阅读、排错和维护。



3.12 ONBUILD

格式：ONBUILD <其它指令>。 ONBUILD 是⼀个特殊的指令，它后⾯跟的是其它指令，⽐如 RUN, COPY 等，⽽这些指令，在当前镜像构建时并不会被执⾏。只有当以当前镜像为基础镜像，去构建下 ⼀级镜像的时候才会被执⾏。Dockerfile 中的其它指令都是为了定制当前镜像⽽准备的，唯有 ONBUILD 是为了帮助别⼈定制⾃⼰⽽准备的。



假设我们要制作 Node.js 所写的应⽤的镜像。我们都知道 Node.js 使⽤ npm 进⾏包管理，所有依赖、 配置、启动信息等会放到 package.json ⽂件⾥。在拿到程序代码后，需要先进⾏ npm install 才可以获 得所有需要的依赖。然后就可以通过 npm start 来启动应⽤。因此，⼀般来说会这样写 Dockerfile：

```javascript
FROM node:slim
RUN mkdir /app
WORKDIR /app
COPY ./package.json /app
RUN [ "npm", "install" ]
COPY . /app/
CMD [ "npm", "start" ]
```

把这个 Dockerfile 放到 Node.js 项⽬的根⽬录，构建好镜像后，就可以直接拿来启动容器运⾏。但是 如果我们还有第⼆个 Node.js 项⽬也差不多呢？好吧，那就再把这个 Dockerfile 复制到第⼆个项⽬ ⾥。那如果有第三个项⽬呢？再复制么？⽂件的副本越多，版本控制就越困难，让我们继续看这样的 场景维护的问题：

如果第⼀个 Node.js 项⽬在开发过程中，发现这个 Dockerfile ⾥存在问题，⽐如敲错字了、或者需要 安装额外的包，然后开发⼈员修复了这个 Dockerfile，再次构建，问题解决。第⼀个项⽬没问题了，但 是第⼆个项⽬呢？虽然最初 Dockerfile 是复制、粘贴⾃第⼀个项⽬的，但是并不会因为第⼀个项⽬修 复了他们的 Dockerfile，⽽第⼆个项⽬的 Dockerfile 就会被⾃动修复。 

那么我们可不可以做⼀个基础镜像，然后各个项⽬使⽤这个基础镜像呢？这样基础镜像更新，各个项 ⽬不⽤同步 Dockerfile 的变化，重新构建后就继承了基础镜像的更新？好吧，可以，让我们看看这样 的结果。那么上⾯的这个 Dockerfile 就会变为：

```javascript
FROM node:slim
RUN mkdir /app
WORKDIR /app
CMD [ "npm", "start" ]
```

这⾥我们把项⽬相关的构建指令拿出来，放到⼦项⽬⾥去。假设这个基础镜像的名字为 my-node 的 话，各个项⽬内的⾃⼰的 Dockerfile 就变为：

```javascript
FROM my-node
COPY ./package.json /app
RUN [ "npm", "install" ]
COPY . /app/
```

基础镜像变化后，各个项⽬都⽤这个 Dockerfile 重新构建镜像，会继承基础镜像的更新。

 那么，问题解决了么？没有。准确说，只解决了⼀半。如果这个 Dockerfile ⾥⾯有些东⻄需要调整 呢？⽐如 npm install 都需要加⼀些参数，那怎么办？这⼀⾏ RUN 是不可能放⼊基础镜像的，因为涉 及到了当前项⽬的 ./package.json，难道⼜要⼀个个修改么？所以说，这样制作基础镜像，只解决了原 来的 Dockerfile 的前4条指令的变化问题，⽽后⾯三条指令的变化则完全没办法处理。 

ONBUILD 可以解决这个问题。让我们⽤ ONBUILD 重新写⼀下基础镜像的 Dockerfile:

```javascript
FROM node:slim
RUN mkdir /app
WORKDIR /app
ONBUILD COPY ./package.json /app
ONBUILD RUN [ "npm", "install" ]
ONBUILD COPY . /app/
CMD [ "npm", "start" ]
```

这次我们回到原始的 Dockerfile，但是这次将项⽬相关的指令加上 ONBUILD，这样在构建基础镜像的 时候，这三⾏并不会被执⾏。然后各个项⽬的 Dockerfile 就变成了简单地：

```javascript
FROM my-node
```

是的，只有这么⼀⾏。当在各个项⽬⽬录中，⽤这个只有⼀⾏的 Dockerfile 构建镜像时，之前基础镜 像的那三⾏ ONBUILD 就会开始执⾏，成功的将当前项⽬的代码复制进镜像、并且针对本项⽬执⾏ npm install，⽣成应⽤镜像。





4. 官⽅仓库示例 

这些官⽅仓库的 Dockerfile 都是参考典范：https://github.com/docker-library/docs



