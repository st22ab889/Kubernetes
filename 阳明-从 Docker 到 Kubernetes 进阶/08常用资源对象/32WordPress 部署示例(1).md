1. 利用k8s常见的资源对象来部署⼀个实际的应⽤ - 将 Wordpress 应⽤部署到K8S集群当中.前⾯已经⽤ docker-compose 的⽅式部署过，可以了解到要部署⼀个 Wordpress 应⽤主要涉及到两个镜像：wordpress 和 mysql ，wordpress 是应⽤的核⼼程序，mysql ⽤于数据存储。



将应⽤部署到 blog 这个命名空间下⾯，创建一个名为blog的命名空间:

```javascript

kubectl create namespace blog
kubectl get namespace

```





2. 方式一: 把wordpress 和 mysql部署到同一个Pod中.

⼀个 Pod 中可以包含多个容器，那么很明显这⾥可以将 wordpress 和 mysql  部署成⼀个 独⽴的 Pod。

[wordpress-pod.yaml](attachments/30C5F09A022446779C3A1C5B83C7B643wordpress-pod.yaml)

```javascript
# wordpress-pod.yaml

---
apiVersion: v1
kind: Pod
metadata:
  name: wordpress
  namespace: blog
spec:
  # Kubernetes的调度有简单,有复杂.指定NodeName和使用NodeSelector调度是最简单的，可以将Pod调度到期望的节点上
  # NodeName和NodeSelector使用示例如下:

  # 指定节点运行
  # nodeName: k8s-master
  
  # nodeSelector:
    # 指定调度节点为带有label标记为：cloudnil.com/role=dev的node节点
    # cloudnil.com/role: dev 

  # 一个Pod中部署两个容器，分别是wordpress和mysql
  containers:
  - name: wordpress
    image: wordpress
    # 定义镜像拉取策略."IfNotPresent"表示如果镜像在节点上已存在就不要去拉取了,这样可以加快容器运行速度
    # imagePullPolicy的默认值是always, 它表示即使节点有这个镜像，它也会去重新拉取
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
      name: wdport
    env:
    - name: WORDPRESS_DB_HOST
      # 因为wordpress和mysql定义在同一个Pod下,同一个Pod下的容器共享同一个网络命名空间,所以直接用localhost就可以访问
      value: localhost:3306
    - name: WORDPRESS_DB_USER
      value: wordpress
    - name: WORDPRESS_DB_PASSWORD
      value: wordpress
  - name: mysql
    image: mysql:5.7
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 3306
      name: dbport
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: rootPassWord
    - name: MYSQL_DATABASE
      value: wordpress
    - name: MYSQL_USER
      value: wordpress
    - name: MYSQL_PASSWORD
      value: wordpress
    volumeMounts:
    - name: db
      mountPath: /var/lib/mysql
  volumes:
  - name: db
    # 问题: 假如Pod重启之前容器在节点1上面，数据挂载到节点1这个目录上,重启之后容器很可能就调度到节点2上，节点2的mountPath上就没有数据了
    # 如果用hostPath,最好指定"nodeSelector"或"nodeName"指定调度节点，这样应用重启后也能调度到同一个节点上.
    hostPath:
      path: /var/lib/mysql

```



yaml文件中针对 mysql 这个容器做了⼀个数据卷的挂载，这是为了能够将 mysql 的数据能够持久化到节点上，这样下次 mysql 容器重启过后数据不⾄于丢失。

这种单⼀ Pod 的⽅式有以下缺点:

- 假如现在需要部署3个 Wordpress 的副 本，这时就需要在上⾯的 YAML ⽂件中加上 replicas: 3 这个属性。但是这样一来不仅仅是 Wordpress 这个容器会被部署成3份，连MySQL 数据库也会被部署成3份。 MySQL 数据库单纯的部署成3份不能联合起来使⽤，否则就不需要各种数据库集群解决⽅案了，所以这⾥部署3个 Pod 实例，实际上他们互相之间 是独⽴的，因为数据不相通。解决方法是把 wordpress 和 mysql 这两个容器部署成独⽴的 Pod ，把它们拆分开。

- 另外⼀个问题是 wordpress 容器需要去连接 mysql 数据库，如果放在⼀起不能保证mysql 先启动起来。貌似没有特别的办法，前⾯学习的 InitContainer 也是针对 Pod 来的，所以 ⽆论如何都需要将他们进⾏拆分。



```javascript

kubectl create -f wordpress-pod.yaml
kubectl get pods -n blog
# 使⽤ describe 指令查看详细信息
kubectl describe pod wordpress -n blog

// kubectl logs 常用于将容器中的日志导出
 # 如果Pod中只有一个容器
 kubectl logs $PodName
 # 如果Pod中有多个容器
 kubectl logs $PodName --all-containers=true
 # 如果Pod中有多个容器,需要指定一个容器查看
kubectl logs $PodName -c $ContainerName
 # 更多"kubectl logs"的使用方法
 kubectl logs --help
 
 // 查看容器日志
 kubectl logs wordpress --all-containers=true -n blog
 kubectl logs wordpress -c wordpress -n blog
 kubectl logs wordpress -c mysql -n blog

kubectl delete pod wordpress -n blog
kubectl get pods -n blog
```



