
// 更新配置,然后查看 Targets 路径
[root@centos7 57prometheus-k8sobject]# kubectl apply -f prometheus-cm.yaml 
configmap/prometheus-config configured

[root@centos7 57prometheus-k8sobject]# kubectl get svc -n kube-ops
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                          AGE
jenkins      NodePort    10.97.243.51    <none>        8080:30001/TCP,50000:30310/TCP   85d
prometheus   NodePort    10.106.78.77    <none>        9090:30216/TCP                   5d18h
redis        ClusterIP   10.96.158.160   <none>        6379/TCP,9121/TCP                22h

[root@centos7 57prometheus-k8sobject]# curl -X POST "http://10.106.78.77:9090/-/reload"






