1. PV 都是静态的，就是说我要使⽤⼀个 PVC 的话就必须⼿动去创建⼀个 PV，这种⽅式在很⼤程度上并不能满⾜需求，⽐如有⼀个应⽤需要对存储的并发度要求⽐较⾼，⽽另外⼀个应⽤对读写速度⼜要求⽐ 较⾼，特别是对于 StatefulSet 类型的应⽤简单的来使⽤静态的 PV 就很不合适了，这种情况下就需要⽤到动态 PV，也就是本节的重点 StorageClass。



2. 安装 nfs-client 的⾃动配置程序

要使⽤ StorageClass, 需要安装对应的⾃动配置程序, ⽐如存储后端使⽤的是 nfs, 那么就需要使⽤到⼀个 nfs-client 的⾃动配置程序，也叫它Provisioner，这个程序使⽤已经配置好的 nfs 服务器来⾃动创建持久卷，也就是⾃动创建 PV。

- ⾃动创建的 PV 以 ${namespace}-${pvcName}-${pvName} 这样的命名格式创建在 NFS 服务器上的 共享数据⽬录中 

- ⽽当这个 PV 被回收后会以 archieved-${namespace}-${pvcName}-${pvName} 这样的命名格式存在 NFS 服务器上



在部署 nfs-client 之前，需要先成功安装上 nfs 服务器，然后接下来部署 nfs-client 即可。

```javascript
// 准备nfs服务
// nfs服务已安装在master节点
// IP为 192.168.32.100
// 数据共享目录为 /data/k8s/
```



直接参考 nfs-client 的⽂档进⾏安装,从文档地址中可以看到"retired",说明已经过时了：https://github.com/kubernetes-retired/external-storage



第一步: 配置 Deployment，将⾥⾯的对应的参数替换成⾃⼰的 nfs 配置

https://github.com/kubernetes-retired/external-storage/blob/master/nfs-client/deploy/deployment.yaml

[deployment.yaml](attachments/D86FA17546A545B09B52940BED75AF21deployment.yaml)

```javascript
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      # 这⾥使⽤了⼀个名为 nfs-client-provisioner 的 serviceAccount,所以需要创建⼀个sa,然后绑定上对应的权限
      # 如果不创建SA,Pod不会启动成功.可以先创建Deployment,也可以先创建SA,顺序不重要
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
              # 注意:这里的值要和定义 StorageClass 中的 provisioner 属性的值一样 
            - name: PROVISIONER_NAME
              value: fuseim.pri/ifs
              # nfs服务IP  
            - name: NFS_SERVER
              value: 192.168.32.100
              # nfs共享目录根目录
            - name: NFS_PATH
              value: /data/k8s
      volumes:
        - name: nfs-client-root
          nfs:
            # nfs服务IP
            server: 192.168.32.100
            # nfs共享目录根目录
            path: /data/k8s
```

将环境变量 NFS_SERVER 和 NFS_PATH 替换，当然也包括 volumes 的 nfs 配置，可以看到这⾥使⽤了⼀个名为 nfs-client-provisioner 的 serviceAccount ，所以需要创建⼀个 sa， 然后绑定上对应的权限。



```javascript

// 使用 docker 拉取 nfs-client-provisioner 镜像
docker pull quay.io/external_storage/nfs-client-provisioner:latest

// Deployment用到了SA,当Deployment创建过程中发现没有这个SA,会停止创建
// 直到用到的这个SA创建后才会继续创建
kubectl create -f deployment.yaml
kubectl get pods
kubectl describe deployment nfs-client-provisioner
```



第二步: 创建ServiceAccount

https://github.com/kubernetes-retired/external-storage/blob/master/nfs-client/deploy/rbac.yaml

[rbac.yaml](attachments/BC613E690F484A6BB88C419E62EF854Erbac.yaml)

```javascript
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```

这⾥新建的⼀个名为 nfs-client-provisioner 的 ServiceAccount ，然后绑定了⼀个名为 nfs-clientprovisioner-runner 的 ClusterRole ，⽽该 ClusterRole 声明了⼀些权限，其中就包括 对 persistentvolumes 的增、删、改、查等权限，所以可以利⽤该 ServiceAccount 来⾃动创建 PV。

