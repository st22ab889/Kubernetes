1. PVC的使用

真正使⽤的时候是使⽤的 PVC，而不是PV。就类似于我们的服务是通 过 Pod 来运⾏的，⽽不是 Node，只是 Pod 跑在 Node 上⽽已。



1.1  准备工作

必须在所有节点都 安装 nfs 客户端，否则可能会导致 PV 挂载不上的问题.



1.2 PV

在第35节已经创建了一个PV，创建的YAML文件如下:

[pv-nfs-demo.yaml](attachments/628E4C2E06954C67B6411D01700F162Epv-nfs-demo.yaml)

```javascript
# pv-nfs-demo.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  # 回收策略
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    # nfs服务所在的主机IP
    server: 192.168.32.100
    # nfs共享数据目录
    path: /data/k8s
```



```javascript
[root@centos7 ~]# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                      STORAGECLASS   REASON   AGE
pv-nfs   1Gi        RWO            Recycle          Available                                                      17h
// 可以看到当前 pv-nfs 是在 Available 的⼀个状态.
// 这个时候 PVC 可以和这个 PV 进⾏绑定 
```







1.3 新建PVC

[pvc-nfs-demo.yaml](attachments/CCABACAD8D5443B79C620D7A3E75B1DFpvc-nfs-demo.yaml)

```javascript
# pvc-nfs-demo.yaml   声明⽅法⼏乎和 PV ⼀样
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-nfs
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```



```javascript
[root@centos7 aaron]# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                      STORAGECLASS   REASON   AGE
pv-nfs   1Gi        RWO            Recycle          Available                                                      17h
[root@centos7 pv-pvc]# kubectl create -f pvc-nfs-demo.yaml 
persistentvolumeclaim/pvc-nfs created
[root@centos7 pv-pvc]# kubectl get pvc
NAME               STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs            Bound    pv-nfs   1Gi        RWO                           60s
[root@centos7 pv-pvc]# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS   REASON   AGE
pv-nfs   1Gi        RWO            Recycle          Bound    default/pvc-nfs                                    17h

// pvc-nfs 创建成功了, 状态是 Bound 状态, PV 也变为 Bound 状态, 
// 并且PV的声明是 default/pvc-nfs，表示 就是 default 命名空间下⾯的 pvc-nfs
// 说明  pvc-nfs这个PVC 和 pv-nfs这个PV 绑定成功了
```



在 pvc-nfs这个PVC 中并没有指定关于 pv 的什么标志，它们之间的关联是系统⾃动去匹配的，系统会根据声明要求去查找处于 Available 状 态的 PV，如果没有找到的话那么我们的 PVC 就会⼀直处于 Pending 状态，找到了的话当然就会把当 前的 PVC 和⽬标 PV 进⾏绑定，这个时候状态就会变成 Bound 状态了.



2. PVC和PV关联的问题



2.1  PVC多条件匹配PV

步骤1： 

[pvc2-nfs-demo.yaml](attachments/69F1210684D446C695DF22874E14A29Dpvc2-nfs-demo.yaml)

```javascript
# pvc2-nfs-demo.yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc2-nfs
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  selector:
    # 指定PVC去匹配一个"app=nfs"的PV
    matchLabels:
      app: nfs
```

这⾥的PVC声明⼀个 PV 资源的请求，邀请访问模式是 ReadWriteOnce，存储容量是 2Gi，还 要求匹配具有标签 app=nfs 的PV



步骤2 

```javascript
[root@centos7 pv-pvc]# kubectl create -f pvc2-nfs-demo.yaml 
persistentvolumeclaim/pvc2-nfs created
[root@centos7 pv-pvc]# kubectl get pvc
NAME               STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc2-nfs           Pending                                                     26s
```

可以看出当前系统并没有合适PV给PVC匹配,所以新建的 PVC 是没办法 选择到合适的 PV 的，所以状态也是 Pending 状态.



步骤3

新创建一个PV,访问模式是 ReadWriteOnce，存储容量是 2Gi

