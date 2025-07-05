

1. podAffinity（Pod 亲和性）

pod 亲和性主要解决 pod 可以和哪些 pod 部署在同⼀个拓扑域中的问题(其中拓扑域⽤主机标签实现，可以是单个主机，也可以是多个主机组成的 cluster、zone 等等)，⽽ pod 反亲和性主要是解决 pod 不能和哪些 pod 部署在同⼀个拓扑域中的问题，它们都是处理的 pod 与 pod 之间的关系。⽐如⼀ 个 pod 在A节点上，那么另一个也得在A节点；或者一个 pod 在A节点上，另一个 pod 不能在A节点上。



由于本地只有⼀个集群，并没有区域或者机房的概念，所以直接使⽤主机名来作为拓扑域，把 pod 创建在同⼀个主机上⾯。

```javascript
[root@centos7 50]# kubectl get node -o wide
NAME             STATUS   ROLES                  AGE    VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION           CONTAINER-RUNTIME
centos7.master   Ready    control-plane,master   102d   v1.22.1   192.168.32.100   <none>        CentOS Linux 7 (Core)   3.10.0-1160.el7.x86_64   docker://20.10.8
centos7.node     Ready    <none>                 102d   v1.22.1   192.168.32.101   <none>        CentOS Linux 7 (Core)   3.10.0-1160.el7.x86_64   docker://20.10.8

[root@centos7 aaron]# kubectl get nodes --show-labels
NAME             STATUS   ROLES                  AGE    VERSION   LABELS
centos7.master   Ready    control-plane,master   102d   v1.22.1   beta.kubernetes.io/arch=amd64,......
centos7.node     Ready    <none>                 102d   v1.22.1   beta.kubernetes.io/arch=amd64,demo=node02,......
```





2. 测试 pod 的亲和性：

第一步:部署一个具有 app=busybox-pod 这个标签的 pod 在 centos7.master 这个节点上

[node-name-demo.yaml](attachments/4D49674223874C57A71D178DB2C247EBnode-name-demo.yaml)

```javascript
# node-name-demo.yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    app: busybox-pod
  name: test-busybox
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox
    imagePullPolicy: Always
    name: test-busybox
  # 把 pod 部署在名为 centos7.master 的节点上
  nodeName: centos7.master
```



```javascript
[root@centos7 51]# kubectl create -f node-name-demo.yaml 
pod/test-busybox created
// 可以看到 pod 运行在 centos7.master 这个节点上
[root@centos7 51]# kubectl get pod -o wide -l app=busybox-pod
NAME           READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
test-busybox   1/1     Running   0          33m   10.244.139.59   centos7.master   <none>           <none>
```



第二步:把 pod 调度到某个指定的主机(节点)上，⾄少有⼀个节点上运⾏了这样一个 pod，这个 pod 具有 app=busybox-pod 这样的label

[node-affinity-demo.yaml](attachments/EB9689BC19C84643B9164C0DED32B8C1node-affinity-demo.yaml)

```javascript
# pod-affinity-demo.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: affinity
  labels:
    app: affinity
spec:
  replicas: 3
  revisionHistoryLimit: 15
  selector:
    matchLabels:
       app: affinity
  template:
    metadata:
      labels:
        app: affinity
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
          name: nginxweb
      affinity:
        # pod 亲和性
        podAffinity:
          # 硬策略
          requiredDuringSchedulingIgnoredDuringExecution:
          # 如果 nodeSelectorTerms 下⾯有多个选项的话，满⾜任何⼀个条件就可以
          - labelSelector:
          # 如果 matchExpressions 有多个选项的话，则必须同时满⾜这些条件才能正常调度 POD
              matchExpressions:
              - key: app
                operator: In
                values:
                - busybox-pod
            # topologyKey 是拓扑的意思,这里指的是一个拓扑域,是指一个范围的概念  
            topologyKey: kubernetes.io/hostname
      # 定义容忍度
      tolerations:
      # Exists表示只要节点有这个污点的key,pod都能容忍,值是什么都行;Equal表示只要节点必须精确匹配污点的key和value才能容忍.
      - operator: "Exists"
         
```

在使⽤ kubeadm 搭建的集群默认给 master 节点添加了⼀个污点标记，所以YAML文件中需要定义容忍度才能将 Pod 调度到 master 节点。



