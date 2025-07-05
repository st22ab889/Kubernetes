1. 特定场合下使⽤的控制器：DaemonSet 与 StatefulSet



2. DaemonSet 的使⽤

DaemonSet就是⽤来部署守护进程的,通过该控制器的名称我们可以看出它的⽤法。DaemonSet ⽤于在每个 Kubernetes 节点中将守护进程的副本作为后台进程运⾏，说⽩了就是在每个节点部署⼀ 个 Pod 副本。当有节点加⼊到 Kubernetes 集群中， Pod 会被调度到该节点上运⾏，当有节点从集群被移除后，该节点上的这个 Pod 也会被移除。当然，如果我们删除 DaemonSet ，所有和这个对象相 关的 Pods 都会被删除。



以下情况下会需要⽤到这种业务场景：

- 集群存储守护程序，如 glusterd 、 ceph 要部署在每个节点上以提供持久性存储； 

- 节点监视守护进程，如 Prometheus 监控集群，可以在每个节点上运⾏⼀个 node-exporter 进程来 收集监控节点的信息； 

- ⽇志收集守护程序，如 fluentd 或 logstash 这样的agent，在每个节点上运⾏以收集容器的⽇志



需要特别说明的⼀个就是关于 DaemonSet 运⾏的 Pod 的调度问题，正常情况下， Pod 运⾏在哪 个节点上是由 Kubernetes 的调度器策略来决定的，然⽽，由 DaemonSet 控制器创建的 Pod 实际上提 前已经确定了在哪个节点上了（ Pod 创建时指定了 .spec.nodeName ），所以：

- DaemonSet 并不关⼼⼀个节点的 unshedulable 字段，可以在调度章节中继续了解。 

- DaemonSet 可以创建 Pod ，即使调度器还没有启动，这点⾮常重要。



演示DaemonSet：

[daemonset-demo.yaml](attachments/E80DFC77A62A496E940F2D280315725Fdaemonset-demo.yaml)

```javascript
# daemonset-demo.yaml
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: daemonset-demo
  labels:
    app: demonset
spec:
  selector:
    matchLabels:
       k8s-app: nginx
  template:
    metadata:
      labels:
        k8s-app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - name: nginx-port
          containerPort: 80
```



```javascript

kubectl create -f demonset-demo.yaml
# 查看节点
kubectl get nodes

kubectl get daemonset

#  观察 DaemonSet 运⾏的 Pod 是否被分布到了每个节点上
# "-l"表示根据label过滤Pod,可以看到在Node上被调度了,master不会被普通的应用来调度
kubectl get pods -l k8s-app=nginx -o wide

// 假如现在新增加一个节点, 在新增加的节点上会自动生成这样一个Pod
// 假如把某一个节点移除掉, 这个Pod也会自动移除
```





3. StatefulSet 的使⽤



有状态服务和⽆状态服务:

- ⽆状态服务（Stateless Service）：该服务运⾏的实例不会在本地存储需要持久化的数据，并且多 个实例对于同⼀个请求响应的结果是完全⼀致的，⽐如前⾯的 WordPress 实例，可以同时启动多个实例，但是我们访问任意⼀个实例得到的结果都是⼀样的。因为它唯⼀ 需要持久化的数据是存储在 MySQL 数据库中的，所以可以说 WordPress 这个应⽤是⽆状态服 务，但是 MySQL 数据库就不是了，因为他需要把数据持久化到本地。

-  有状态服务（Stateful Service）：和上⾯的概念是对⽴的，该服务运⾏的实例需要在本地存 储持久化数据，⽐如 MySQL 数据库，现在运⾏在节点A，那么他的数据就存储在节点A上 ⾯的，如果这个时候你把该服务迁移到节点B去的话，那么就没有之前的数据了，因为他需要去对应的数据⽬录⾥⾯恢复数据，⽽此时没有任何数据。