[pv-nfs-demo-v1.yaml](attachments/FE9DB172F32049D3B10BC395024FD39Epv-nfs-demo-v1.yaml)

```javascript
# pv-nfs-demo-v1.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs-v1
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 192.168.32.100
    path: /data/k8s
```



```javascript
[root@centos7 pv-pvc]# kubectl create -f pv-nfs-demo-v1.yaml 
persistentvolume/pv-nfs-v1 created
[root@centos7 pv-pvc]# kubectl get pvc
NAME               STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc2-nfs           Pending                                                     12m
[root@centos7 pv-pvc]# kubectl get pvc
NAME               STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc2-nfs           Pending                                                     12m
[root@centos7 pv-pvc]# kubectl get pv
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                      STORAGECLASS   REASON   AGE
pv-nfs-v1   2Gi        RWO            Recycle          Available                                                      2m13s
```



可以看出来新建的PV虽然满足了 ReadWriteOnce，存储容量是 2Gi，但是仍然不能和PVC绑定，因为 PVC  要求匹配具有标签 app=nfs 的PV



步骤4 

新创建一个PV,访问模式是 ReadWriteOnce，存储容量是 2Gi，并且PV的标签是 app=nfs 

[pv-nfs-demo-v2.yaml](attachments/5B2E86A801B849A382AFD3E679C05762pv-nfs-demo-v2.yaml)

```javascript
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs-v2
  labels:
    app: nfs
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 192.168.32.100
    path: /data/k8s
```



```javascript
[root@centos7 pv-pvc]# kubectl create -f pv-nfs-demo-v2.yaml 
persistentvolume/pv-nfs-v2 created
[root@centos7 pv-pvc]# kubectl get pv
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                      STORAGECLASS   REASON   AGE
pv-nfs-v2   2Gi        RWO            Recycle          Bound       default/pvc2-nfs                                   10s
[root@centos7 pv-pvc]# kubectl get pvc
NAME               STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc2-nfs           Bound    pv-nfs-v2   2Gi        RWO                           20m
```



新建的 pv-nfs-v2 这个 PV 很快就变成了 Bound 状态，对应的 PVC 是 default/pvc2-nfs，证 明 pvc2-nfs 终于找到合适的 PV 进⾏绑定上了.



2.2  PVC匹配条件之  capacity storage

现在假如PVC和PV除了storage,其它条件都一样:

- 如果PVC的 storage 声明容量是2Gi， PV的容量是 大于等于2Gi, PVC 和 PV 是可以绑定成功的。假如PVC声明的容量是2Gi, 但是PV的容量是3Gi，绑定后查看 PVC 的 CAPACITY 会发现是3Gi，也就是说在PVC中声明的2Gi是没什么用的,PV是3Gi, PVC中声明2Gi是不行的，必须得使⽤3Gi。

- 如果PVC的 storage 声明容量是2Gi， PV的容量是 小于2Gi, PVC 和 PV 是不能绑定成功的。

总结： PV的容量可以等于或大于PVC声明的容量,但是不能小于PVC声明的容量。





3. 使⽤ PVC

这⾥使⽤ nginx 镜像，将容器的 /usr/share/nginx/html ⽬录通过 volume 挂载到名为 pvc-nfs 的 PVC 上⾯，然后创建⼀个 NodePort 类型的 Service 来暴露服务。

[pvc-nfs-deploy.yaml](attachments/5073D312257F4931838C75E39E67D6ABpvc-nfs-deploy.yaml)

