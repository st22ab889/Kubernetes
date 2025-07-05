1. 镜像的定制实际上就是定制每⼀层所添加的配置、⽂件等信息，但是命令毕竟只是命令，每次定制都得去重复执⾏这个命令，⽽且还不够直 观，如果我们可以把每⼀层修改、安装、构建、操作的命令都写⼊⼀个脚本，⽤这个脚本来构建、定制镜像，这个脚本就是我们说的 Dockerfile



2.Dockerfile 是⼀个⽂本⽂件，其内包含了⼀条条的指令(Instruction)，每⼀条指令构建⼀层，因此每⼀ 条指令的内容，就是描述该层应当如何构建。



3.构建一个名为“Dockerfile”的文件,其内容如下 ：

[docker.zip](attachments/3890BA50462C4FA2903ED0A00DCA2943docker.zip)

```javascript
FROM nginx 
RUN echo 'Hello, Docker!' > /usr/share/nginx/html/index.html
```

A. 所谓定制镜像，那⼀定是以⼀个镜像为基础，在其上进⾏定制。就像我们之前运⾏了⼀个 nginx 镜像 的容器，再进⾏修改⼀样，基础镜像是必须指定的。⽽ FROM 就是指定基础镜像，因此⼀个 Dockerfile 中 FROM 是必备的指令，并且必须是第⼀条指令。



在Docker Store上有⾮常多的⾼质量的官⽅镜像，有可以直接拿来使⽤的服务类的镜像，如 nginx、 redis、mongo、mysql、httpd、php、tomcat 等；也有⼀些⽅便开发、构建、运⾏各种语⾔应⽤的镜 像，如 node、openjdk、python、ruby、golang 等。可以在其中寻找⼀个最符合我们最终⽬标的镜像 为基础镜像进⾏定制。 如果没有找到对应服务的镜像，官⽅镜像中还提供了⼀些更为基础的操作系统镜像，如 ubuntu、 debian、centos、fedora、alpine 等，这些操作系统的软件库为我们提供了更⼴阔的扩展空间。



除了选择现有镜像为基础镜像外，Docker 还存在⼀个特殊的镜像，名为 scratch 。这个镜像是虚拟的 概念，并不实际存在，它表示⼀个空⽩的镜像。

```javascript
FROM scratch
...
```

以 scratch 为基础镜像的话，意味着你不以任何镜像为基础，接下来所写的指令将作为镜像第 ⼀层开始存在。有的同学可能感觉很奇怪，没有任何基础镜像，我怎么去执⾏我的程序呢，其实对于 Linux 下静态编译的程序来说，并不需要有操作系统提供运⾏时⽀持，所需的⼀切库都已经在可执行文件⾥了，因此直接 FROM scratch 会让镜像体积更加⼩巧。使⽤ Go 语⾔开发的应⽤会编译打包成二进制文件,所以Go应用很多会使⽤scratch这种⽅式来制作镜像就可以直接运行，这也是为什么有⼈认为Go是特别适合容器微服务架构的语⾔的原因之⼀。结论:为了减小镜像的大小，可以用scratch作为基础镜像.



B. RUN 指令是⽤来执⾏命令⾏命令的。由于命令⾏的强⼤能⼒， RUN 指令在定制镜像时是最常⽤的指令 之⼀。其格式有两种：

- shell 格式：RUN <命令>，就像直接在命令⾏中输⼊的命令⼀样。刚才写的 Dockerfile 中的 RUN 指令就是这种格式。

```javascript
RUN echo 'Hello, Docker!' > /usr/share/nginx/html/index.html
```

- exec 格式：RUN ["可执⾏⽂件", "参数1", "参数2"]，这更像是函数调⽤中的格式。 既然 RUN 就像 Shell 脚本⼀样可以执⾏命令，那么我们是否就可以像 Shell 脚本⼀样把每个命令对应⼀个 RUN 呢？⽐如这样：

```javascript
FROM debian:jessie 
RUN apt-get update 
RUN apt-get install -y gcc libc6-dev make 
RUN wget -O redis.tar.gz "http://download.redis.io/releases/redis-3.2.5.tar.gz" 
RUN mkdir -p /usr/src/redis 
RUN tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 
RUN make -C /usr/src/redis 
RUN make -C /usr/src/redis install
```

之前说过，Dockerfile 中每⼀个指令都会建⽴⼀层，RUN 也不例外。每⼀个 RUN 的⾏为，就和刚才 我们⼿⼯建⽴镜像的过程⼀样：新建⽴⼀层，在其上执⾏这些命令，执⾏结束后，commit 这⼀层的修 改，构成新的镜像。 ⽽上⾯的这种写法，创建了 7 层镜像。这是完全没有意义的，⽽且很多运⾏时不需要的东⻄，都被装 进了镜像⾥，⽐如编译环境、更新的软件包等等。结果就是产⽣⾮常臃肿、⾮常多层的镜像，不仅仅 增加了构建部署的时间，也很容易出错。 这是很多初学 Docker 的⼈常犯的⼀个错误。 