```javascript
[root@centos7 51]# kubectl create -f node-affinity-demo.yaml 
deployment.apps/affinity created

// 查看有 app=busybox-pod 标签的 pod 列表, test-busybox 运行在 centos7.master 节点上
[root@centos7 51]# kubectl get pods -o wide -l app=busybox-pod
NAME           READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
test-busybox   1/1     Running   0          38m   10.244.139.59   centos7.master   <none>           <none>

// 按照亲和性来说,部署的3个 pod 副本也应该运⾏在 centos7.master 节点上
// 可以看到 affinity 这个 deployment 下面的 Pod 也被部署在 centos7.master 这个节点上
[root@centos7 51]# kubectl get pods -o wide -l app=affinity
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
affinity-776b794497-cvrpg   1/1     Running   0          14m   10.244.139.27   centos7.master   <none>           <none>
affinity-776b794497-l4s4n   1/1     Running   0          14m   10.244.139.12   centos7.master   <none>           <none>
affinity-776b794497-vjsnr   1/1     Running   0          14m   10.244.139.8    centos7.master   <none>           <none>

```



第三步: 把 test-busybox 这个 pod 和 affinity 这个 Deployment 都删除，然后重新创建 affinity 这个Deployment ，看能否正常调度.

```javascript
[root@centos7 51]# kubectl delete pod test-busybox
pod "test-busybox" deleted
[root@centos7 51]# kubectl delete deployment affinity
deployment.apps "affinity" deleted
[root@centos7 51]# kubectl create -f node-affinity-demo.yaml 
deployment.apps/affinity created
[root@centos7 51]# kubectl get pods -o wide -l app=affinity
NAME                        READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
affinity-776b794497-4kcvq   0/1     Pending   0          11s   <none>   <none>   <none>           <none>
affinity-776b794497-7blw4   0/1     Pending   0          11s   <none>   <none>   <none>           <none>
affinity-776b794497-m7cvc   0/1     Pending   0          11s   <none>   <none>   <none>           <none>
[root@centos7 51]# kubectl delete deployment affinity
deployment.apps "affinity" deleted
```

可以看到 affinity 这个 Deployment 的3个pod副本处于 Pending 状态，这是因为现在没有⼀个节点拥有 busybox-pod 这个 label 的 pod，⽽上⾯的调度使⽤的是硬策略，所以不能进⾏调度。



注意：

"pod-affinity-demo.yaml"中的 " topologyKey: kubernetes.io/hostname" 表示使⽤ kubernetes.io/hostname 这个拓扑域，意思就是当前调度的 pod 要和⽬标 的 pod 处于同⼀个主机上⾯，要处于同⼀个拓扑域下⾯，而拓扑域是⽤主机标签实现的。

```javascript
// 可以看到 centos7.master 和 centos7.node 都有 kubernetes.io/hostname 这样的标签
NAME             STATUS   ROLES                  AGE    VERSION   LABELS
centos7.master   Ready    control-plane,master   102d   v1.22.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=centos7.master,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node-role.kubernetes.io/master=,node.kubernetes.io/exclude-from-external-load-balancers=
centos7.node     Ready    <none>                 102d   v1.22.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,demo=node02,kubernetes.io/arch=amd64,kubernetes.io/hostname=centos7.node,kubernetes.io/os=linux
[root@centos7 51]# 

// centos7.master 和 centos7.node 都有 beta.kubernetes.io/os 这样的标签
```

如果把拓扑域改为 beta.kubernetes.io/os，同样的要使当前调度的 pod 要和⽬标的 pod 处于同⼀个拓扑域中，那么当前调度的 pod 和⽬标 pod 所在的节点也都要有 beta.kubernetes.io/os=linux 这样的标签，假如多个节点都有这样的标签，这也就意味着多个节点都在同⼀个拓扑域中，所以 pod 可能会被调度到任何⼀个节点上。





3. podAntiAffinity（pod 反亲和性）

pod 反亲和性是反着来，⽐如⼀个节点上运⾏了某个 pod，那么另一个pod 则希望被调度到其他节点上去。



第一步:部署一个具有 app=busybox-pod 这个标签的 pod 在 centos7.node 这个节点上

[node-name-anti-demo.yaml](attachments/C2427655745E4C378A478F6B936D8FB7node-name-anti-demo.yaml)

```javascript
# node-name-anti-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: busybox-pod
  name: test-busybox
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox
    imagePullPolicy: Always
    name: test-busybox
  # 把 pod 部署在名为 centos7.node 的节点上
  nodeName: centos7.node
  
```



```javascript
[root@centos7 51]# kubectl create -f node-name-anti-demo.yaml 
pod/test-busybox created
// 可以看到 pod 运行在 centos7.node 这个节点上
[root@centos7 51]# kubectl get pod -o wide -l app=busybox-pod
NAME           READY   STATUS    RESTARTS   AGE   IP               NODE           NOMINATED NODE   READINESS GATES
test-busybox   1/1     Running   0          42s   10.244.189.152   centos7.node   <none>           <none>
```