```javascript
// 当创建了SA,可以看到Deployment开始继续创建容器
kubectl create -f rbac.yaml
kubectl describe deployment nfs-client-provisioner
```



第三步: nfs-client 的 Deployment 声明完成后，创建⼀个 StorageClass 对象

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#storageclass-v1-storage-k8s-io

https://github.com/kubernetes-retired/external-storage/blob/master/nfs-client/deploy/class.yaml

[class.yaml](attachments/E1384858680C4182BC1C38B1869AF00Dclass.yaml)

```javascript
# class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
# provisioner 属性的值要和Deployment中定义的PROVISIONER_NAME环境变量值一样
# or choose another name, must match deployment's env PROVISIONER_NAME'
provisioner: fuseim.pri/ifs
parameters:
  # 如果storageClass对象中指定archiveOnDelete参数并且值为false,则会自动删除oldPath下的所有数据,即pod对应的数据持久化存储数据
  # 如果storageClass对象中没有指定archiveOnDelete参数或者值为true,表明需要删除时存档,即将oldPath重命名,命名格式为oldPath前面增加"archived-"的前缀
  archiveOnDelete: "true"
```

这里声明了⼀个名为managed-nfs-storage 的 StorageClass 对象，注意下⾯的 provisioner对应的值⼀定要和上⾯的 Deployment 中的 PROVISIONER_NAME 这个环境变量的值⼀样。provisioner 翻译成中文就是"供应人"，相当于唯一标识，通过这个唯一标识就能找到Deployment中的Pod。

```javascript
kubectl create -f class.yaml
```





到此为止，nfs-client 的⾃动配置程序安装完成：

```javascript

// 创建完成后查看下资源状态
[root@centos7 storageclass]# kubectl get pods
NAME                                      READY   STATUS      RESTARTS       AGE
nfs-client-provisioner-7cbb9dc854-zlh24   1/1     Running     0              38m
// "kubectl get storageclass" 可以简写为 "kubectl get sc"
[root@centos7 storageclass]# kubectl get sc
NAME                  PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
managed-nfs-storage   fuseim.pri/ifs   Delete          Immediate           false                  32m
[root@centos7 storageclass]# kubectl get pv
No resources found
[root@centos7 storageclass]# kubectl get pvc
No resources found in default namespace.
```





3. StorageClass 资源对象创建成功，测试动态 PV

https://github.com/kubernetes-retired/external-storage/blob/master/nfs-client/deploy/test-claim.yaml



3.1 在Kubernetes v1.6之前的版本,通过volume.beta.kubernetes.io/storage-class注释类请求动态供应存储, 以下是v1.6之前的版本使用方法:

[test-claim.yaml](attachments/F47BC2BC933E438AABDA87DAF2431831test-claim.yaml)

```javascript
# test-claim.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
  annotations:
    volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
```

这⾥声明了⼀个 PVC 对象，采⽤ ReadWriteMany 的访问模式，请求 1Mi 的空间，annotations 下的 volume.beta.kubernetes.io/storage-class 属性标识出使用 "managed-nfs-storage" 这个StorageClass，如果没有标识出任何和 StorageClass 相关联的信息，那么直接创建的这个 PVC 对象也不能⾃动绑定上合适的 PV 对象,因为没有StorageClass创建一个合适的 PV。

有两种⽅法可以利⽤创建的 StorageClass 对象来⾃动帮我们创建⼀个合适的 PV:

- 第⼀种⽅法：在这个 PVC 对象中添加⼀个声明 StorageClass 对象的标识，这⾥可以利⽤⼀ 个 annotations 属性来标识。如下：

```javascript
metadata:
  # 在 metadata 下面添加 annotations
  annotations:
    # 添加 volume.beta.kubernetes.io/storage-class 属性    
    volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"
```

- 第⼆种⽅法：可以设置这个 course-nfs-storage 的 StorageClass 为 Kubernetes 的默认存储后端，可以⽤ kubectl patch 命令来更新。如下：