Union FS 是有最⼤层数限制的，⽐如 AUFS，曾经是最⼤不得超过 42 层，现在是不得超过 127 层。

上⾯的 Dockerfile 正确的写法应该是这样：

```javascript
FROM debian:jessie
RUN buildDeps='gcc libc6-dev make' \ 
    && apt-get update \ 
    && apt-get install -y $buildDeps \ 
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-3.2.5.tar.gz" \ 
    && mkdir -p /usr/src/redis \ 
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \ 
    && make -C /usr/src/redis \ 
    && make -C /usr/src/redis install \
   && rm -rf /var/lib/apt/lists/* \ 
   && rm redis.tar.gz \ 
   && rm -r /usr/src/redis \ 
   && apt-get purge -y --auto-remove $buildDeps
```

⾸先，之前所有的命令只有⼀个⽬的，就是编译、安装 redis 可执⾏⽂件。因此没有必要建⽴很多层， 这只是⼀层的事情。因此，这⾥没有使⽤很多个 RUN 对⼀⼀对应不同的命令，⽽是仅仅使⽤⼀个 RUN 指令，并使⽤ && 将各个所需命令串联起来。将之前的 7 层，简化为了 1 层。在撰写 Dockerfile 的时候，要经常提醒⾃⼰，这并不是在写 Shell 脚本，⽽是在定义每⼀层该如何构建。

并且，这⾥为了格式化还进⾏了换⾏。Dockerfile ⽀持 Shell 类的⾏尾添加 \ 的命令换⾏⽅式，以及 ⾏⾸ # 进⾏注释的格式。良好的格式，⽐如换⾏、缩进、注释等，会让维护、排障更为容易，这是⼀ 个⽐较好的习惯。 

此外，还可以看到这⼀组命令的最后添加了清理⼯作的命令，删除了为了编译构建所需要的软件，清 理了所有下载、展开的⽂件，并且还清理了 apt 缓存⽂件。这是很重要的⼀步，我们之前说过，镜像 是多层存储，每⼀层的东⻄并不会在下⼀层被删除，会⼀直跟随着镜像。因此镜像构建时，⼀定要确 保每⼀层只添加真正需要添加的东⻄，任何⽆关的东⻄都应该清理掉。 很多⼈初学 Docker 制作出了 很臃肿的镜像的原因之⼀，就是忘记了每⼀层构建的最后⼀定要清理掉⽆关⽂件



4.使用Dockerfile构建镜像.

a.首先在命令行中进入到 Dockerfile ⽂件所在⽬录，Dockerfile内容如下:

```javascript
FROM nginx 
RUN echo 'Hello, Docker!' > /usr/share/nginx/html/index.html
```



b.们使⽤了 docker build 命令 进⾏镜像构建。其格式为：

```javascript
$ docker build [选项] <上下⽂路径/URL/->
```

 

 执行下列命令:

```javascript
docker build -t nginx:v3 .
```

   -t nginx:v3表示指定了最终镜像的名称为nginx:v3

   最后面的"."表示上下⽂路径



 可以使用如下命令对比区别:

```javascript
docker history nginx
docker history nginx:v2
```



c. 测试镜像

```javascript
docker images
docker run --name webservice3 -d -p 8083:80 nginx:v2
docker ps
```

 浏览器中访问"localhost:8083"



5.镜像构建上下文

docker build 命令最后有⼀个 .  表示当前⽬录，⽽ Dockerfile 就在当前⽬录， 因此不少初学者以为这个路径是在指定 Dockerfile 所在路径，这么理解其实是不准确的。如果对应上 ⾯的命令格式，你可能会发现，这是在指定上下⽂路径。那么什么是上下⽂呢？



⾸先我们要理解 docker build 的⼯作原理。Docker 在运⾏时分为 Docker 引擎（也就是服务端守护进 程）和客户端⼯具。Docker 的引擎提供了⼀组 REST API，被称为 Docker Remote API，⽽如 docker 命令这样的客户端⼯具，则是通过这组 API 与 Docker 引擎交互，从⽽完成各种功能。因此，虽然表 ⾯上我们好像是在本机执⾏各种 docker 功能，但实际上，⼀切都是使⽤的远程调⽤形式在服务端 （Docker 引擎）完成。也因为这种 C/S 设计，让我们操作远程服务器的 Docker 引擎变得轻⽽易举。



当我们进⾏镜像构建的时候，并⾮所有定制都会通过 RUN 指令完成，经常会需要将⼀些本地⽂件复制 进镜像，⽐如通过 COPY 指令、ADD 指令等。⽽ docker build 命令构建镜像，其实并⾮在本地构建， ⽽是在服务端，也就是 Docker 引擎中构建的。那么在这种客户端/服务端的架构中，如何才能让服务 端获得本地⽂件呢？



这就引⼊了上下⽂的概念。当构建的时候，⽤户会指定构建镜像上下⽂的路径，docker build 命令得知 这个路径后，会将路径下的所有内容打包，然后上传给 Docker 引擎。这样 Docker 引擎收到这个上下 ⽂包后，展开就会获得构建镜像所需的⼀切⽂件。如果在 Dockerfile 中这么写：

