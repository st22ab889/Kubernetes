
Kubernetes 私有集群 LoadBalancer 解决方案:
https://blog.csdn.net/qq_24794401/article/details/106581286

关于 Kubernetes中Service使用Metallb实现LoadBalancer的一个Demo:
https://blog.csdn.net/sanhewuyang/article/details/122137905

k8s ingress 暴露端口的方式:
https://www.cnblogs.com/sheng6/p/13889838.html

官方demo:
https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/

================================================================================

// 注意3点:
// 1.traefik 的 service type 要改为 NodePort
// 2.如果要访问 traefik 的 dashboard 要打开 8080 端口
// 3.更改主机的host文件
        192.168.32.100	www.example.com
        192.168.32.101	aaron.example.com

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
NAME                                          READY   STATUS    RESTARTS       AGE
pod/nfs-client-provisioner-7cbb9dc854-xpjvq   1/1     Running   5 (13h ago)    2d23h
pod/static-pod-1-centos7.master               1/1     Running   40 (13h ago)   162d
pod/traefik-7cc89db86f-tfwmk                  1/1     Running   0              10s
pod/whoami-7bdd85cf4b-lqv5x                   1/1     Running   0              10s
pod/whoami-7bdd85cf4b-npqdb                   1/1     Running   0              10s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                       AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP                       190d
service/traefik      NodePort    10.108.121.202   <none>        80:32057/TCP,8080:31878/TCP   10s
service/whoami       ClusterIP   10.104.191.105   <none>        80/TCP                        10s

NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nfs-client-provisioner   1/1     1            1           159d
deployment.apps/traefik                  1/1     1            1           10s
deployment.apps/whoami                   2/2     2            2           10s

NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/nfs-client-provisioner-7cbb9dc854   1         1         1       159d
replicaset.apps/traefik-7cc89db86f                  1         1         1       10s
replicaset.apps/whoami-7bdd85cf4b                   2         2         2       10s

[root@centos7 traefik]# kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP                                     192d
traefik      NodePort    10.108.121.202   <none>        80:32057/TCP,8080:31878/TCP                 33h
whoami       ClusterIP   10.104.191.105   <none>        80/TCP                                      33h


traefik dashboard:
    http://192.168.32.101:31878/
    
访问 whoami 服务:
    http://www.example.com:32057/bar
    http://www.example.com:32057/foo
    http://aaron.example.com:32057/bar
    http://aaron.example.com:32057/foo


