1. ConfigMap 是⽤来存储⼀些⾮安全的配置信息，  Secret ⽤来保存敏感信息，例如密码、OAuth 令牌和 ssh key等 等，将这些信息放在 Secret 中⽐放在 Pod 的定义中或者 docker 镜像中来说更加安全和灵活。

Secret 有三种类型：

- Opaque：base64 编码格式的 Secret，⽤来存储密码、密钥等；但数据也可以通过base64 – decode解码得到原始数据，所有加密性很弱。 

- kubernetes.io/dockerconfigjson：⽤来存储私有docker registry的认证信息。 

- kubernetes.io/service-account-token：⽤于被 serviceaccount 引⽤，serviceaccout 创建时 Kubernetes会默认创建对应的secret。Pod如果使⽤了serviceaccount，对应的secret会⾃动挂载 到Pod⽬录 /run/secrets/kubernetes.io/serviceaccount 中。



2. Opaque Secret

Opaque 类型的数据是⼀个 map 类型，要求value是 base64 编码格式.

```javascript
// 创建⼀个⽤户名为 admin，密码为 admin321 的 Secret 对象，
// ⾸先我们先把这⽤户名和密码做 base64 编码

// linux下执行
[root@centos7 secret]# echo -n "admin" | base64
YWRtaW4=
[root@centos7 secret]# echo -n "admin321" | base64
YWRtaW4zMjE=

```



创建Opaque类型的Secret对象,如下:

[secret-base64.yaml](attachments/FFC9EE4A89234DBD81FC7689006988BAsecret-base64.yaml)



```javascript
# secret-base64.yaml
---
apiVersion: v1
kind: Secret
metadata:
   name: secret-base64
type: Opaque
data:
  username: YWRtaW4=
  password: YWRtaW4zMjE=
```



```javascript
kubectl create -f secret-base64.yaml

# 可以看到有 default-token-qrhp7 和 secret-base64 两个Secret对象
# 其中 default-token-qrhp7 是创建集群时默认创建的secret,被serviceacount/default引⽤
kubectl get secret

# 利⽤describe命令查看到的Data没有直接显示出来,来，如果想看到 Data ⾥⾯的详细信息可以输出成YAML⽂件进⾏查看
kubectl describe secret secret-base64

# 输出成YAML⽂件进⾏查看
kubectl get secret secret-base64 -o yaml
```



创建好 Secret 对象后，有两种⽅式来使⽤它： 

- 以环境变量的形式 

- 以Volume的形式挂载



2.1 以环境变量的形式使用 Secret对象

[use-secret-by-env-pod.yaml](attachments/85E0AE81E27346EAAE51CE05B9C975FBuse-secret-by-env-pod.yaml)

```javascript
# use-secret-by-env-pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
   name: use-secret-by-env-pod
spec:
  containers:
  - name: use-secret-by-env
    image: busybox
    command: ["/bin/sh", "-c", "env"]
    env:
    - name: USERNAME
      valueFrom:
        # secretKeyRef 表示从Secret对象中获取
        secretKeyRef:
          # 指定Secret对象
          name: secret-base64
          key: username
    - name: PASSWORD
      valueFrom:
        # secretKeyRef 表示从Secret对象中获取
        secretKeyRef:
          # 指定Secret对象
          name: secret-base64
          key: password
```



```javascript
kubectl create -f use-secret-by-env-pod.yaml
kubectl get pods
# 利用logs命令可以看到打印出的环境变量包括 USERNAME=admin 和 PASSWORD=admin321
kubectl logs use-secret-by-env-pod
```



2.2 以Volume的形式挂载

[use-secret-by-volume-pod.yaml](attachments/622D853AF3E649F58B668EB51E77CEE6use-secret-by-volume-pod.yaml)

