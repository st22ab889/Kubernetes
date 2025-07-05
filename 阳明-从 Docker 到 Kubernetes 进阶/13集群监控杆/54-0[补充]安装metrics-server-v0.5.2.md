1. 下载 components.yaml 文件

```javascript

// components.yaml: 用这个文件安装
https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

// GitHub metrics-server: 
https://github.com/kubernetes-sigs/metrics-server

// GitHub metrics-server releases:
https://github.com/kubernetes-sigs/metrics-server/releases

// Kubernetes doc:
https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/

// kubernetes/kubernetes中GitHub源码下的metrics-server YAML 文件
// 用这下面的 YAML 文件安装报"OCI runtime create failed: ......"错误
https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/metrics-server

// 下面两个metrics-server 的区别? 
// kubernetes/cluster/addons/metrics-server/ 和 kubernetes-sigs/metrics-server

```







2. 给 components.yaml 文件增加配置



在args中增加"--kubelet-insecure-tls"参数

[components.yaml](attachments/3912CDEC91F54DA88D80D67424CA78C4components.yaml)

```javascript
# components.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-view: "true"
  name: system:aggregated-metrics-reader
rules:
- apiGroups:
  - metrics.k8s.io
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  - nodes/stats
  - namespaces
  - configmaps
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    k8s-app: metrics-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        image: k8s.gcr.io/metrics-server/metrics-server:v0.5.2
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 4443
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
---
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  labels:
    k8s-app: metrics-server
  name: v1beta1.metrics.k8s.io
spec:
  group: metrics.k8s.io
  groupPriorityMinimum: 100
  insecureSkipTLSVerify: true
  service:
    name: metrics-server
    namespace: kube-system
  version: v1beta1
  versionPriority: 100

```



```javascript
// bitnami/metrics-server:  
// https://hub.docker.com/r/bitnami/metrics-server/tags

docker pull bitnami/metrics-server:0.5.2
docker tag bitnami/metrics-server:0.5.2 k8s.gcr.io/metrics-server/metrics-server:v0.5.2

kubectl create -f components.yaml
kubectl get pod -n kube-system -o wide
kubectl top pod daemonset-demo-znkw8
kubectl top node
kubectl top pod

```



```javascript
[root@centos7 metrics-server-v0.5.2]# kubectl top node
NAME             CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
centos7.master   433m         21%    1556Mi          42%       
centos7.node     287m         14%    1754Mi          47%       
[root@centos7 metrics-server-v0.5.2]# kubectl top pod -n kube-system
NAME                                       CPU(cores)   MEMORY(bytes)   
......         
kube-scheduler-centos7.master              6m           26Mi            
metrics-server-5b6dd75459-wjkhn            10m          13Mi            
[root@centos7 metrics-server-v0.5.2]# kubectl top pod -n kube-ops
NAME                       CPU(cores)   MEMORY(bytes)   
jenkins-85db8588bd-tjsn5   10m          419Mi           
[root@centos7 metrics-server-v0.5.2]# kubectl top pod 
NAME                                         CPU(cores)   MEMORY(bytes)               
helm-demo-mysql-0                            11m          438Mi           
helm-demo-nginx-hello-helm-75cbc4c7b-xkl2k   1m           1Mi             
......         
[root@centos7 metrics-server-v0.5.2]# kubectl top pod kube-scheduler-centos7.master -n kube-system
NAME                            CPU(cores)   MEMORY(bytes)   
kube-scheduler-centos7.master   6m           26Mi            
[root@centos7 metrics-server-v0.5.2]# 
```





不增加"--kubelet-insecure-tls"参数会包如下错误(证书错误):

```javascript
[root@centos7 metrics-server-v0.5.2]# kubectl get pod -n kube-system | grep metrics
metrics-server-dbf765b9b-b8k4k             0/1     Running   0                35s

[root@centos7 metrics-server-v0.5.2]# kubectl describe pod metrics-server-dbf765b9b-b8k4k -n kube-system
Name:                 metrics-server-dbf765b9b-b8k4k
Namespace:            kube-system
......
Containers:
  metrics-server:
    ......
    Liveness:     http-get https://:https/livez delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get https://:https/readyz delay=20s timeout=1s period=10s #success=1 #failure=3
    ......
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  ......
  Warning  Unhealthy  1s (x8 over 61s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 500

[root@centos7 metrics-server-v0.5.2]# kubectl logs -f metrics-server-dbf765b9b-b8k4k -n kube-system
I1212 08:26:40.106285       1 serving.go:341] Generated self-signed cert (/tmp/apiserver.crt, /tmp/apiserver.key)
E1212 08:26:41.083719       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.32.101:10250/stats/summary?only_cpu_and_memory=true\": x509: cannot validate certificate for 192.168.32.101 because it doesn't contain any IP SANs" node="centos7.node"
I1212 08:26:41.084435       1 secure_serving.go:202] Serving securely on [::]:4443
I1212 08:26:41.084531       1 requestheader_controller.go:169] Starting RequestHeaderAuthRequestController
I1212 08:26:41.084540       1 shared_informer.go:240] Waiting for caches to sync for RequestHeaderAuthRequestController
I1212 08:26:41.084553       1 dynamic_serving_content.go:130] Starting serving-cert::/tmp/apiserver.crt::/tmp/apiserver.key
I1212 08:26:41.084593       1 tlsconfig.go:240] Starting DynamicServingCertificateController
I1212 08:26:41.084926       1 configmap_cafile_content.go:202] Starting client-ca::kube-system::extension-apiserver-authentication::client-ca-file
I1212 08:26:41.084935       1 shared_informer.go:240] Waiting for caches to sync for client-ca::kube-system::extension-apiserver-authentication::client-ca-file
I1212 08:26:41.084965       1 configmap_cafile_content.go:202] Starting client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file
I1212 08:26:41.084972       1 shared_informer.go:240] Waiting for caches to sync for client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file
E1212 08:26:41.085795       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.32.100:10250/stats/summary?only_cpu_and_memory=true\": x509: cannot validate certificate for 192.168.32.100 because it doesn't contain any IP SANs" node="centos7.master"
I1212 08:26:41.184945       1 shared_informer.go:247] Caches are synced for RequestHeaderAuthRequestController 
I1212 08:26:41.185697       1 shared_informer.go:247] Caches are synced for client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file 
I1212 08:26:41.185770       1 shared_informer.go:247] Caches are synced for client-ca::kube-system::extension-apiserver-authentication::client-ca-file 
E1212 08:26:56.077780       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.32.101:10250/stats/summary?only_cpu_and_memory=true\": x509: cannot validate certificate for 192.168.32.101 because it doesn't contain any IP SANs" node="centos7.node"
E1212 08:26:56.082198       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.32.100:10250/stats/summary?only_cpu_and_memory=true\": x509: cannot validate certificate for 192.168.32.100 because it doesn't contain any IP SANs" node="centos7.master"
I1212 08:27:08.541138       1 server.go:188] "Failed probe" probe="metric-storage-ready" err="not metrics to serve"
......
```







3. 参考资料



K8S 资源指标监控-部署metrics-server

https://blog.csdn.net/wangmiaoyan/article/details/102868728



K8s容器资源限制     

https://www.cnblogs.com/wn1m/p/11291235.html