常⻅的 WEB 应⽤是通过 session 来保持⽤户的登录状态的，如果将 session 持久化到节点上，那么该应⽤就是⼀个有状态的服务了，因为登录进来把用户的 session 持久化到节点A上了，下次登录的时候可能会将请求路由到节点B上，但是节点B上根本就没有当前的 session 数据，就会被认为是未登录状态了，这样就导致前后两次请求得到的结果不⼀致。所以⼀般为了横向扩展，都会把这类 WEB 应⽤改成⽆状态的服务，将 session 数据存⼊⼀个公共的地⽅，⽐如 redis ⾥⾯，对 于⼀些客户端请求 API 的情况，就不使⽤ session 来保持⽤户状态，改成⽤ token 就可以 (类似于JWT这种token来验证就可以)。



⽆状态服务利⽤ Deployment 或者 RC 都可以很好的控制，对应有状态服务，需要考虑的细节就要多很多了，容器化应⽤程序最困难的任务之⼀，就是设计有状态分布式组件的部署体系结构。 由于⽆状态组件可能没有预定义的启动顺序、集群要求、点对点 TCP 连接、唯⼀的⽹络标识符、正常 的启动和终⽌要求等，因此可以很容易地进⾏容器化。诸如数据库，⼤数据分析系统，分布式 key/value 存储和 message brokers 可能有复杂的分布式体系结构，都可能会⽤到上述功能。为 此， Kubernetes 引⼊了 StatefulSet 资源来⽀持这种复杂的需求。



StatefulSet 类似于 ReplicaSet ，但是它可以处理 Pod 的启动顺序，保留每个 Pod 的状态设置唯 ⼀标识，同时具有以下功能：

- 稳定的、唯⼀的⽹络标识符 

- 稳定的、持久化的存储 

- 有序的、优雅的部署和缩放 

- 有序的、优雅的删除和终⽌ 

- 有序的、⾃动滚动更新



3.1 创建StatefulSet之前先准备两个1G的存储卷(PV)

[pv-demo.yaml](attachments/253176E6E4AC4C95AE1B9838DCBF82F0pv-demo.yaml)

```javascript
# pv-demo.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
  labels:
    release: stable
spec:
  # 存储容量
  capacity:
    storage: 1Gi
  # 访问模式
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: /tmp/data

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
  labels:
    release: stable
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: /tmp/data 
```



```javascript
kubectl create -f pv-demo.yaml
# 看到成功创建了两个PV对象, 状态是Available
kubectl get pv
```



3.2 创建StatefulSet

使⽤ StatefulSet 来创建⼀个 Nginx 的 Pod，对于这种类型的资源，⼀般是通过创建⼀ 个 Headless Service 类型的服务来暴露服务，将 ClusterIP 设置为 None 就是Headless Service，也就是说没有ClusterIP，不需要ClusterIP来做负载均衡。

[statefulset-demo.yaml](attachments/59679D55ED3B4F958EB9920D3FC6ADEDstatefulset-demo.yaml)

```javascript
# statefulset-demo.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
  - port: 80
    name: nginx-service-port
  # 把clusterIP设置为None,这就是一个Headless Service类型的服务
  clusterIP: None
  selector:
    # 必须要满足下面两个label,才能匹配到这个service中
    app: nginx
    role: statefulset
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  # 这里的值和上面定义的Service的name的值一样
  serviceName: nginx
  replicas: 2
  selector:
    matchLabels:
       app: nginx
       role: statefulset
  template:
    metadata:
      labels:
        # 这里必须要写下面两个label才能匹配到上面的Service中
        app: nginx
        role: statefulset
    spec:
      containers:
      - name: nginx
        # 这里不直接使用nginx镜像,因为要利用这个镜像里面的一些命令来做些事情，原生的nginx1.7.9里面有些命令没有，所以使用这个镜像
        image: cnych/nginx-slim:0.8
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: nginx-pod-port
        volumeMounts:
        - name: nginx-path
          mountPath: /usr/share/nginx/html
  # volumeClaimTemplates相当于PVC声明的模板,这个属性它会自动声明一个PVC对象，然后和上面创建的PV关联
  # volumeClaimTemplates 和 template 在同一级,这个模板实际上就是volumeClaim的一个模板
  volumeClaimTemplates:
  - metadata:
      # 这里的name的值要和volumeMounts的name一致，相当于是对volumeMounts进行声明
      # 把"nginx-path"这个volumeMounts和PVC进行了关联, PVC又和PV进行关联, PV也会自动去匹配，有可能匹配到pv001，也有可能匹配到pv002
      name: nginx-path
    spec:
      # 和PV中定义的 accessModes 中保持一致
      accessModes: [ "ReadWriteOnce" ]
      # 资源 
      resources:
        # 请求存储空间
        requests:
          # 一个PVC只能和一个PV进行绑定
          storage: 1Gi
```