```javascript
# 格式：kubectl patch storageclass  $创建的StorageClass的name -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass course-nfs-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

上面两种⽅法都可以，但是为了不影响系统的默认⾏为，还是采⽤第⼀种⽅法比较好！

```javascript
kubectl create -f test-claim.yaml
kubectl get pvc
kubectl get pv
```





3.2 在 Kubernetes v1.6 版本之后，用户应该使用PersistentVolumeClaim对象的storageClassName参数来请求动态存储.

[test-claim-k8s-v1.22.yaml](attachments/A369CD98A28A4529ACFC5C9BEBBBFB2Dtest-claim-k8s-v1.22.yaml)

```javascript
# test-claim-k8s-v1.22.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
  # K8S V1.6 之前的版本通过volume.beta.kubernetes.io/storage-class注释类请求动态供应存储
  # annotations:
  #   volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"
spec:
  accessModes:
  - ReadWriteMany
  # 在v1.6版本之后, 用户PersistentVolumeClaim对象的storageClassName参数来请求动态存储
  storageClassName: managed-nfs-storage
  resources:
    requests:
      storage: 1Mi
```



```javascript
[root@centos7 storageclass]# kubectl get pvc
NAME         STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS          AGE
test-claim   Pending                                      managed-nfs-storage   3m41s
[root@centos7 storageclass]# kubectl get pods
NAME                                      READY   STATUS      RESTARTS       AGE
nfs-client-provisioner-7cbb9dc854-mr6r8   1/1     Running     0              3m58s
[root@centos7 storageclass]# kubectl logs nfs-client-provisioner-7cbb9dc854-mr6r8
// 省略......
E0923 06:41:37.329695       1 controller.go:1004] provision "default/test-claim" class "managed-nfs-storage": unexpected error getting claim reference: selfLink was empty, can't make reference
[root@centos7 storageclass]# 
```

从上面可以看出 test-claim 这个PVC还是 Pending 状态,似乎managed-nfs-storage 这个StorageClass 没有自动创建 PV，通过Pod日志可以看出原因是"selfLink was empty, can't make reference"，原因据说是k8s1.20版本禁用了selfLink，两种解决办法，如下：

- 方法一： 进入kubernetes放静态Pod文件的目录下，编辑 kube-apiserver.yaml，添加 "- --feature-gates=RemoveSelfLink=false"

```javascript
// k8s v1.22.0 静态Pod路径是: /etc/kubernetes/manifests
vi /etc/kubernetes/manifests/kube-apiserver.yaml

spec:
  containers:
  - command:
    - kube-apiserver
    # 这一行是添加行
    - --feature-gates=RemoveSelfLink=false

// 保存退出
//  静态Pod路径下的Pod文件变更后,系统会自动更新
```

- 方法二：更换provisioner的镜像，换个4.0以上的版本就行



使用方法一解决后:

```javascript
// Pod 已经正常启动,没有出现"selfLink was empty, can't make reference"错误
[root@centos7 manifests]# kubectl logs nfs-client-provisioner-7cbb9dc854-mr6r8
// 省略......
ResourceVersion:"570739", FieldPath:""}): type: 'Normal' reason: 'ProvisioningSucceeded' Successfully provisioned volume pvc-15e8aaa2-3b24-4ab1-b77c-32ccf8bc264a
// 名为 test-pvc 的 PVC 对象创建成功了,状态已经是 Bound, 也产生了一个对应的 VOLUME 对象
// STORAGECLASS这栏的值就是刚刚创建的 StorageClass 对象  managed-nfs-storage 
[root@centos7 manifests]# kubectl get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
test-claim   Bound    pvc-15e8aaa2-3b24-4ab1-b77c-32ccf8bc264a   1Mi        RWX            managed-nfs-storage   36m
// 这个PV对象不是手动创建的,是通过 StorageClass 对象自动动创建的,这就是StorageClass 的创建方法
// 自动生成的这个关联的PV对象,访问模式是 RWX,回收策略是 Delete
[root@centos7 manifests]# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS          REASON   AGE
pvc-15e8aaa2-3b24-4ab1-b77c-32ccf8bc264a   1Mi        RWX            Delete           Bound    default/test-claim   managed-nfs-storage            5m59s
```





4. ⽤⼀个简单的示例测试⽤ StorageClass ⽅式声明的PVC对象

https://github.com/kubernetes-retired/external-storage/blob/master/nfs-client/deploy/test-pod.yaml

[test-pod.yaml](attachments/0AB96E08CD6C4BFABF480A3188052B50test-pod.yaml)

```javascript
# test-pod.yaml
kind: Pod
apiVersion: v1
metadata:
  name: test-pod