```javascript
# pvc-nfs-deploy.yaml
# PV
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
  labels:
    app: pv-nfs
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 192.168.32.100
    path: /data/k8s

# PVC
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-nfs
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      # 因为PV的容量大于PVC声明的容量,所以能绑定成功
      storage: 1Gi
  selector:
    matchLabels:
      app: pv-nfs

# Deployment
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pvc-nfs-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pvc-nfs-pod
  template:
    metadata:
      labels:
        app: pvc-nfs-pod
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: nginx-port
        volumeMounts:
        - name: pvc-nfs-volume
          # 如果不加subPath,容器中的数据是直接放到共享数据⽬录根⽬录下⾯,
          # 如果后面有新的容器的数据⽬录也挂载到nfs,这时候就有冲突
          # 为了区分, 在 Pod 中使⽤属性 subPath,最终是把共享目录下的nginx-pvc-test目录挂载到"/usr/share/nginx/html"
          # "nginx-pvc-test" 这个目录会被自动在共享数据⽬录根⽬录下⾯创建
          subPath: nginx-pvc-test 
          mountPath: /usr/share/nginx/html
      volumes:
      - name: pvc-nfs-volume
        # 和PVC进行绑定
        persistentVolumeClaim:
          claimName: pvc-nfs

# Service
---
apiVersion: v1
kind: Service
metadata:
  name: pvc-nfs-svc
  labels:
    app: pvc-nfs-svc
spec:
  type: NodePort
  selector:
    app: pvc-nfs-pod  
  ports:
  - port: 80
    targetPort: nginx-port
```

注意 Pod 中新属性 subPath 的用法，如果不加subPath，容器中的数据是直接放到共享数据⽬录根⽬录下⾯, 如果后面有新的容器的数据⽬录也挂载到nfs,这时候就有冲突。为了区分, 在 Pod 中使⽤属性 subPath，系统会自动在共享目录下创建 subPath 属性指定的这个目录, 最终是 subPath 属性指定的这个目录挂载到容器中。



```javascript

[root@centos7 pv-pvc]# kubectl delete -f

[root@centos7 pv-pvc]# kubectl create -f pvc-nfs-deploy.yaml 
persistentvolume/pv-nfs created
persistentvolumeclaim/pvc-nfs created
deployment.apps/pvc-nfs-deploy created
service/pvc-nfs-svc created

[root@centos7 pv-pvc]# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
pv-nfs   2Gi        RWO            Recycle          Bound    default/pvc-nfs                           17m

[root@centos7 pv-pvc]# kubectl get pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs   Bound    pv-nfs   2Gi        RWO                           16m

[root@centos7 pv-pvc]# kubectl get deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
pvc-nfs-deploy   3/3     3            3           15m

[root@centos7 pv-pvc]# kubectl get pods
NAME                              READY   STATUS      RESTARTS       AGE
pvc-nfs-deploy-85ff7db554-6949m   1/1     Running     0              15m
pvc-nfs-deploy-85ff7db554-hf6z2   1/1     Running     0              15m
pvc-nfs-deploy-85ff7db554-lgf4s   1/1     Running     0              15m

// 因为容器⽬录"/user/share/nginx/html"挂载到了nfs共享目录根目录下的nginx-pvc-test目录
// 所以要在"nfs共享目录根目录下的nginx-pvc-test目录"创建一个index.html文件
// 有了"index.html"文件nginx才能正常访问
[root@centos7 pv-pvc]# echo hello kubernetes >> /data/k8s/nginx-pvc-test/index.html

[root@centos7 pv-pvc]# kubectl get svc
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
pvc-nfs-svc   NodePort    10.102.241.181   <none>        80:31972/TCP     16m
// 可以看到Service暴露的端口为31972
// 在浏览器中访问"http://192.168.32.100:31972"或"http://192.168.32.101:31972"
// 主页出现刚刚创建的"index.html"页面
```





验证数据是否会丢失:

```javascript
// 删掉 pvc-nfs-deploy 这个deployment, 下⾯管理的3个 Pod 也会被⼀起删除掉

// 可以看到"/data/k8s/nginx-pvc-test/index.html"仍然存在。如果不在了, ⽤PVC、PV、nfs也就没有任何意义了

// 再重新创建 pvc-nfs-deploy 这个deployment
//由于Service 没有删除掉，还是可以通过31972这个端口访问,证明数据持久化成功

// 在浏览器中访问"http://192.168.32.100:31972"或"http://192.168.32.101:31972"
```





注意事项

实际使⽤的⼯程中，很有可能出现这种情况，在正常使用的时候把PV或PVC删了,持久化的数据是否还存在。

