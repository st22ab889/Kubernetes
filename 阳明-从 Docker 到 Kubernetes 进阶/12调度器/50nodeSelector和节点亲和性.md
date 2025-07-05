1. Kubernetes 亲和性调度介绍

⼀般情况下部署的 Pod 是通过集群的⾃动调度策略来选择节点，默认情况下调度器考虑的是资源⾜够并且负载尽量平均，但有时候需要能够更加细粒度的控制 Pod 的调度，⽐如内部的⼀些服务 gitlab 之类的也是跑在 Kubernetes 集群上的，此时就不希望对外的⼀些服务和内部的服务跑在同⼀个节点上了，避免内部服务对外部的服务产⽣影响；但有时候服务之间交流⽐较频繁，⼜希望能够将这两个服务的 Pod 调度到同⼀个节点上。这就需要⽤到 Kubernetes  中的⼀个概念：亲和性和反亲和性。

 亲和性有分成节点亲和性( nodeAffinity )和 Pod 亲和性( podAffinity )。





2. nodeSelector

在了解亲和性之前，先了解⼀个⾮常常⽤的调度⽅式：nodeSelector。label 是 kubernetes 中⼀个⾮常重要的概念，⽤户可以⾮常灵活的利⽤ label 来管理集群中的资源, 比如最常⻅的⼀个就是 service 通过匹配 label 去匹配 Pod 资源，⽽ Pod 的调度也可以根据节点 的 label 来进⾏调度。



第一步: 给 node 绑定 label

```javascript
// 可以通过下⾯的命令查看 node 的 label：
kubectl get nodes --show-labels

// 给节点centos7.node增加⼀个 demo=node02 的标签
[root@centos7 aaron]# kubectl label nodes centos7.node demo=node02
node/centos7.node labeled
[root@centos7 aaron]# kubectl get nodes --show-labels
NAME             STATUS   ROLES                  AGE    VERSION   LABELS
centos7.master   Ready    control-plane,master   102d   v1.22.1   beta.kubernetes.io/arch=amd64,......
centos7.node     Ready    <none>                 102d   v1.22.1   beta.kubernetes.io/arch=amd64,demo=node02,......
```

当 node 被打上了一些标签后，在调度的时候就可以使⽤这些标签了，只需要在 Pod 的 spec 字段中添加 nodeSelector 字段，字段的值是需要被调度的节点的 label 即可。⽐如，下⾯的 Pod 要强制调度到 centos7.node 这个节点，就可以使⽤ nodeSelector 来表示.



第二步: 给 pod 指定 node 的 label

[node-selector-demo.yaml](attachments/FC3630F8396B47BDA4FF1A23B0D5C9E8node-selector-demo.yaml)

```javascript
# node-selector-demo.yaml
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
  nodeSelector:
    # 把 Pod 调度到具有 demo=node02 这个标签的节点上
    demo: node02
```



```javascript
[root@centos7 50]# kubectl create -f node-selector-demo.yaml
pod/test-busybox created

// 通过 describe 命令查看调度结果
[root@centos7 50]# kubectl describe pod test-busybox
......
Node:         centos7.node/192.168.32.101
......
Node-Selectors:              demo=node02
......
// 从Events信息可以看出 Pod 通过默认的 default-scheduler 调度器被绑定到了 centos7.node 节点
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  27s   default-scheduler  Successfully assigned default/test-busybox to centos7.node
......
```



注意： nodeSelector 属于强制性的，如果⽬标节点没有可⽤的资源，Pod 就会⼀直处于 Pending 状态，这就是 nodeSelector 的⽤法。



nodeSelector 的⽅式⽐较直观，但是还够灵活，控制粒度偏⼤，更加灵活的⽅式是节点亲和性( nodeAffinity )。





3. 亲和性和反亲和性调度

从 kubernetes 调度器的调度流程可知，默认的调度器使⽤时经过了 predicates 和 priorities 两个阶段，但在实际的⽣产环境中，往往需要根据⼀些实际需求来控制 pod 的调度，这就需要⽤到 nodeAffinity(节点亲和性)、podAffinity(pod 亲和性) 以及 podAntiAffinity(pod 反亲和性)。