spec:
  containers:
  - name: test-pod
    image: busybox
    imagePullPolicy: IfNotPresent
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "touch /mnt/SUCCESS && exit 0 || exit 1"
    volumeMounts:
      - name: nfs-pvc
        mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: test-claim
```

上⾯这个 Pod ⾮常简单，就是⽤⼀个 busybox 容器，在 /mnt ⽬录下⾯新建⼀个 SUCCESS 的⽂件， 然后把 /mnt ⽬录挂载到上⾯新建的 test-pvc 这个资源对象上⾯了，要验证很简单，只需要去查看 下我们 nfs 服务器上⾯的共享数据⽬录下⾯是否有 SUCCESS 这个⽂件即可。

```javascript
[root@centos7 storageclass]# kubectl create -f test-pod.yaml 
pod/test-pod created
// 查看 nfs 服务器的共享数据⽬录下⾯的数据
[root@centos7 storageclass]# ls /data/k8s/
default-test-claim-pvc-15e8aaa2-3b24-4ab1-b77c-32ccf8bc264a
// 文件夹下面的 SUCCESS 文件就是 busybox 这个容器创建的,说明持久化数据成功
[root@centos7 storageclass]# ls /data/k8s/default-test-claim-pvc-15e8aaa2-3b24-4ab1-b77c-32ccf8bc264a/
SUCCESS

// 可以看到共享数据⽬录下的文件夹名字很长,这个⽂件夹的命名⽅式的规则如下:
// ${namespace}-${pvcName}-${pvName}
               
```



5. 在实际⼯作中使⽤StorageClass更多的是StatefulSet类型的服务,StatefulSet 类型的服务也可以通过 volumeClaimTemplates 这样一个属性来直接使⽤ StorageClass。

[test-statefulset-nfs.yaml](attachments/A3C7C52F886348F8970974696762C8A2test-statefulset-nfs.yaml)

```javascript
# test-statefulset-nfs.yaml
---
apiVersion:  apps/v1
kind: StatefulSet
metadata:
  name: statefulset-sc
spec:
  # 一般来说，StatefulSet类型的服务不会简单直接的把副本设置成多个
  # 因为每个有状态的Pod下面它们的工作方式不尽相同
  # 比如说是个Mysql,不是简单的把mysql复制三份底层的数据就可以共享
  replicas: 3
  serviceName: nginx
  selector:
    matchLabels:
       app: statefulset-pod
  template:
    metadata:
      labels:
        app: statefulset-pod
    spec:
      # 在规定的terminationGracePeriodSeconds优雅时间内(默认30s)未能终止pod容器,则发送SIGKILL信号强制终止
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: nginx:1.7.9
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: nginx-port
        volumeMounts:
        - name: nginx-volume
          mountPath: /usr/share/nginx/html
  # 注意: volumeClaimTemplates 是 StatefulSet.sepc 下面的属性
  # volumeClaimTemplates下⾯就是⼀个PVC对象的模板,⽤这种模板就可以动态的去创建对象
  # 这⾥是⼿动创建的⼀个 PVC 对象,StorageClass会自动创建PV,而不会自动创建PVC
  volumeClaimTemplates:
  - metadata:
      name: nginx-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      # 使用 managed-nfs-storage 这个 StorageClass 自动创建PV
      storageClassName: managed-nfs-storage  
      resources:
        requests:
          storage: 1Gi
  