```javascript
//示例1: 先删除PV, 看持久化的数据是否还在

[root@centos7 pv-pvc]# kubectl delete pv pv-nfs
persistentvolume "pv-nfs" deleted
[root@centos7 pv-pvc]# kubectl get pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs   Bound    pv-nfs   2Gi        RWO                           60m
// 可以看到pvc-nfs这个PVC仍然是Bound的状态,也就意味着还可以正常使⽤这个PVC
// 如果有⼀个新的 Pod 来使⽤这个 PVC 会是怎样的情况？
// 如有 Pod 正在使⽤此 pvc-nfs 这个 PVC 的话,那么新建的 Pod 仍可使⽤
// 如⽆ Pod 使⽤, 则创建 Pod 挂载此 PVC 时会出现失败


[root@centos7 pv-pvc]# kubectl delete pvc pvc-nfs
persistentvolumeclaim "pvc-nfs" deleted
[root@centos7 pv-pvc]# kubectl get pvc
NAME      STATUS        VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs   Terminating   pv-nfs   2Gi        RWO                           68m
// 删掉pvc-nfs这个PVC后, 再查看发现这个PVC状态变为"Terminating",但浏览器仍可正常访问nginx
// 为什么删掉PV和PVC后,仍可以正常访问数据,因为还有Pod进行关联,此时它们并没有被真正删除

[root@centos7 pv-pvc]# kubectl delete deployment pvc-nfs-deploy
deployment.apps "pvc-nfs-deploy" deleted
[root@centos7 pv-pvc]# kubectl get pv
No resources found
[root@centos7 pv-pvc]# kubectl get pvc
No resources found in default namespace.
// 删除deployment,意味着它下面管理的Pod也删除了
// 没有Pod关联后,发现PV和PVC也随即被删除了

[root@centos7 pv-pvc]# ls /data/k8s/
// 并且nfs共享目录根目录下的 subPath 属性指定的目录也被删除了
// 这是因为在PV和PVC中persistentVolumeReclaimPolicy属性的值为Recycle,当删除PVC就会回收数据

```





```javascript
//示例2: 先删除 pvc-nfs-deploy 这个deployment, 再删除 pvc-nfs 这个PVC,看持久化数据是否还在

// 现在恢复到最初始状态,出现错误是因为之前的Service并没有被删除
// 把PV、PVC、Deployment都添加回来
[root@centos7 pv-pvc]# kubectl create -f pvc-nfs-deploy.yaml 
persistentvolume/pv-nfs created
persistentvolumeclaim/pvc-nfs created
deployment.apps/pvc-nfs-deploy created
Error from server (AlreadyExists): error when creating "pvc-nfs-deploy.yaml": services "pvc-nfs-svc" already exists
root@centos7 pv-pvc]# echo hello kubernetes >> /data/k8s/nginx-pvc-test/index.html

//  先删除 pvc-nfs-deploy 这个deployment, 再删除 pvc-nfs 这个PVC
[root@centos7 pv-pvc]# kubectl delete deployment pvc-nfs-deploy
deployment.apps "pvc-nfs-deploy" deleted
[root@centos7 pv-pvc]# kubectl delete pvc pvc-nfs
persistentvolumeclaim "pvc-nfs" deleted
[root@centos7 pv-pvc]# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv-nfs   2Gi        RWO            Recycle          Available                                   6m39s
[root@centos7 pv-pvc]# ls /data/k8s/
[root@centos7 pv-pvc]# 
// 看到pv-nfs这个PV的状态已经变成了Available状态,表示PVC已经被释放,现在可以被重新绑定
// 由于设置的PV的回收策略是Recycle,所以nfs的共享数据目录下已经没有数据,这是因为把PVC给删除掉了,然后回收了数据
```



要注意，并不是所有的存储后端的表现结果都是这样的，这⾥使⽤的是 nfs，其他 存储后端肯能会有不⼀样的结果。 在使⽤ PV 和 PVC 的时候⼀定要注意这些细节，不然⼀不⼩⼼就把数据搞丢了。