3. 方式二: 把wordpress 和 mysql拆分,分别创建Pod.

拆分成两个 Pod ，并且使⽤ Deployment 来管理Pod 。方式一只是为了单纯说明怎么把前⾯的 Docker 环境下的 wordpress 转换成 Kubernetes 环境下⾯的 Pod ，有了上⾯的 Pod 模板，转换成 Deployment 很容易。



3.1 创建⼀个 MySQL 的 Deployment 对象

[wordpress-db.yaml](attachments/8A2C385446D94BBBAB283B2D57CDD223wordpress-db.yaml)

```javascript
# wordpress-db.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deploy
  namespace: blog
  # 这个labels作用的对象是Deployment
  labels:
    app: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  # template就是定义Pod的模板
  template:
    metadata:
      # 这里指定Pod的name不起作用,因为使用Deployment管理的Pod,它会自动创建Pod名称,格式是"[Deployment的名称]-[随机字符串]"
      labels:
        #  这个labels作用的对象是Pod
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
          name: dbport
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootPassWord
        - name: MYSQL_DATABASE
          value: wordpress
        - name: MYSQL_USER
          value: wordpress
        - name: MYSQL_PASSWORD
          value: wordpress
        volumeMounts:
          - name: db
            mountPath: /var/lib/mysql
      # volumes和containers同级,因为volumes针对Pod里面的所有容器,所有容器都有可能存在挂载数据卷，所以同级是为了统一说明它们的挂载方式
      volumes:
        - name: db
          hostPath:
            path: /var/lib/mysql

# 如果 wordpress 和 mysql 在同一个Pod中可以通过 localhost 来进⾏访问
# 这里可以通过给Deployment创建Service来让 Wordpress 来访问.
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: blog
spec:
  selector:
    app: mysql
  #service的类型,默认是ClusterIP的类型,ClusterIP是通过集群内部IP来暴露服务,使用这种类型只能在集群内部互相访问
  type: ClusterIP  
  ports:
  - name: mysqlport
    protocol: TCP
    port: 3306
    # 这里使用容器端口的名称是为了解决以下两个问题:
    # 假如端口号之后发生改变,只要名称没有变,这里不用作任何变更
    # 假如还有个服务也具有"app: mysql"这个labels,也会关联到Service,但有可能它的端口不是3306,这里直接写3306就出现了问题,写名称就能避免这种问题
    targetPort: dbport
```



```javascript
kubectl create -f wordpress-db.yaml

# 运行如下命令可以看到Pod的IP为"10.244.189.108"
kubectl get pods -o wide -n blog
# 运行如下命令可以看到Pod的IP为"10.244.189.108", 端口为"3306/TCP"
kubectl describe pod mysql-deploy-79655fc986-hbmlg  -n blog

kubectl get deployment -n blog 
kubectl describe deployment mysql-deploy -n blog

kubectl get svc -n blog


# 查看 Service 的详细情况可以得到如下信息：
# "Endpoints:10.244.189.108:3306",它跟Pod的IP和端口相对应，相当于mysql这个Service关联了mysql这个Pod
# "IP:10.97.120.75" 这是ClusterIP, "Port: mysqlport  3306/TCP"这是ClusterPort
# ClusterIP 和 ClusterPort 就是 wordpress 服务要使用的IP和端口
kubectl describe svc mysql -n blog

// 总结:
// mysql这个Service的 Endpoints 部分匹配到了⼀个Pod,⽣成了⼀个clusterIP.
// 现在可以通过这个 clusterIP 加上定义的3306端⼝就可以正常访问 mysql 服务了.
```



3.2 . 创建 Wordpress 服务

[wordpress.yaml](attachments/E2A921C6DD074897B6311C98EBC63BACwordpress.yaml)

```javascript
# wordpress.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-deploy
  namespace: blog
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: wdport
        env:
        - name: WORDPRESS_DB_HOST
          # 同一个Pod当使用localhost没有问题. 现在因为拆分了, 要通过mysql这个Service的ClusterIP和端口进行访问
          value: 10.97.120.75:3306
        - name: WORDPRESS_DB_USER
          value: wordpress
        - name: WORDPRESS_DB_PASSWORD
          value: wordpress
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: blog
spec:
  selector:
    app: wordpress
  #  NodePort 类型的 Service 才能让外网用户进行访问,这里要添加"type: NodePort",否则type的默认值是"ClusterIP"
  type: NodePort
  ports:
  - name: wordpressport
    protocol: TCP
    port: 80
    targetPort: wdport

```





```javascript

kubectl create -f wordpress.yaml
kubectl get deployment -n blog

kubectl get pods -n blog
kubectl get pod wordpress-deploy-79b697dd9f-rgxd7 -n blog -o yaml
kubectl describe pod wordpress-deploy-79b697dd9f-rgxd7 -n blog

kubectl  get svc -n blog
kubectl describe svc wordpress -n blog
```



在浏览器中输入以下地址访问看是否出现Wordpress 主页:

http://192.168.32.100:30797/

http://192.168.32.101:30797/



假如有自己的域名，最好在前面挂一个nginx ，把Wordpress这个服务给挂到nginx上面去，然后用dns解析一下就可以用自己的域名来访问Wordpress服务了，而且这个Wordpress服务是跑在k8s上面的。 









