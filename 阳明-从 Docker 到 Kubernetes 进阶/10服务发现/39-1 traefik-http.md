

[traefik-http.zip](attachments/E20BCB56DA4D420FAB58A29C7A417563traefik-http.zip)



```javascript
# rbac.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses/status
    verbs:
      - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
  - kind: ServiceAccount
    name: traefik-ingress-controller
    namespace: default
```



```javascript
# whoami.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  labels:
    app: traefiklabs
    name: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: traefiklabs
      task: whoami
  template:
    metadata:
      labels:
        app: traefiklabs
        task: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami

spec:
  ports:
    - name: http
      port: 80
  selector:
    app: traefiklabs
    task: whoami
```



```javascript
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myingress
  # 注释下面的 annotations 没有影响
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web

spec:
  rules:
    #- host: example.com
    - host: "*.example.com"
      http:
        paths:
          - path: /bar
            pathType: Exact
            backend:
              service:
                name:  whoami
                port:
                  number: 80
          - path: /foo
            pathType: Exact
            backend:
              service:
                name:  whoami
                port:
                  number: 80
```



```javascript
# traefik.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-ingress-controller

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  labels:
    app: traefik

spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-ingress-controller
      containers:
        - name: traefik
          image: traefik:v2.6
          imagePullPolicy: IfNotPresent
          args:
            # 下面这个参数和whoamI这个服务有关
            - --entrypoints.web.address=:80
            #- --providers.kubernetesingress   # 这个默认值是true,一定要有这个参数,否则不能发现k8s服务
            - --providers.kubernetesingress=true
            # 如果缺少下面的参数不能访问到 dashboard, 但是不影响访问服务
            - --api.insecure=true
          ports:
            - name: web
              containerPort: 80
            - name: dashboard
              containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
spec:
  # 一般在机房或者云上使用ECS(Elastic Compute Service)自建Kubernetes集群是无法使用 LoadBalancer 类型的 Service.
  # 因为 Kubernetes 本身没有为裸机群集提供网络负载均衡器的实现. MetalLB是一个负载均衡器,专门解决自建 k8s 集群中无法使用 LoadBalancer 类型服务的痛点
  #type: LoadBalancer
  type: NodePort
  selector:
    app: traefik
  ports:
    # 这个端口和配置whoami访问路径的ingress有关
    - protocol: TCP
      port: 80
      name: web
      targetPort: 80
    # 这个端口应用在traefik的dashboard上
    - protocol: TCP
      name: dashboard
      port: 8080  
```



1. 注意3点

(1).traefik 的 service type 要改为 NodePort。

(2).如果要访问 traefik 的 dashboard 要打开 8080 端口。

(3).因为 ingress.yaml 文件中配置了 host: "*.example.com"，所以这里只能通过域名访问((ingress就是通过域名来访问)，需要更改主机的host文件。

        192.168.32.100  www.example.com

        192.168.32.101  aaron.example.com





2. 安装和使用 traefik

```javascript
[root@centos7 traefik]# kubectl create -f .
ingress.networking.k8s.io/myingress created
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller created
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller created
serviceaccount/traefik-ingress-controller created
deployment.apps/traefik created
service/traefik created
deployment.apps/whoami created
service/whoami created

[root@centos7 traefik]# kubectl get all
NAME                                          READY   STATUS    RESTARTS       AGE
pod/nfs-client-provisioner-7cbb9dc854-xpjvq   1/1     Running   5 (13h ago)    2d23h
pod/static-pod-1-centos7.master               1/1     Running   40 (13h ago)   162d
pod/traefik-7cc89db86f-tfwmk                  1/1     Running   0              10s
pod/whoami-7bdd85cf4b-lqv5x                   1/1     Running   0              10s
pod/whoami-7bdd85cf4b-npqdb                   1/1     Running   0              10s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                       AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP                       190d
service/traefik      NodePort    10.108.121.202   <none>        80:32057/TCP,8080:31878/TCP   10s
service/whoami       ClusterIP   10.104.191.105   <none>        80/TCP                        10s

NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nfs-client-provisioner   1/1     1            1           159d
deployment.apps/traefik                  1/1     1            1           10s
deployment.apps/whoami                   2/2     2            2           10s

NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/nfs-client-provisioner-7cbb9dc854   1         1         1       159d
replicaset.apps/traefik-7cc89db86f                  1         1         1       10s
replicaset.apps/whoami-7bdd85cf4b                   2         2         2       10s

[root@centos7 traefik]# kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP                                     192d
traefik      NodePort    10.108.121.202   <none>        80:32057/TCP,8080:31878/TCP                 33h
whoami       ClusterIP   10.104.191.105   <none>        80/TCP                                      33h 
```



traefik dashboard: 因为 traefik 的 insecure方式(http) 是通过8080端口访问。这个端口对应的 NodePort 端口是31878。

    http://192.168.32.101:31878/



访问 whoami 服务: ingress 监听 *.example.com 这个域名，这个域名对应的是 whoami 服务，traefik 监听80端口(也就是说通过这个端口进来的衔接都会通过ingress去路由)，traefik 服务是  NodePort 类型服务，这个服务暴露的80端口对应的 NodePort 端口是 32057。

    http://www.example.com:32057/bar

    http://www.example.com:32057/foo

    http://aaron.example.com:32057/bar

    http://aaron.example.com:32057/foo





3. 参考资料



Kubernetes 私有集群 LoadBalancer 解决方案:

https://blog.csdn.net/qq_24794401/article/details/106581286



关于 Kubernetes中Service使用Metallb实现LoadBalancer的一个Demo:

https://blog.csdn.net/sanhewuyang/article/details/122137905



k8s ingress 暴露端口的方式:

https://www.cnblogs.com/sheng6/p/13889838.html



官方demo:

https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/