```javascript
COPY ./package.json /app/
```

这并不是要复制执⾏docker build 命令所在的⽬录下的 package.json，也不是复制 Dockerfile 所在⽬ 录下的 package.json，⽽是复制 上下⽂（context） ⽬录下的 package.json。

因此， COPY 这类指令中的源⽂件的路径都是相对路径。这也是初学者经常会问的为什么 COPY ../package.json /app 或者 COPY /opt/xxxx /app ⽆法⼯作的原因，因为这些路径已经超出了上下⽂的 范围，Docker 引擎⽆法获得这些位置的⽂件。如果真的需要那些⽂件，应该将它们复制到上下⽂⽬录 中去。

现在就可以理解刚才的命令 docker build -t nginx:v3 . 中的这个 . ，实际上是在指定上下⽂的⽬ 录，docker build 命令会将该⽬录下的内容打包交给 Docker 引擎以帮助构建镜像。



如果观察 docker build 输出，我们其实已经看到了这个发送上下⽂的过程：

```javascript
$ docker build -t nginx:v3 .
Sending build context to Docker daemon 2.048 kB
 ...
```



理解构建上下⽂对于镜像构建是很重要的，可以避免犯⼀些不应该的错误。⽐如有些初学者在发现 COPY /opt/xxxx /app 不⼯作后，于是⼲脆将 Dockerfile 放到了硬盘根⽬录去构建，结果发现 docker build 执⾏后，在发送⼀个⼏⼗ GB 的东⻄，极为缓慢⽽且很容易构建失败。那是因为这种做法是在让 docker build 打包整个硬盘，这显然是使⽤错误。



⼀般来说，应该会将 Dockerfile 置于⼀个空⽬录下，或者项⽬根⽬录下。如果该⽬录下没有所需⽂ 件，那么应该把所需⽂件复制⼀份过来。如果⽬录下有些东⻄确实不希望构建时传给 Docker 引擎，那 么可以⽤ .gitignore ⼀样的语法写⼀个 .dockerignore ，该⽂件是⽤于剔除不需要作为上下⽂传递给 Docker 引擎的。

比如在上下文文件夹中有一个"add.json"这样一个文件不想传递给 Docker 引擎,就可以在文件创建一个" .dockerignore"这样的文件,文件内容如下 ：

```javascript
add.json
```



为什么会有⼈误以为 . 是指定 Dockerfile 所在⽬录呢？这是因为在默认情况下，如果不额外指定 Dockerfile 的话，会将上下⽂⽬录下的名为 Dockerfile 的⽂件作为 Dockerfile。

这只是默认⾏为，实际上 Dockerfile 的⽂件名并不要求必须为 Dockerfile，⽽且并不要求必须位于上下 ⽂⽬录中，⽐如可以⽤ -f ../Dockerfile.php 参数指定某个⽂件作为 Dockerfile。 当然，⼀般⼤家习惯性的会使⽤默认的⽂件名 Dockerfile，以及会将其置于镜像构建上下⽂⽬录中。

如果Dockerfile的文件名为"Dockerfile2",构建命令如下 ：

```javascript
docker build -t nginx:v3 -f Dockerfile2 .
```



6.迁移镜像. 类似于离线下载的方式,如果机器访问不了docker仓库，就可以使用这种方式加载镜像.



Docker 提供了 docker load 和 docker save 命令，⽤以将镜像保存为⼀个 tar ⽂件，然后传输到另 ⼀个位置上，再加载进来。这是在没有 Docker Registry 时的做法，现在已经不推荐，镜像迁移应该直 接使⽤ Docker Registry，⽆论是直接使⽤ Docker Hub 还是使⽤内⽹私有 Registry 都可以.



使⽤ docker save 命令可以将镜像保存为归档⽂件,保存镜像的命令为：

```javascript
docker save nginx:v3 | gzip > nginx.v3.tar.gz
```

当前文件夹就会多一个"nginx.v3.tar.gz"的文件.



⽤下⾯这个命令加载镜像：:

```javascript
docker load -i nginx.v3.tar.gz
```



查看是否加载成功：

```javascript
docker images
docker history 镜像名称或ID
```



如果我们结合这两个命令以及 ssh 甚⾄ pv 的话，利⽤ Linux 强⼤的管道，我们可以写⼀个命令完成从 ⼀个机器将镜像迁移到另⼀个机器，并且带进度条的功能：

```javascript
docker save <镜像名> | bzip2 | pv | ssh <⽤户名>@<主机名> 'cat | docker load'

命令解释:
   pv 用来显示进度条.
   
   cat 命令的原始用途是 连接并显示文件内容（cat 即 concatenate 的缩写），例如：
       cat /path/to/file.txt 
   但 cat 还有一个重要特性：当不指定文件参数时，它会从标准输入（stdin）读取数据，并将其原样输出到标准输出（stdout）。例如：
       echo "Hello" | cat  
   此时 cat 相当于一个 “透明管道”，仅负责传递数据而不做任何修改。


```

