

[traefik-https.zip](attachments/340B7AE1F913428085EE85EE6F0D16ECtraefik-https.zip)



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
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure

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
          args:
            - --entrypoints.websecure.address=:443
            - --entrypoints.websecure.http.tls
            - --providers.kubernetesingress
            - --api.dashboard=true
            - --providers.file.directory=/path/to/dynamic/conf
            # disables SSL certificate verification. 
            # detail info: https://doc.traefik.io/traefik/routing/overview/#transport-configuration
            - --serversTransport.insecureSkipVerify=true
          ports:
            - name: websecure
              containerPort: 443
          volumeMounts:
            - name: dynamic-conf
              mountPath: /path/to/dynamic/conf
      volumes:
      - name: dynamic-conf
        configMap:
          name: traefik-dynamic-conf
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
spec:
  # type: LoadBalancer
  type: NodePort
  selector:
    app: traefik
  ports:
    - protocol: TCP
      port: 443
      name: websecure
      targetPort: 443
```



```javascript
# traefik-dynamic-conf.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
   name: traefik-dynamic-conf
data:
  traefik.yaml: |
    # Traefik Dynamic Configuration
    http:
      routers:
        dashboard:
          rule: Host(`traefik.aaron.com`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))
          service: api@internal
          middlewares:
            - auth
      middlewares:
        auth:
          basicAuth:
            users:
              - "test:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/"
              - "test2:$apr1$d9hr9HBB$4HxwgUir3HP4EsggP/QNo0"
```



1. 注意3点

(1) traefik 的 service type 要改为 NodePort。

(2) 因为这里是通过TLS访问 traefik-dashboard, 所以需要通过 traefik 的动态配置方式才能访问 dashboard, 这里将动态配置文件放入到 ConfigMap 中, 然后通过数据卷的方式挂载 ConfigMap 到 pod 中。

(3) "traefik-dynamic-conf.yaml"中的动态配置说明:

```javascript
# traefik-dynamic-conf.yaml
//......    
    # Traefik Dynamic Configuration
    http:
      routers:
        dashboard:
          # 这个配置说明只能通过 http://traefik.aaron.com/dashboard/ 这个路径访问
          # 所以需要在主机hosts文件中配置域名,例如： 192.168.32.100  traefik.aaron.com
          rule: Host(`traefik.aaron.com`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))
          service: api@internal
          middlewares:
            # 说明访问 dashboard 需要通过 ahth 验证
            - auth
      middlewares:
        auth:
          basicAuth:
            # 说明是通过用户名密码的方式认证            
            users:
              # 用户名和密码都是test,这里是使用"htpasswd"生成密码
              - "test:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/"
              # 用户名和密码都是test2
              - "test2:$apr1$d9hr9HBB$4HxwgUir3HP4EsggP/QNo0"
```





2. 安装和使用 traefik

```javascript
[root@centos7 traefik-https]# kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
traefik      NodePort    10.108.121.202   <none>        443:30646/TCP   2d4h
whoami       ClusterIP   10.104.191.105   <none>        80/TCP          2d4h
```



traefik dashboard (注意路径最后的"/"，少了"/"页面会出现404):       

    https://traefik.aaron.com:30646/dashboard/



访问 whoami 服务: ingress 监听 *.example.com 这个域名，这个域名对应的是 whoami 服务，traefik 监听443端口(也就是说通过这个端口进来的衔接都会通过ingress去路由)，traefik 服务是  NodePort 类型服务，这个服务暴露的443端口对应的 NodePort 端口是 30646。

    https://www.example.com:30646/bar

    https://www.example.com:30646/foo

    https://aaron.example.com:30646/bar

    https://aaron.example.com:30646/foo





3. 参考资料

Traefik & Kubernetes TLS DEMO:

https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#tls



开启 traefik dashboard 的方法(http和https开启的方式不一样):

https://doc.traefik.io/traefik/operations/dashboard/



traefik 配置文件引入方法:

https://doc.traefik.io/traefik/providers/file/



Configuration Introduction

https://doc.traefik.io/traefik/getting-started/configuration-overview/



basicauth

https://doc.traefik.io/traefik/middlewares/http/basicauth/#usersfile