```javascript
// 在创建之前准备两个终端A和B
// 先在终端B运行如下命令, "-l"表示根据label过滤,"-w"表示会一直等待Pod出现
kubectl get pods -l role=statefulset -w

// 然后在终端A执行创建操作, 然后观察终端B
kubectl create -f statefulset-demo.yaml

// 现在可以 检查 Pod 的顺序索引, 从终端B可以观察到Pod的创建顺序
// web-0变成running后,web-1才开始pending,这就是StatefulSet下控制的pod的一个特性
// 对于⼀个拥有 N 个副本的 StatefulSet，Pod 被部署时是按照 {0..N-1}的序号顺序创建的
// 注意: 在 web-0 Pod 处于 Running 和 Ready 状态后 web-1 Pod 才会被启动

// 每个Pod都运⾏了⼀个NGINX服务.获取Service和StatefulSet来验证是否成功创建了它们
// 从下面可以看到nginx这个Service的CLUSTER-IP为None,它是一个Headless Service
kubectl get service nginx
[root@centos7 daemonset-statefull]# kubectl get service nginx
NAME    TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
nginx   ClusterIP   None         <none>        80/TCP    17m
[root@centos7 daemonset-statefull]# kubectl get statefulset web
NAME   READY   AGE
web    2/2     19m
[root@centos7 daemonset-statefull]#

// 删除StatefulSet下的两个Pod,观察删除的顺序
kubectl get pods -l role=statefulset 
# 在终端A删除这个两个Pod,然后在终端B观察
kubectl delete pods -l role=statefulset
// 通过观察发现也是先删除web-0,再删除web-1
// 然后自动重启,仍然是先启动web-0,直到web-0是running状态,web-1才是Pending状态.

```



如同 StatefulSets 概念中所提到的，StatefulSet 中的 Pod 拥有⼀个具有稳定的、独⼀⽆⼆的身份标 志。这个标志基于 StatefulSet 控制器分配给每个 Pod 的唯⼀顺序索引。Pod 的名称的形式为 <statefulset name>-<ordinal index> 。上面创建的 StatefulSet 拥有两个副本，所以它创建了两个 Pod：web-0 和 web-1。



使⽤稳定的⽹络身份标识

```javascript

kubectl get statefulset
kubectl get svc
# 运行下面命令可以发现nginx这个Service的Endpoints有两个地址,这就是StatefulSet下的两个Pod的地址
kubectl describe svc nginx
kubectl get pods -l role=statefulset -o wide

// 每个Pod都拥有⼀个基于其顺序索引的稳定的主机名。
// 使⽤ kubectl exec 在每个 Pod 中执⾏ hostname

// 方式一:运行如下脚本
[root@centos7 daemonset-statefull]# for i in 0 1; do kubectl exec web-$i -- sh -c 'hostname'; done
web-0
web-1

// 方式二：
[root@centos7 daemonset-statefull]# kubectl exec web-0  -it -- bash
root@web-0:/# echo hostname 
hostname
root@web-0:/# exit
exit
[root@centos7 daemonset-statefull]# kubectl exec web-1  -it -- bash
root@web-1:/# echo hostname
hostname
root@web-1:/# exit
exit
[root@centos7 daemonset-statefull]#

// 把两个Pod删掉,它们会自动重启
kubectl get pods -l role=statefulset 
kubectl delete pods -l role=statefulset

// 重启过程仍然是先启动web-0,直到web-0是running状态,web-1才是Pending状态
// 重启后web-0和web-1的hostname仍然不变
// 所以说StatefulSet下的Pod是稳定的,而且网络标识唯一,也是稳定的
[root@centos7 daemonset-statefull]# kubectl exec web-0  -it -- bash
root@web-0:/# echo hostname 
hostname
root@web-0:/# exit
exit
[root@centos7 daemonset-statefull]# kubectl exec web-1  -it -- bash
root@web-1:/# echo hostname
hostname
root@web-1:/# exit
exit
[root@centos7 daemonset-statefull]#

```