```javascript
# use-secret-by-volume-pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
   name: use-secret-by-volume-pod
spec:
  containers:
  - name: use-secret-by-volume
    image: busybox
    # 挂载进去会把Secret对象里面的数据变成文件,有多少条数据就会有多少个文件
    command: ["/bin/sh", "-c", "ls /etc/secrets"]
    volumeMounts:
    - name: secrets
      mountPath: /etc/secrets
  volumes:
  - name: secrets
    secret:
      secretName: secret-base64
```



```javascript
kubectl create -f use-secret-by-volume-pod.yaml
kubectl get pods
# 用logs命令可以看到Secret对象挂载到数据卷后,Secret对象的两个key挂载成了两个⽂件
kubectl logs kubectl logs use-secret-by-volume-pod
```





也可以挂载到指定的⽂件上⾯，在 secretName 下⾯添加 items 指定 key 和 path,如下:

[use-secret-by-volume-pod2.yaml](attachments/94E02F0E24664D27AA713C10C4B06FF8use-secret-by-volume-pod2.yaml)

```javascript
# use-secret-by-volume-pod2.yaml
---
apiVersion: v1
kind: Pod
metadata:
   name: use-secret-by-volume-pod2
spec:
  containers:
  - name: use-secret-by-volume2
    image: busybox
    command: ["/bin/sh", "-c", "cat /etc/secrets/usr/detail/userinfo.conf"]
    volumeMounts:
    - name: secrets
      mountPath: /etc/secrets
  volumes:
  - name: secrets
    secret:
      secretName: secret-base64
      # 把Secret对象挂载到指定的文件,在secretName下⾯添加items,指定key和path
      items:
      - key: username
        path: usr/detail/userinfo.conf
```



```javascript
kubectl create -f use-secret-by-volume-pod2.yaml
kubectl get pods
kubectl logs use-secret-by-volume-pod2

// Secret对象中username对应的值是admin的Base64编码
// 这里显示出admin说明进行了Base64的解码 
[root@centos7 secret]# kubectl logs use-secret-by-volume-pod2
admin
```



3. kubernetes.io/dockerconfigjson 是用来创建⽤户 docker registry 认证的 Secret ，直接使 ⽤ kubectl create 命令创建即可.

```javascript

# 创建一个docker-registry类型的secret,用来存储docker的registry认证信息
# 格式: kubectl create secret docker-registry $secretName  --docker-server=$server --docker-username=$username --docker-password=$password --docker-email=$email
kubectl create secret docker-registry my-docker-registry --docker-server=DOKER_SEVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL

# 可以看到刚刚创建的my-docker-registry对象,default-token-qrhp7是集群创建时自动生成的
# 可以看到my-docker-registry对象的类型是 kubernetes.io/dockerconfigjson
kubectl get secret
# 利⽤describe命令查看到的Data没有直接显示出来,来，如果想看到 Data ⾥⾯的详细信息可以输出成YAML⽂件进⾏查看
kubectl describe secret my-docker-registry

# 输出成YAML⽂件进⾏查看
kubectl get secret my-docker-registry -o yaml

// 从yaml文件中查看到的 data: .dockerconfigjson 值使用base64解码, 可以看到docker-registry详细信息
[root@centos7 secret]# echo eyJhdXRocyI6eyJET0tFUl9TRVZFUiI6eyJ1c2VybmFtZSI6IkRPQ0tFUl9VU0VSIiwicGFzc3dvcmQiOiJET0NLRVJfUEFTU1dPUkQiLCJlbWFpbCI6IkRPQ0tFUl9FTUFJTCIsImF1dGgiOiJSRTlEUzBWU1gxVlRSVkk2UkU5RFMwVlNYMUJCVTFOWFQxSkUifX19 | base64 -d
{"auths":{"DOKER_SEVER":{"username":"DOCKER_USER","password":"DOCKER_PASSWORD","email":"DOCKER_EMAIL","auth":"RE9DS0VSX1VTRVI6RE9DS0VSX1BBU1NXT1JE"}}}

```