第二步:如果有节点存在 app=busybox-pod 这个标签的 pod, 那么另外的 pod 就调度到其它没有这个标签的节点上, 体现反亲和性

[node-antiaffinity-demo.yaml](attachments/AEDFA1B7187F4218A066E58EDF68EB0Anode-antiaffinity-demo.yaml)

```javascript
# node-antiaffinity-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: affinity
  labels:
    app: affinity
spec:
  replicas: 3
  revisionHistoryLimit: 15
  selector:
    matchLabels:
       app: affinity
  template:
    metadata:
      labels:
        app: affinity
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
          name: nginxweb
      affinity:
        # pod 反亲和性
        podAntiAffinity:
          # 硬策略
          requiredDuringSchedulingIgnoredDuringExecution:
          # 如果 nodeSelectorTerms 下⾯有多个选项的话，满⾜任何⼀个条件就可以
          - labelSelector:
          # 如果 matchExpressions 有多个选项的话，则必须同时满⾜这些条件才能正常调度 POD
              matchExpressions:
              - key: app
                operator: In
                values:
                - busybox-pod
            # topologyKey 是拓扑的意思,这里指的是一个拓扑域,是指一个范围的概念  
            topologyKey: kubernetes.io/hostname
      # 定义容忍度
      tolerations:
      # Exists表示只要节点有这个污点的key,pod都能容忍,值是什么都行;Equal表示只要节点必须精确匹配污点的key和value才能容忍.
      - operator: "Exists"
```

这⾥意思就是如果有节点存在 app=busybox-pod 这样的标签的 pod ，那么另外的 pod 就不要调度到这个节点。上面YAML文件中把 podAntiAffinity 直接改成 podAffinity 就是亲和性，把  podAffinity 改成podAntiAffinity 就是反亲和性。这就是 pod 反亲和性的⽤法。

在使⽤ kubeadm 搭建的集群默认给 master 节点添加了⼀个污点标记，所以YAML文件中需要定义容忍度才能将 Pod 调度到 master 节点。



```javascript
[root@centos7 51]# kubectl create -f node-antiaffinity-demo.yaml 
deployment.apps/affinity created

// 查看有 app=busybox-pod 标签的 pod 列表, test-busybox 运行在 centos7.node 节点上
[root@centos7 51]# kubectl get pods -o wide -l app=busybox-pod
NAME           READY   STATUS    RESTARTS   AGE     IP               NODE           NOMINATED NODE   READINESS GATES
test-busybox   1/1     Running   0          5m10s   10.244.189.152   centos7.node   <none>           <none>

// 按照反亲和性来说,部署的3个 pod 副本应该运⾏在 centos7.master 节点上
// 可以看到 affinity 这个 deployment 下面的 Pod 被部署在 centos7.master 这个节点上
[root@centos7 51]# kubectl get pods -o wide -l app=affinity
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
affinity-789d9777b7-54l89   1/1     Running   0          42s   10.244.139.18   centos7.master   <none>           <none>
affinity-789d9777b7-jtfc5   1/1     Running   0          42s   10.244.139.5    centos7.master   <none>           <none>
affinity-789d9777b7-xf7gr   1/1     Running   0          42s   10.244.139.16   centos7.master   <none>           <none>

[root@centos7 51]# kubectl delete deployment affinity
deployment.apps "affinity" deleted
```





4.污点（taints）与容忍（tolerations）

对于 nodeAffinity ⽆论是硬策略还是软策略⽅式，都是调度 pod 到预期节点上，⽽ Taints 恰好与之相反，如果⼀个节点标记为 Taints ，除⾮ pod 也被标识为可以容忍污点节点，否则该 Taints 节点不会被调度 pod。

⽐如⽤户希望把 Master 节点保留给 Kubernetes 系统组件使⽤，或者把⼀组具有特殊资源预留给某些 pod，则污点就很有⽤，pod 不会再被调度到 taint 标记过的节点。在使⽤ kubeadm 搭建的集群默认就给 master 节点添加了⼀个污点标记，所以平时的 pod 都没有被调度到 master 节点上。

```javascript
 [root@centos7 51]# kubectl get node
NAME             STATUS   ROLES                  AGE    VERSION
centos7.master   Ready    control-plane,master   102d   v1.22.1
centos7.node     Ready    <none>                 102d   v1.22.1

[root@centos7 51]# kubectl describe node centos7.master
......
CreationTimestamp:  Mon, 23 Aug 2021 10:49:17 -0400
// 这里就是 master 节点的污点标记
// noderole.kubernetes.io/master:NoSchedule 表示给 master 节点打了⼀个污点标记
// 污点标记影响的参数是 NoSchedule，表示 pod 不会被调度到标记为 taints 的节点
Taints:             node-role.kubernetes.io/master:NoSchedule
......
[root@centos7 51]# 
```