亲和性调度可以分成软策略和硬策略两种⽅式:

- 软策略 就是如果你没有满⾜调度要求的节点的话，pod 就会忽略这条规则，继续完成调度过程， 说⽩了就是满⾜条件最好了，没有的话也⽆所谓了的策略。

- 硬策略 就⽐较强硬了，如果没有满⾜条件的节点的话，就不断重试直到满⾜条件为⽌，简单说就 是你必须满⾜我的要求，不然我就不⼲的策略。



对于亲和性和反亲和性都有这两种规则可以设置：

- 软策略：preferredDuringSchedulingIgnoredDuringExecution 

- 硬策略：requiredDuringSchedulingIgnoredDuringExecution





4. nodeAffinity（节点亲和性）

节点亲和性主要是⽤来控制 pod 要部署在哪些主机上，以及不能部署在哪些主机上的。它可以进⾏⼀ 些简单的逻辑组合，不只是简单的相等匹配。



如下示例: ⽤⼀个 Deployment 来管理3个 pod 副本，来控制这些 pod 的调度

[node-affinity-demo.yaml](attachments/6235270AAF4F49F4A1AAE31ED9CB3995node-affinity-demo.yaml)

```javascript
# node-affinity-demo.yaml
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
        nodeAffinity:
          # 硬策略
          requiredDuringSchedulingIgnoredDuringExecution:
            # 如果 nodeSelectorTerms 下⾯有多个选项的话，满⾜任何⼀个条件就可以
            nodeSelectorTerms:
            # 如果 matchExpressions 有多个选项的话，则必须同时满⾜这些条件才能正常调度 POD
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - node03
          # 软策略
          preferredDuringSchedulingIgnoredDuringExecution: 
          - weight: 1
            preference:
              matchExpressions:
              - key: demo
                operator: In
                values:
                - node02
```

上⾯的 Deployment 下的 pod ⾸先是要求不能运⾏在 node03 这个节点上，如果有个节点存在 demo=node02 这个标签，就优先调度到这个节点上。

```javascript
// 节点列表信息
[root@centos7 aaron]# kubectl get nodes --show-labels
NAME             STATUS   ROLES                  AGE    VERSION   LABELS
centos7.master   Ready    control-plane,master   102d   v1.22.1   beta.kubernetes.io/arch=amd64,......
centos7.node     Ready    <none>                 102d   v1.22.1   beta.kubernetes.io/arch=amd64,demo=node02,......

// centos7.node 节点有 demo=node02 这样的label,按要求会优先调度到这个节点
[root@centos7 50]# kubectl create -f node-affinity-demo.yaml
deployment.apps/affinity created
[root@centos7 50]# kubectl get pods -l app=affinity -o wide
NAME                        READY   STATUS    RESTARTS   AGE   IP               NODE           NOMINATED NODE   READINESS GATES
affinity-5bd9fbbfcf-7kdcq   1/1     Running   0          12m   10.244.189.149   centos7.node   <none>           <none>
affinity-5bd9fbbfcf-l7r65   1/1     Running   0          12m   10.244.189.188   centos7.node   <none>           <none>
affinity-5bd9fbbfcf-pb7nr   1/1     Running   0          12m   10.244.189.173   centos7.node   <none>           <none>
```



从结果可以看出 pod 都被部署到了centos7.node 这个节点，其他节点没有部署 pod，这⾥的匹配逻辑是 label 的值在某个列表中，现在 Kubernetes 提供的操作符有下⾯的⼏种：

- In：label 的值在某个列表中

- NotIn：label 的值不在某个列表中

- Gt：label 的值⼤于某个值

- Lt：label 的值⼩于某个值

- Exists：某个 label 存在

- DoesNotExist：某个 label 不存在



注意:如果 nodeSelectorTerms 下⾯有多个选项的话，满⾜任何⼀个条件就可以了，如果 matchExpressions 有多个选项的话，则必须同时满⾜这些条件才能正常调度 POD。