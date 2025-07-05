1. Kubernetes集群中除了我们经常使⽤到的普通的 Pod 外，还有⼀种特殊 的 Pod，叫做 Static Pod ，就是我们说的静态 Pod.

静态 Pod 直接由特定节点上的 kubelet 进程来管理，不通过 master 节点上的 apiserver 。⽆法与我 们常⽤的控制器 Deployment 或者 DaemonSet 进⾏关联，它由 kubelet 进程⾃⼰来监控，当 pod 崩溃 时重启该 pod ， kubelete 也⽆法对他们进⾏健康检查。静态 pod 始终绑定在某⼀个 kubelet ，并且 始终运⾏在同⼀个节点上。 kubelet 会⾃动为每⼀个静态 pod 在 Kubernetes 的 apiserver 上创建⼀ 个镜像 Pod（Mirror Pod），因此我们可以在 apiserver 中查询到该 pod，但是不能通过 apiserver 进 ⾏控制（例如不能删除）。



2.⽤ kubeadm 安装的集群，master 节点上⾯的⼏个重要组件(etcd、apiserver、scheduler、controller-manager)都是⽤静态 Pod 的⽅式运⾏的， 我们登录到 master 节点上查看 /etc/kubernetes/manifests ⽬录.

这种⽅式也为我们将集群的⼀些组件容器化提供了可能，因为这些 Pod 都不会受到 apiserver 的控制，不然我们这⾥ kube-apiserver 怎么⾃⼰去控制⾃⼰呢？万⼀不⼩⼼把这个 Pod 删 掉了呢？所以只能有 kubelet ⾃⼰来进⾏控制，这就是我们所说的静态 Pod.



3.创建静态 Pod的两种方式:  配置⽂件和 HTTP 两种⽅式.

（1）配置⽂件就是放在特定⽬录下的标准的 JSON 或 YAML 格式的 pod 定义⽂件。⽤ kubelet --podmanifest-path=<the directory> 来启动 kubelet 进程，kubelet 定期的去扫描这个⽬录，根据这个⽬ 录下出现或消失的 YAML/JSON ⽂件来创建或删除静态 pod。

⽐如要在某个节点上⽤静态 pod 的⽅式来启动⼀个 nginx 的服务。我们登录到这个节点 上⾯，可以通过下⾯命令找到kubelet对应的启动配置⽂件.

```javascript

// kubelet-1.10.0-0 kubeadm-1.10.0-0 kubectl-1.10.0-0,此版本集群按如下设置 .

#运行下面命令令找到kubelet对应的启动配置⽂件路径.
systemctl status kubele

#打开如下路径⽂件我们可以看到其中有⼀条如下的环境变量配置：
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allowprivileged=true"

#"/etc/kubernetes/manifests"就是静态Pod⽂件的路径,只需要在该⽬录下⾯创建⼀个标准的Pod的JSON或者YAML⽂件即可
#所以如果通过 kubeadm 的⽅式来安装的集群环境，对应的kubelet已经配置了静态Pod⽂件的路径.
#如果你的kubelet启动参数中没有配置上⾯的"--pod-manifest-path"参数的话,那么添加上这个参数然后重启kubelet即可.


```



[StaticPodExample.yaml](attachments/315AF00807344A9994EAE2D57657EC05StaticPodExample.yaml)



```javascript


// kubeadm.x86_64 0:1.22.1-0,kubectl.x86_64 0:1.22.1-0,kubelet.x86_64 0:1.22.1-0 
// 官方文档:https://kubernetes.io/zh/docs/tasks/configure-pod-container/static-pod/
// 此版本按如下配置:

#方式1：使用"--pod-manifest-path= <the directory>"参数,没有配成功
#把静态Pod文件放在<the directory>目录下.

==============================================================

#方式2: 
#查看kubeadm的环境变量,Drop-In 就是配置环境变量文件所在的路径.
systemctl status kubelet
//  Drop-In: /usr/lib/systemd/system/kubelet.service.d
//           └─10-kubeadm.conf

#查看kubelet配置文件路径,"--config=/var/lib/kubelet/config.yaml"就是配置文件所在位置
cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
// Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"

#查看配置静态Pod的目录,staticPodPath就是放静态Pod的路径
cat /var/lib/kubelet/config.yaml
// staticPodPath: /etc/kubernetes/manifests

#把定义好的"StaticPodExample.yaml"放到"/etc/kubernetes/manifests"目录

==============================================================

#验证,在1.22.1版本中用以下命令看不到容器,在1.10.0中可以
docker ps|grep static 

# 运行下面命令如果看到静态Pod被创建说明静态Pod创建成功
kubectl get pods 

#静态Pod并不能被删除
kubectl delete pod static pod static-pod-1-centos7.master
kubectl get pods 

#从"/etc/kubernetes/manifests"目录中移除"StaticPodExample.yaml"后,静态Pod消失.

```



（2）kubelet 周期地从 –manifest-url= 参数指定的地址下载⽂件，并且把它翻译成 JSON/YAML 格式的 pod 定义。此后的操作⽅式与 –pod-manifest-path= 相同，kubelet 会不时地重新下载该⽂件，当⽂件 变化时对应地终⽌或启动静态 pod。

```javascript
// kubelet-1.10.0-0 kubeadm-1.10.0-0 kubectl-1.10.0-0
// kubeadm.x86_64 0:1.22.1-0,kubectl.x86_64 0:1.22.1-0,kubelet.x86_64 0:1.22.1-0 
// 两个版本都是设置如下参数:
--manifest-url=<manifest-url>

```





结论:

- 静态 pod 的标签会传递给镜像 Pod，可以⽤来过滤或筛选

- 不能通过API服务器来删除静态pod(例如，通过kubectl命令),kebelet不会删除它.

- 如果尝试⼿动终⽌容器，可以看到kubelet很快就会⾃动重启容器.

- 静态pods的动态增加和删除, 运⾏中的kubelet周期扫描配置的⽬录(/etc/kubernetes/manifests)下⽂件的变化,当这个⽬录中有⽂件出现或消失时创建或删除pods.





4. 重要的命令:

```javascript

# 查看kubectl的版本.
kubectl version

# 重启kubelet
systemctl restart kubelet

# 查看kubeleat启动时的配置.
systemctl status kubelet

# 查看kubelet相关信息
kubelet

#kubelet.service changed on disk. Run 'systemctl daemon-reload' to reload units
systemctl daemon-reload

================================================================================
 
Linux相关命令:

#使用"lsof"和"netstat"查看端口占用情况,比如查看进程名称和PID,
#如果使用"lsof"提示没有这个命令,使用"yum install lsof -y"安装
lsof -i:10250     
netstat -tunlp | grep 10250
     
#根据PID结束某个进程
kill 96237

```





kubelet参数说明: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/



