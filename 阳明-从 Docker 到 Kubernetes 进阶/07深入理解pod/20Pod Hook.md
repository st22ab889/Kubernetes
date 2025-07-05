1.Pod 是 Kubernetes 集群中的最⼩单元，⽽ Pod 是有容器组组成的，所以在讨论 Pod 的⽣命 周期的时候我们可以先看下容器的⽣命周期.

Kubernetes 为我们的容器提供了⽣命周期钩⼦的，就是我们说的 Pod Hook ，Pod Hook 是由 kubelet 发起的，当容器中的进程启动前或者容器中的进程终⽌之前运⾏，这是包含在容器的⽣命周期 之中。我们可以同时为 Pod 中的所有容器都配置 hook. Kubernetes 为我们提供了两种钩⼦函数：

-  PostStart：这个钩⼦在容器创建后⽴即执⾏。但是，并不能保证钩⼦将在容器 ENTRYPOINT 之前运 ⾏，因为没有参数传递给处理程序。主要⽤于资源部署、环境准备等。不过需要注意的是如果钩 ⼦花费太⻓时间以⾄于不能运⾏或者挂起， 容器将不能达到 running 状态。 

- PreStop：这个钩⼦在容器终⽌之前⽴即被调⽤。它是阻塞的，意味着它是同步的， 所以它必须 在删除容器的调⽤发出之前完成。主要⽤于优雅关闭应⽤程序、通知其他系统等。如果钩⼦在执 ⾏期间挂起， Pod阶段将停留在 running 状态并且永不会达到 failed 状态。

如果 PostStart 或者 PreStop 钩⼦失败， 它会杀死容器。所以我们应该让钩⼦函数尽可能的轻量。当 然有些情况下，⻓时间运⾏命令是合理的， ⽐如在停⽌容器之前预先保存状态。 另外我们有两种⽅式来实现上⾯的钩⼦函数： 

- Exec - ⽤于执⾏⼀段特定的命令，不过要注意的是该命令消耗的资源会被计⼊容器。 

- HTTP - 对容器上的特定的端点执⾏ HTTP 请求。



2. postStart



[podhook-demo-poststart.yaml](attachments/08C87D141C4F42DEB6C25E59DD9CEEF0podhook-demo-poststart.yaml)



```javascript
# podhook-demo-poststart.yaml

---
apiVersion: v1
kind: Pod
metadata:
  name: podhook-demo-poststart
  labels:
    app: hook-poststart
spec:
  containers:
  - name: podhook-demo-poststart
    image: nginx
    ports:
    - name: webport
      containerPort: 80
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh", "-c", "echo hello from the postStart Handler > /usr/share/message"]


```





```javascript

kubectl apply -f podhook-demo-poststart.yaml 
kubectl get pods
kubectl describe pod podhook-demo-poststart 


# "kubectl exec"进入容器, "kubectl exec --help"查看参数
# 格式: kubectl exec [podNmae] -c [containerNmae] -i -t -- /bin/bash  
# -i表示标准输入, -t表示伪终端, 如果Pod只有一个容器,不用加"-c [containerNmae]"
# 已过时格式: kubectl exec [podNmae] -c [containerNmae] -i -t /bin/bash

// 验证:
# 进入容器
kubectl exec podhook-demo-poststart -c podhook-demo-poststart -i -t -- /bin/bash
# 查看文件
cat  /usr/share/message  
#如果显示"hello from the postStart Handler"说明钩子函数执行.      

#删除Pod, "kubectl delete pod --help"
# 格式: kubectl delete pod [podName] --grace-period=0 --force
# "--grace-period"指定退出时间,值'0'代表 强制删除 pod. 
# kubectl 1.5及以上的版本执⾏强制删除时必须同时指定 --force --grace-period=0
kubectl delete pod podhook-demo-poststart --grace-period=0 --force
kubectl get pods

```





3. preStop

[podhook-demo-preStop.yaml](attachments/E6C215AD13774BB19DF34942B4F4C1CFpodhook-demo-preStop.yaml)



```javascript

# podhook-demo-preStop.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: podhook-demo-prestop
  labels:
    app: hook
spec:
  containers:
  - name: podhook-demo-prestop
    image: nginx
    ports:
    - name: webport
      containerPort: 80
    volumeMounts:
    - name: message
      mountPath: /usr/share
    lifecycle:
      preStop:
        exec:
# nginx优雅关闭,但是这里无法验证,所以还是使用写入文件的方式
#          command: ["/usr/sbin/nginx", "-s", "quit"]
          command: ["/bin/sh", "-c", "echo hello from the preStop Handler > /usr/share/message"]
  volumes:
  - name: message
    hostPath:
      path: /tmp
      
```



```javascript

kubectl apply -f podhook-demo-preStop.yaml
kubectl get pods
kubectl describe pod podhook-demo-prestop

# 删除Pod的两种方式:
# 方式1: 根据pod名称删除
# kubectl delete pod podhook-demo-prestop
#方式2: 根据yaml文件删除,这样yaml文件中定义的所有资源文件都能删除掉
kubectl delete -f podhook-demo-preStop.yaml

# 验证
ls /tmp/message 
# 如果是在master上执行会出现"No such file or directory"
# 因为由于这是一个普通的pod，默认情况下普通的pod是不能调度到master上.

# 到node节点验证
ls /tmp/message
cat /tmp/message
# 如果出现"hello from the preStop Handler", 说明"preStop"函数执行了.
 
# nginx补充:
# ningx有个优雅退出的命令就是.
nginx -s quit 

# ngxin配置更细重新加载的命令,这样就不用重新启动nginx.
nginx -s reload
 
```





当⽤户请求删除含有 pod 的资源对象时（如Deployment等），K8S 为了让应⽤程序优雅关闭（即让应 ⽤程序完成正在处理的请求后，再关闭软件），K8S提供两种信息通知：

- 默认：K8S 通知 node 执⾏ docker stop 命令，docker 会先向容器中 PID 为1的进程发送系统信 号 SIGTERM ，然后等待容器中的应⽤程序终⽌执⾏，如果等待时间达到设定的超时时间，或者默 认超时时间（30s），会继续发送 SIGKILL 的系统信号强⾏ kill 掉进程。

- 使⽤ pod ⽣命周期（利⽤ PreStop 回调函数），它执⾏在发送终⽌信号之前。 



默认所有的优雅退出时间都在30秒内。kubectl delete 命令⽀持 --grace-period= 选项，这 个选项允许⽤户⽤他们⾃⼰指定的值覆盖默认值。值'0'代表 强制删除 pod. 在 kubectl 1.5 及以上的版 本⾥，执⾏强制删除时必须同时指定 --force --grace-period=0 。 

强制删除⼀个 pod 是从集群状态还有 etcd ⾥⽴刻删除这个 pod。 当 Pod 被强制删除时， api 服务器 不会等待来⾃ Pod 所在节点上的 kubelet 的确认信息：pod 已经被终⽌。在 API ⾥ pod 会被⽴刻删 除，在节点上， pods 被设置成⽴刻终⽌后，在强⾏杀掉前还会有⼀个很⼩的宽限期。

另外 Hook 调⽤的⽇志没有暴露个给 Pod 的 event，所以只能通过 describe 命令来获取，如果有错误 将可以看到 FailedPostStartHook 或 FailedPreStopHook 这样的 event。



















