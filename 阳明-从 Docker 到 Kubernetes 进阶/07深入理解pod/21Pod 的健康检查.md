1. 除 了两个钩⼦函数(PostStart 与 PreStop)以外，还有⼀项配置会影响到容器的⽣命周期的，那就是健康检查的探针。



在 Kubernetes 集群当中，我们可以通过配置 liveness probe （存活探针）和 readiness probe （可 读性探针）来影响容器的⽣存周期。

- kubelet 通过使⽤ liveness probe 来确定你的应⽤程序是否正在运⾏，通俗点将就是是否还活着。⼀般来 说，如果你的程序⼀旦崩溃了， Kubernetes 就会⽴刻知道这个程序已经终⽌了，然后就会重启这个程序。⽽我 们的 liveness probe 的⽬的就是来捕获到当前应⽤程序还没有终⽌，还没有崩溃，如果出现了这些情况，那么 就重启处于该状态下的容器，使应⽤程序在存在 bug 的情况下依然能够继续运⾏下去。 

- kubelet 使⽤ readiness probe 来确定容器是否已经就绪可以接收流量过来了。这个探针通俗点讲就是说是 否准备好了，现在可以开始⼯作了。只有当 Pod 中的容器都处于就绪状态的时候 kubelet 才会认定该 Pod 处 于就绪状态，因为⼀个 Pod 下⾯可能会有多个容器。当然 Pod 如果处于⾮就绪状态，那么我们就会将他从我们 的⼯作队列(实际上就是我们后⾯需要重点学习的 Service)中移除出来，这样我们的流量就不会被路由到这个 P od ⾥⾯来了。



2.探针支持以下三种配置方式.



-  exec：执⾏⼀段命令 

-  http：检测某个 http 请求 

-  tcpSocket：使⽤此配置， kubelet 将尝试在指定端⼝上打开容器的套接字。如果可以建⽴连接，容器被认为 是健康的，如果不能就认为是失败的。实际上就是检查端⼝.



3.存活探针, 使用 exec 执⾏命令的⽅式来检测容器。



[pod-liveness-prove-exec.yaml](attachments/BE7D382BAA354D02A8640248CA29613Fpod-liveness-prove-exec.yaml)

```javascript
# pod-liveness-prove-exec.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: liveness-probe-exec-demo
  labels:
    app: liveness
spec:
  containers:
  - name: liveness-probe-exec-demo
    image: busybox
    args:
    - /bin/sh
    - -c
    # 容器最开始的30秒内有⼀个 /tmp/healthy ⽂件,30秒后，我们删除这个⽂件
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      #第一次执行探针先要等待5秒，这样保证容器里面的一些文件、配置等都准备好了然后每隔5秒执行一次存活探针  
      initialDelaySeconds: 5
      #每隔5秒执行一次liveness probe.因为30秒后就移除了"/tmp/healthy", 所以30秒后执行命令就会报错,然后容器会被杀掉重启
      periodSeconds: 5
```



通过 exec 执⾏⼀段命令，其 中 periodSeconds 属性表示让 kubelet 每隔5秒执⾏⼀次存活探针，也就是每5秒执⾏⼀次上⾯的 cat /tmp/healthy 命令，如果命令执⾏成功了，将返回0，那么 kubelet 就会认为当前这个容器是存活的 并且很监控，如果返回的是⾮0值，那么 kubelet 就会把该容器杀掉然后重启它。

属 性 initialDelaySeconds 表示在第⼀次执⾏探针的时候要等待5秒，这样能够确保我们的容器能够有⾜ 够的时间启动起来。如果你的第⼀次执⾏探针等候的时间太短有可能容 器还没正常启动起来，存活探针很可能始终都是失败的，这样就会⽆休⽌的重启下去. 所以⼀个合理的 initialDelaySeconds ⾮常重要。



```javascript
kubectl apply -f pod-liveness-prove-exec.yaml
kubectl get pods
kubectl describe pod liveness-probe-exec-demo
kubectl delete pod liveness-probe-exec-demo

```









4.存活探针, 使用 http 的⽅式来检测容器。



```javascript
# pod-liveness-prove-http.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: liveness-probe-http-demo
  labels:
    app: liveness
spec:
  containers:
  - name: liveness-probe-http-demo
    image: cnych/liveness
    args:
    - /server
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 3
      periodSeconds: 3  
```



```javascript
# 容器中http部分的代码.
# 前10s返回http状态码200，10s过后返回状态码500
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    duration := time.Now().Sub(started)
    if duration.Seconds() > 10 {
        w.WriteHeader(500)
        w.Write([]byte(fmt.Sprintf("error: %v", duration.Seconds())))
    } else {
        w.WriteHeader(200)
        w.Write([]byte("ok"))
    }
})

#  请求成功: 200 <= httpCode < 400
#  请求失败:  httpCode >= 400

```

kubelet 需要每隔3秒执⾏⼀次 liveness probe ，该 探针将向容器中的 server 的8080端⼝发送⼀个 HTTP GET 请求。如果 server 的 /healthz 路径的 handler 返回⼀个成功的返回码， kubelet 就会认定该容器是活着的并且很健康,如果返回失败的返回 码， kubelet 将杀掉该容器并重启它。。 initialDelaySeconds 指定 kubelet 在该执⾏第⼀次探测之 前需要等待3秒钟。