污点标记影响的参数除了 NoSchedule 外，还有另外两个参数，共如下三个参数：

- PreferNoSchedule ：NoSchedule 的软策略版本，表示尽量不调度到污点节点上去

- NoExecute ：该选项意味着⼀旦 Taint ⽣效，如该节点内正在运⾏的 pod 没有对应 Tolerate 设置，会直接被逐出

- NoSchedule ：表示 pod 不会被调度到标记为 taints 的节点



4.1 给节点污点标记 以及 删除污点标记

```javascript
[root@centos7 51]# kubectl get node
NAME             STATUS   ROLES                  AGE    VERSION
centos7.master   Ready    control-plane,master   102d   v1.22.1
centos7.node     Ready    <none>                 102d   v1.22.1

// 污点标记节点的命令格式: kubectl taint nodes [NodeName] [TaintsFlag]
[root@centos7 51]# kubectl taint nodes centos7.node test=centos7.node:NoSchedule
node/centos7.node tainted

// 查看 centos7.node 节点的污点标记
[root@centos7 51]# kubectl describe node centos7.node
......
Taints:             test=centos7.node:NoSchedule
......

// 删除节点的污点标记,格式如下:
// kubectl taint node [NodeName] [keyName]:NoSchedule-
// kubectl taint node [NodeName] [keyName]:NoExecute-
// kubectl taint node [NodeName] [keyName]:NoSchedule-
// 删除指定key所有的effect
// kubectl taint node [NodeName] [keyName]-
[root@centos7 51]# kubectl taint node centos7.node test:NoSchedule-
node/centos7.node untainted
[root@centos7 51]# kubectl describe node centos7.node | grep Taints
Taints:             <none>
[root@centos7 51]#
```



4.2 使用 Toleration 把 pod 调度到污点节点

如果一个节点被标记成了污点，影响策略是 NoSchedule，只会影响新的 pod 调度，如果仍然希望某个新的 pod 调度到 taint 节点，则必须在 Spec 中做出 Toleration 定义，才能调度到该节点。如下: 将 pod 调度到 master 节点



第一步: 查看 master 节点的污点标记

```javascript
[root@centos7 51]# kubectl describe node centos7.master
......
CreationTimestamp:  Mon, 23 Aug 2021 10:49:17 -0400
// 这里就是 master 节点的污点标记
Taints:             node-role.kubernetes.io/master:NoSchedule
......
```



第二步: 在YAML文件中定义 Toleration 

[taint-toleration-demo.yaml](attachments/0C9F103B7881415ABA45CC8388CFECBCtaint-toleration-demo.yaml)

```javascript
# taint-toleration-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: taint
  labels:
    app: taint
spec:
  replicas: 3
  revisionHistoryLimit: 10
  selector:
    matchLabels:
       app: taint
  template:
    metadata:
      labels:
        app: taint
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - name: http
          containerPort: 80
      # 由于master节点被标记为了污点节点,要使pod能够调度到master节点,就需要增加容忍的声明
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
```



```javascript
[root@centos7 51]# kubectl create -f taint-toleration-demo.yaml 
deployment.apps/taint created

// 可以看到 pod 副本被调度到了 master 节点，这就是容忍的使⽤⽅法
[root@centos7 51]# kubectl get pods -o wide -l app=taint
NAME                     READY   STATUS    RESTARTS   AGE   IP              NODE             NOMINATED NODE   READINESS GATES
taint-85d96c6d85-fmw4j   1/1     Running   0          74s   10.244.139.19   centos7.master   <none>           <none>
taint-85d96c6d85-nxkq8   1/1     Running   0          74s   10.244.139.21   centos7.master   <none>           <none>
taint-85d96c6d85-rzkpc   1/1     Running   0          74s   10.244.139.28   centos7.master   <none>           <none>

[root@centos7 51]# kubectl delete deployment taint
deployment.apps "taint" deleted
[root@centos7 51]# 
```



4.3 tolerations 属性的写法

对于 tolerations 属性的写法，其中的 key、value、effect 与 Node 的 Taint 设置需保持⼀致， 还有以 下⼏点说明：

- 如果 operator 的值是 Exists，则 value 属性可省略

- 如果 operator 的值是 Equal，则表示其 key 与 value 之间的关系是 equal(等于)

- 如果不指定 operator 属性，则默认值为 Equal



另外，还有两个特殊值：

- 空的 key 如果再配合 Exists 就能匹配所有的 key 与 value，也是是能容忍所有 node 的所有 Taints

- 空的 effect 匹配所有的 effect



这就是污点和容忍的使⽤⽅法。