StatefulSet下面的Pod删除自动重启后，可以看到Pod 的序号、主机名、SRV 条⽬和记录名称没有改变，但和 Pod 相关联的 IP 地址可能会发⽣改变。所以说这就是为什么不要在其他应⽤中使⽤ StatefulSet 中的 Pod 的 IP 地址进⾏连接， 这点很重要。

⼀般情况下我们直接通过 SRV 记录(格式为：$PodName.$ServiceName)连接就⾏，因为他们是稳定的、唯一的。比如在这里就是使用 web-0.nginx  和 web-1.nginx，并且当 Pod 的状态变为 Running 和 Ready 时，应⽤就能够通过 web-0.nginx 和 web-1.nginx 发现它们的地址，然后直接找到 StatefulSet下的Pod了。



```javascript
// 从以下两个名称得知访问Pod的名字为 web-0.nginx 和 web-1.nginx
kubectl get pods -l role=statefulset -o wide
kubectl get svc

# 使⽤ kubectl run 运⾏⼀个提供 nslookup 命令的容器
# 通过对 Pod 的主机名执⾏ nslookup,检查他们在集群内部的 DNS 地址
[root@centos7 daemonset-statefull]# kubectl run -i --tty --image busybox dns-test --restart=Never --rm /bin/sh
If you don't see a command prompt, try pressing enter.
/ # nslookup web-0.nginx
// ....省略
/ # nslookup web-1.nginx
// ....省略

```



headless service 的 CNAME 指向 SRV 记录（记录每个 Running 和 Ready 状态的 Pod）。SRV 记录 指向⼀个包含 Pod IP 地址的记录表项。







查看 PV、PVC的最终绑定情况：

```javascript
// 可以看到PV状态都是Bound 
// CLAIM就是声明这个PV被哪个命名空间下的Pod的volume绑定.格式: $namespaceName/$volumeMountsName-$PodName
[root@centos7 daemonset-statefull]# kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS   REASON   AGE
pv001   1Gi        RWO            Recycle          Bound    default/nginx-path-web-0                           135m
pv002   1Gi        RWO            Recycle          Bound    default/nginx-path-web-1                           135m
// 从下面可以看到PVC的NAME和PV的CLAIM值一样,说明PV和PVC关联了.相当于也是声明
[root@centos7 daemonset-statefull]# kubectl get pvc
NAME               STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nginx-path-web-0   Bound    pv001    1Gi        RWO                           90m
nginx-path-web-1   Bound    pv002    1Gi        RWO                           89m
[root@centos7 daemonset-statefull]#
```



4. 总结

StatefulSet 还拥有其他特性，但是在实际的项⽬和线上的环境中，还是很少会去直接通过 StatefulSet 来部署 这种有状态的服务，除⾮能够完全 hold 住，对于⼀些特定的服务可能会使⽤更加⾼级的 Operator 来部署，⽐如 etcd-operator、prometheus-operator 等等，这些应⽤都能够很好的来管理有状态的服务，⽽不是单纯的使⽤⼀个 StatefulSet 来部署⼀个 Pod就⾏，因为对于有状态的应⽤最重要的还是数据恢复、故障转移等等。

分布式有状态应用要保证应用挂了能及时恢复，数据不丢失等， 所以说这种应用是部署的一个难点，但现在有很多第三方的，比如 Operator 是专门来解决这种特定的一些 weakness 服务场景.

对于 StatefulSet 这种控制器要了解使用场景、基本概念、使用方法，特别是名字的唯一性这样的特点。

还可以额外了解Operator 实现的原理，因为可以从代码的层面上去实现有状态服务它们的一些内部机制，比如说故障转移，分布式集群管理之类的。



PV、PVC、Operator这些才是真正在线上使用到的。