通常来说，任何⼤于200⼩于400的返回码都会认定是成功的返回码。其他返回码都会被认为是失败的 返回码。



```javascript
kubectl apply -f pod-liveness-prove-http.yaml
kubectl get pods
kubectl describe pod liveness-probe-http-demo
kubectl delete pod liveness-probe-http-demo
```



5.存活探针和可读探针, 使用 http 和 TCP Socket 的⽅式来检测容器。

[pod-liveness-prove-tcpsocket.yaml](attachments/9640052E815D4F808B1CEED6D91027D4pod-liveness-prove-tcpsocket.yaml)



```javascript
# pod-liveness-prove-tcpsocket.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: liveness-probe-tcpsocket-demo
  labels:
    app: liveness
spec:
  containers:
  - name: liveness-probe-tcpsocket-demo
    image: cnych/liveness
    args:
    - /server
    #存活探针
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5  
    #可读探针(就绪态探针),如果容器没就绪(容器可能还在进行加载文件和配件等工作)就告诉k8s不要把流量分配发过来过来.
    readinessProbe: 
      tcpSocket:
        port: 8080
      initialDelaySeconds: 3
      periodSeconds: 3
```



```javascript
kubectl apply -f pod-liveness-prove-tcpsocket.yaml
kubectl get pods
kubectl describe pod liveness-probe-tcpsocket-demo
kubectl delete pod liveness-probe-tcpsocket-demo
```



使用TCP socket, kubelet 将尝试在指定端⼝上打开容器的 套接字。 如果可以建⽴连接，容器被认为是健康的，如果不能就认为是失败的。

TCP 检查的配置与 HTTP 检查⾮常相似，只是将 httpGet 替换成了 tcpSocket 。 ⽽ 且我们同时使⽤了 readiness probe 和 liveness probe 两种探针。 容器启动后3秒后， kubelet 将发 送第⼀个 readiness probe （可读性探针）。 该探针会去连接容器的8080端，如果连接成功，则该 Pod 将被标记为就绪状态。然后 Kubelet 将每隔3秒钟执⾏⼀次该检查.

除了 readiness probe 之外，该配置还包括 liveness probe 。 容器启动5秒后， kubelet 将运⾏第 ⼀个 liveness probe 。 就像 readiness probe ⼀样，这将尝试去连接到容器的8080端⼝。如 果 liveness probe 失败，容器将重新启动.

有的时候，应⽤程序可能暂时⽆法对外提供服务，例如，应⽤程序可能需要在启动期间加载⼤量数据 或配置⽂件。 在这种情况下，您不想杀死应⽤程序，也不想对外提供服务。 那么这个时候我们就可以 使⽤ readiness probe 来检测和减轻这些情况。 Pod中的容器可以报告⾃⼰还没有准备，不能处理 Kubernetes服务发送过来的流量。 

从上⾯的 YAML ⽂件我们可以看出 readiness probe 的配置跟 liveness probe 很像，基本上⼀致的。 唯⼀的不同是使⽤ readinessProbe ⽽不是 livenessProbe 。两者如果同时使⽤的话就可以确保流量不 会到达还未准备好的容器，准备好过后，如果应⽤程序出现了错误，则会重新启动容器。 

另外除了上⾯的 initialDelaySeconds 和 periodSeconds 属性外，探针还可以配置如下⼏个参数：

- timeoutSeconds：探测超时时间，默认1秒，最⼩1秒。 

- successThreshold：探测失败后，最少连续探测成功多少次才被认定为成功。默认是 1，但是如果是`liveness probe `则必须是 1。最⼩值是 1。 

- failureThreshold：探测成功后，最少连续探测失败多少次才被认定为失败。默认是 3，最⼩值是 1。



6.总结

(1). 一般情况下, 在pod中做健康检查的时候都会把"livenessProbe"和"readinessProbe"同时使用,同时使用可以确保流量不会到达还未准备好的容器中,如果"readinessProbe"通过了说明容器准备好了,准备好了就通过"livenessProbe"来检查应用的存活性(如果应用程序失败了就会重启容器)



(2). pod当中的探针检测(健康检查)对提高应用程序的稳定性和健壮性非常重要,一般线上应用程序都需要去配置"livenessProbe"和"readinessProbe"



(3). 官方文档(V1.22版本)还有另外一种探针,官方文档如下:

- livenessProbe：指示容器是否正在运行。如果存活态探测失败，则 kubelet 会杀死容器， 并且容器将根据其重启策略决定未来。如果容器不提供存活探针， 则默认状态为 Success。

- readinessProbe：指示容器是否准备好为请求提供服务。如果就绪态探测失败， 端点控制器将从与 Pod 匹配的所有服务的端点列表中删除该 Pod 的 IP 地址。 初始延迟之前的就绪态的状态值默认为 Failure。 如果容器不提供就绪态探针，则默认状态为 Success。

- startupProbe: 指示容器中的应用是否已经启动。如果提供了启动探针，则所有其他探针都会被 禁用，直到此探针成功为止。如果启动探测失败，kubelet 将杀死容器，而容器依其 重启策略进行重启。 如果容器没有提供启动探测，则默认状态为 Success。

