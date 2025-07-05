将 http 请求重定向为 https 请求.



[traefik-https-HttpRedirection.zip](attachments/EBD737D0D24642B0A751BBAE9331CC98traefik-https-HttpRedirection.zip)



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
            # 下面三个配置表示监听80端口,将http重定向为https访问
            # detail info: https://doc.traefik.io/traefik/migration/v1-to-v2/#http-to-https-redirection-is-now-configured-on-routers
            - --entrypoints.web.address=:80
            - --entrypoints.web.http.redirections.entrypoint.to=websecure
            - --entrypoints.web.http.redirections.entrypoint.scheme=https
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
    - protocol: TCP
      port: 80
      name: web
      targetPort: 80
```





注意:

```javascript
// 在"traefik.yaml" 中注意如下三个参数：
 
# 表示监听80端口
- --entrypoints.web.address=:80
# 将http重定向为https访问
- --entrypoints.web.http.redirections.entrypoint.to=websecure
- --entrypoints.web.http.redirections.entrypoint.scheme=https

# detail info: https://doc.traefik.io/traefik/migration/v1-to-v2/#http-to-https-redirection-is-now-configured-on-routers     


[root@centos7 traefik-https]# kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP                      196d
traefik      NodePort    10.103.234.13   <none>        443:32257/TCP,80:31293/TCP   22h
whoami       ClusterIP   10.100.188.73   <none>        80/TCP                       22h

// 示例说明：
    访问：
    	http://www.example.com:31293/bar
    会跳转到(因为https的默认端口号是443,所以跳转到的https链接没有显示端口号)：
    	https://www.example.com/bar   
```