如果要拉取私有仓库中docker镜像,就需要使用到docker-registry类型的secret对象，如下:

[use-secret-by-docker-registry-pod.yaml](attachments/98C352F2CE0C45888EEB2D18AE6CD953use-secret-by-docker-registry-pod.yaml)

```javascript
---
apiVersion: v1
kind: Pod
metadata:
  name: test-secret-docker-registry-pod
spec:
  containers:
  - name: foo
    # 私有仓库镜像,默认私有仓库只需要用 docker login 认证
    image: 192.168.1.100:5000/test:v1
  imagePullSecrets:
  - name: my-docker-registry
```



上面YAML文件表示需要拉取私有仓库镜像 192.168.1.100:5000/test:v1，就需要针对该私有仓库来创建⼀个如上的Secret ，然后在 Pod 的 YAML ⽂件中指定 imagePullSecrets ，会在使用Harbor搭建私有仓库中详细讲到.



作业: 使用阿里云私有仓库也来测试kubernetes.io/dockerconfigjson类型的Secret,在一个集群环境当中拉取阿里云中私有仓库的镜像.





4. kubernetes.io/service-account-token 类型的 Secret



kubernetes.io/service-account-token类型的Secret，⽤于被 serviceaccount 引⽤。 serviceaccout 创建时 Kubernetes 会默认创建对应的 secret。Pod 如果使⽤了 serviceaccount，对应 的secret会⾃动挂载到Pod的 /run/secrets/kubernetes.io/serviceaccount ⽬录中。



使⽤⼀个 nginx 镜像来验证，busybox 镜像来验证也是 可以的，但是就不能在 command ⾥⾯来验证了，因为token是需要 Pod 运⾏起来过后才会被挂载 上去的，直接在 command 命令中去查看肯定是还没有 token ⽂件的。



4.1 查看Pod的"/run/secrets/kubernetes.io/serviceaccount"⽬录是否有token这个文件

```javascript
// 查看Pod的"/run/secrets/kubernetes.io/serviceaccount"⽬录是否有token这个文件

kubectl run test-sa-token --image nginx

kubectl describe pod test-sa-token

// 进入到nginx中的Pod中，这就是service-account-token这种类型的Secret对象的用法
[root@centos7 secret]# kubectl exec -it test-sa-token /bin/bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@test-sa-token:/# ls /run/secrets/kubernetes.io/serviceaccount      
ca.crt  namespace  token
root@test-sa-token:/# cat /run/secrets/kubernetes.io/serviceaccount/token
eyJhbGciOiJSUzI1NiIsImtpZCI6ImdWOE1QTFdNQTdtZndGUnprZjdfTF9fbDlMTEN5ejRKb1dnSFV3c3Y0UzQifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjYzNDAxMjM4LCJpYXQiOjE2MzE4NjUyMzgsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0IiwicG9kIjp7Im5hbWUiOiJ0ZXN0LXNhLXRva2VuIiwidWlkIjoiNjcwMDdkMzAtZDlhMS00NTgxLWJjODQtNmMxYzMwMGRhMmIyIn0sInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJkZWZhdWx0IiwidWlkIjoiZGVmZjBlMTktNDkzYS00OGFiLWI5ZTgtMWYxNGE0NDEzMzE5In0sIndhcm5hZnRlciI6MTYzMTg2ODg0NX0sIm5iZiI6MTYzMTg2NTIzOCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6ZGVmYXVsdCJ9.mhgLvGJtNt1HZmkMLuF2mE7CvBTCyAOH5jEYpwVGdT8C-AydiXofYxQ1FWRKW4ZZRiQs4yseqt_NMi81Pk4ImEfGmC7IIAix7EOpAHtgt2wJ8rEyeMlhri2rSUbsYab8Gp7CSRETt7K-1H4ADffo5-nqixH0N7IyLBDTlY7-H1qnyxfMDpN5CApk3DCQcuCSPUbGzxMDicPehhHiYdjkYqH1ld1eQDcvCPtjICYSotAEiByR6TYpfZeatB65oWq6UQWZWsqJmjXnQ2DmOBQB5qJH_c2hyhGV0jph1aoFOVafrdUsSRkgwVrCwmIRjPoL2p6a9Vvnc9tevf9S9h8M6A
root@test-sa-token:/# exit
exit
command terminated with exit code 127
[root@centos7 secret]#
kubectl exec -it test-sa-token /bin/bash
```