```

volumeClaimTemplates 下⾯就是⼀个 PVC 对象的模板，类似于 StatefulSet 下⾯的 template，template实际上就是⼀个 Pod 的模板，使用 PVC 对象的模板就不用单独创建成 PVC 对象，⽽⽤这种模板就可以动态的去创建了对象，这种⽅式在 StatefulSet 类型的服务下⾯使⽤得⾮常多。



```javascript
[root@centos7 storageclass]# kubectl create -f test-statefulset-nfs.yaml 
statefulset.apps/statefulset-sc created
// 可以看到3个 Pod 已经运行成功
[root@centos7 storageclass]# kubectl get pods
NAME                                      READY   STATUS      RESTARTS       AGE
statefulset-sc-0                          1/1     Running     0              8m33s
statefulset-sc-1                          1/1     Running     0              8m30s
statefulset-sc-2                          1/1     Running     0              8m27s
// 生成了3个PVC对象,名称由 模板名称name 加上 Pod的名称 组合而成,这3个PVC对象也都是绑定状态
[root@centos7 storageclass]# kubectl get pvc
NAME                            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
nginx-volume-statefulset-sc-0   Bound    pvc-0c7e5819-9c5b-45e1-91a6-0b137b83afc1   1Gi        RWO            managed-nfs-storage   9m47s
nginx-volume-statefulset-sc-1   Bound    pvc-2286e139-0f33-44bd-9a53-4a15e3992a7e   1Gi        RWO            managed-nfs-storage   9m44s
nginx-volume-statefulset-sc-2   Bound    pvc-23284421-1a74-4673-825f-42416c7f57ff   1Gi        RWO            managed-nfs-storage   9m41s
// 也可以看到对应的3个 PV 对象
[root@centos7 storageclass]# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                   STORAGECLASS          REASON   AGE
pvc-0c7e5819-9c5b-45e1-91a6-0b137b83afc1   1Gi        RWO            Delete           Bound    default/nginx-volume-statefulset-sc-0   managed-nfs-storage            11m
pvc-2286e139-0f33-44bd-9a53-4a15e3992a7e   1Gi        RWO            Delete           Bound    default/nginx-volume-statefulset-sc-1   managed-nfs-storage            11m
pvc-23284421-1a74-4673-825f-42416c7f57ff   1Gi        RWO            Delete           Bound    default/nginx-volume-statefulset-sc-2   managed-nfs-storage            11m
// 查看nfs服务器上的共享数据目录,对应了3个数据目录
[root@centos7 storageclass]# ls -ls /data/k8s/
0 drwxrwxrwx. 2 root root  6 Sep 23 04:25 default-nginx-volume-statefulset-sc-0-pvc-0c7e5819-9c5b-45e1-91a6-0b137b83afc1
0 drwxrwxrwx. 2 root root  6 Sep 23 04:25 default-nginx-volume-statefulset-sc-1-pvc-2286e139-0f33-44bd-9a53-4a15e3992a7e
0 drwxrwxrwx. 2 root root  6 Sep 23 04:25 default-nginx-volume-statefulset-sc-2-pvc-23284421-1a74-4673-825f-42416c7f57ff

```

如果没有 StorageClass，volumeMounts 只能使用一个 PVC，三个副本都使用的是同一个PVC，也就是说这三个Pod的数据都在一块。所以要用动态的 StorageClass 让三个副本的共享数据目录不冲突。如果不使用 StorageClass 就要手动创建三个Pod，然后创建三个PVC，但是现在 StorageClass 直接就能动态创建。					

但是对于StatefulSet这种类型的服务并不是简单的把下面的数据放在一块就能共享，比如mysql，并不是说启动三个mysql副本就能组成Mysql集群来共享数据。对于 StorageClass， 多⽤于StatefulSet 类型的服务，比如搭建 redis集群 或者 mysql 集群肯定会用到 StorageClass。





5. 使用 StorageClass 遇到的问题参考如下网页得到解决：



Kubernetes-基于StorageClass的动态存储供应

https://blog.csdn.net/bbwangj/article/details/82355357



k8s1.20使用动态供给storageclass问题

https://blog.csdn.net/chris3_29/article/details/119296921