4.2  Pod、ServiceAccount、Secret这三种资源对象之间的关系:

```javascript

kubectl get pods

kubectl get pod test-sa-token -o yaml
// 运行"kubectl get pod test-sa-token -o yaml"输出内容包含以下两行内容:
//  serviceAccount: default
//  serviceAccountName: default
// 现在推荐使用serviceAccountName这个key,如果是以前的版本,使用serviceAccount也没有问题

// 查看Secret对象 
[root@centos7 secret]# kubectl get secret 
NAME                  TYPE                                  DATA   AGE
default-token-qrhp7   kubernetes.io/service-account-token   3      24d
my-docker-registry    kubernetes.io/dockerconfigjson        1      59m
secret-base64         Opaque                                2      111m

// sa表示ServiceAccount资源对象
[root@centos7 secret]# kubectl get sa
NAME      SECRETS   AGE
default   1         24d

// 可以看到有个Mountable secrets是default-token-qrhp7
// default-token-qrhp7是一个kubernetes.io/service-account-token类型的Secret对象
// 也就是说一个名为"default"的ServiceAccount资源对象,用到了default-token-qrhp7这个Secret对象
// Pod对象又用到了"default"这个ServiceAccount资源对象.
[root@centos7 secret]# kubectl describe sa default
Name:                default
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   default-token-qrhp7
Tokens:              default-token-qrhp7
Events:              <none>

```





4.3 Pod的"/run/secrets/kubernetes.io/serviceaccount"⽬录挂载token文件原理

```javascript
// Pod的"/run/secrets/kubernetes.io/serviceaccount"⽬录挂载token文件原理

# 运行下面命令查看发现有"default-token-qrhp7"这个secret资源对象
# 同时"default-token-qrhp7"这个secret对象的类型是kubernetes.io/service-account-token
kubectl get secret

# 运行下面命令查看"default-token-qrhp7"的详细信息,其中包含了token值
kubectl describe secret default-token-qrhp7

# sa表示ServiceAccount资源对象,可以看看到有个名为default的SA资源对象
kubectl get sa

# 查看名为default的这个SA资源对象的详细信息.
# 发现"Mountable secrets"值为"default-token-qrhp7"
# 这相当于把"default-token-qrhp7"里面的token挂载到了名为default的这个SA资源对象中
kubectl describe sa default

# 运行下面命令出现的内容包含"serviceAccount: default"和"serviceAccountName: default"
# 说明这个Pod使用了名为default的这个SA资源对象
# 然后这个token转为文件挂载到"/run/secrets/kubernetes.io/serviceaccount"目录
kubectl get pod test-sa-token -o yaml


```





补充:

挂载到Pod的"/run/secrets/kubernetes.io/serviceaccount/token"的token值如下:

eyJhbGciOiJSUzI1NiIsImtpZCI6ImdWOE1QTFdNQTdtZndGUnprZjdfTF9fbDlMTEN5ejRKb1dnSFV3c3Y0UzQifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjYzNDAxMjM4LCJpYXQiOjE2MzE4NjUyMzgsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0IiwicG9kIjp7Im5hbWUiOiJ0ZXN0LXNhLXRva2VuIiwidWlkIjoiNjcwMDdkMzAtZDlhMS00NTgxLWJjODQtNmMxYzMwMGRhMmIyIn0sInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJkZWZhdWx0IiwidWlkIjoiZGVmZjBlMTktNDkzYS00OGFiLWI5ZTgtMWYxNGE0NDEzMzE5In0sIndhcm5hZnRlciI6MTYzMTg2ODg0NX0sIm5iZiI6MTYzMTg2NTIzOCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6ZGVmYXVsdCJ9.mhgLvGJtNt1HZmkMLuF2mE7CvBTCyAOH5jEYpwVGdT8C-AydiXofYxQ1FWRKW4ZZRiQs4yseqt_NMi81Pk4ImEfGmC7IIAix7EOpAHtgt2wJ8rEyeMlhri2rSUbsYab8Gp7CSRETt7K-1H4ADffo5-nqixH0N7IyLBDTlY7-H1qnyxfMDpN5CApk3DCQcuCSPUbGzxMDicPehhHiYdjkYqH1ld1eQDcvCPtjICYSotAEiByR6TYpfZeatB65oWq6UQWZWsqJmjXnQ2DmOBQB5qJH_c2hyhGV0jph1aoFOVafrdUsSRkgwVrCwmIRjPoL2p6a9Vvnc9tevf9S9h8M6A





使用"kubectl describe secret default-token-qrhp7"打印出来的token如下:

eyJhbGciOiJSUzI1NiIsImtpZCI6ImdWOE1QTFdNQTdtZndGUnprZjdfTF9fbDlMTEN5ejRKb1dnSFV3c3Y0UzQifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlZmF1bHQtdG9rZW4tcXJocDciLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGVmYXVsdCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImRlZmYwZTE5LTQ5M2EtNDhhYi1iOWU4LTFmMTRhNDQxMzMxOSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmRlZmF1bHQifQ.TlDONHOLnWHIuUyV3snnh3QNVCdfeqsuD5prDP1DAAM_YY_n82v-OdXGAiwUU91HfSep-SUkh6Yzt9cs5F07jNji4lX_L4QQAMtX6MIzR93Dvw8AkSB8SyOC7klfNkV53ErCvb7djwfQOghKWoUe5sZ4i2MReWbTfeQeNVTnsRqvj3-D4mTkBuy-TX22wVeTLbkxpfN67gGkdAyeFD5qB9j53QDbaPewLBGqQPbcjZ95hPIjx2aZ81colI2IBazF2qFmdaSGgx3XKIvmOmJ2v-DNH-URtxeVncuqUdEGbb8QWwg56s2nC5U3VwbxZCeUh3g_NY6qXb3XP-KEpSgGug



(这些token实际上是由多个值经过base64编码拼接而成,拼接过程中使用"."进行割开)



结论: 实际上它们只有一部分token一样，把这部分一样的token经过base64解码得到如下值:



token(实际上就是一个Base64编码的字符串): eyJhbGciOiJSUzI1NiIsImtpZCI6ImdWOE1QTFdNQTdtZndGUnprZjdfTF9fbDlMTEN5ejRKb1dnSFV3c3Y0UzQifQ



Base64解码后:

{"alg":"RS256","kid":"gV8MPLWMA7mfwFRzkf7_L__l9LLCyz4JoWgHUwsv4S4"}







5. 对⽐ Secret 和 ConfigMap 这两种资源对象的异同点：



相同点：

- key/value的形式

- 属于某个特定的namespace

- 可以导出到环境变量

- 可以通过⽬录/⽂件形式挂载

- 通过 volume 挂载的配置信息均可热更新

不同点：

- Secret 可以被 ServerAccount 关联

- Secret 可以存储 docker register 的鉴权信息，⽤在 ImagePullSecret 参数中，⽤于拉取私有仓库的镜像

- Secret ⽀持 Base64 加密

- Secret 分为 kubernetes.io/service-account-token、kubernetes.io/dockerconfigjson、Opaque 三种类型，⽽ Configmap 不区分类型