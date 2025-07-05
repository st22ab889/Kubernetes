
--------------------------------------------------------

master
docker pull cnych/kube-apiserver-amd64:v1.10.0
docker pull cnych/kube-scheduler-amd64:v1.10.0
docker pull cnych/kube-controller-manager-amd64:v1.10.0
docker pull cnych/etcd-amd64:3.1.12

common
docker pull cnych/kube-proxy-amd64:v1.10.0
docker pull cnych/k8s-dns-kube-dns-amd64:1.14.8
docker pull cnych/k8s-dns-dnsmasq-nanny-amd64:1.14.8
docker pull cnych/k8s-dns-sidecar-amd64:1.14.8
docker pull cnych/flannel:v0.10.0-amd64
docker pull cnych/pause-amd64:3.1

node
docker pull cnych/kubernetes-dashboard-amd64:v1.8.3
docker pull cnych/heapster-influxdb-amd64:v1.3.3
docker pull cnych/heapster-grafana-amd64:v4.4.3
docker pull cnych/heapster-amd64:v1.4.2

--------------------------------------------------------

下面两个节点都可以访问到kubernetes-dashboard:
https://192.168.32.100:30443/
https://192.168.32.101:30443/


生成TOKEN
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')


eyJhbGciOiJSUzI1NiIsImtpZCI6ImdWOE1QTFdNQTdtZndGUnprZjdfTF9fbDlMTEN5ejRKb1dnSFV3c3Y0UzQifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJkYXNoYm9hcmQtYWRtaW4tdG9rZW4tamhmMmgiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGFzaGJvYXJkLWFkbWluIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiNmJjYTkyMDItZTgyNy00YjBiLWE0NTUtNjQyMTNkZjQwYTI4Iiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOmRhc2hib2FyZC1hZG1pbiJ9.aIw-INoJJ--0WIceDYlTX9bbPNVDz24Qki76sutsXMWb6koBLPCzKq9ktvHnRN1q35gD49yFHsCwmHYb7Ya6C9RtO8nQ4euccvdvLeI5tSzpb5txZxC_0WhqxLFz_uIf7KUae3CQQ8WLlXZu65scZtV40f5ylO_aJ1QcAqviNaS8wYCAXvfIlCqkezi4l90ZCLqZDtQZta2LrPMLTSD8mGAhG11a0HWb6FMCrzw4MdQKRM2uv3sHQs715jQI_hGtgc1V6_-0bgJrLSm92fKhYrA2cAwky_ssaSQiuY3tSqGwlXkmZMU2CUye4pU9KE-1myteKCYV7iJf-aG5i9fkKQ

---------------------------------------------------------------------------

下面两个节点都可以访问到nginx:
http://192.168.32.100:31007/
http://192.168.32.101:31007/

--------------------------------------------------------
Jenkins账号
http://192.168.32.100:30001/
http://192.168.32.101:30001/
aaron
admin000

--------------------------------------------------------

prometheus
http://192.168.32.100:31469
http://192.168.32.101:31469

alertManager
http://192.168.32.100:31828
http://192.168.32.101:31828

grafana(未配置用户名和密码)
http://192.168.32.100:31260
http://192.168.32.101:31260

--------------------------------------------------------
harbor
	https://registry.aaron.com:32656/
	admin
	Harbor123456


查看promethesu进程的limits，发现open file的限制是1024，明显不够:
Prometheus（普罗米修斯）使用过程中遇到的问题：https://www.lijiaocn.com/%E9%97%AE%E9%A2%98/2018/08/03/prometheus-problem.html

两大grafana实用插件快速监控kubernetes
https://www.cnblogs.com/ssgeek/p/12957177.html


----------------------------------------------------------------------------------


[root@centos7 aaron]#  systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
  Drop-In: /usr/lib/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: active (running) since Sun 2021-08-29 08:39:45 EDT; 24min ago
     Docs: https://kubernetes.io/docs/
 Main PID: 21858 (kubelet)
    Tasks: 15
   Memory: 70.2M
   CGroup: /system.slice/kubelet.service
           └─21858 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=cgroupfs --config=/va...

Aug 29 08:39:57 centos7.master kubelet[21858]: E0829 08:39:57.870622   21858 remote_runtime.go:276] "StopContainer from runtime service failed" err="rpc error: code = Unknown de...
Aug 29 08:39:57 centos7.master kubelet[21858]: E0829 08:39:57.870905   21858 kuberuntime_container.go:719] "Container termination failed with gracePeriod" err="rpc error: code =...
Aug 29 08:39:57 centos7.master kubelet[21858]: E0829 08:39:57.870988   21858 kuberuntime_container.go:744] "Kill container failed" err="rpc error: code = Unknown desc = Error re...
Aug 29 08:39:57 centos7.master kubelet[21858]: E0829 08:39:57.875147   21858 kubelet.go:1767] failed to "KillContainer" for "web" with KillContainerError: "rpc error:...473d860442"
Aug 29 08:39:57 centos7.master kubelet[21858]: E0829 08:39:57.875339   21858 pod_workers.go:747] "Error syncing pod, skipping" err="failed to \"KillContainer\" for \"web\" with ...
Aug 29 08:39:57 centos7.master kubelet[21858]: I0829 08:39:57.882079   21858 kubelet_volumes.go:160] "Cleaned up orphaned pod volumes dir" podUID=9935e32793b63066e0e3...18/volumes"
Aug 29 08:39:58 centos7.master kubelet[21858]: I0829 08:39:58.989514   21858 prober_manager.go:255] "Failed to trigger a manual run" probe="Readiness"
Aug 29 08:40:02 centos7.master kubelet[21858]: I0829 08:40:02.958283   21858 prober_manager.go:255] "Failed to trigger a manual run" probe="Readiness"
Aug 29 08:40:45 centos7.master kubelet[21858]: E0829 08:40:45.902144   21858 fsHandler.go:114] failed to collect filesystem stats - rootDiskErr: could not stat "/var/...ea7495bcaed
Aug 29 09:00:54 centos7.master kubelet[21858]: E0829 09:00:54.769189   21858 remote_runtime.go:394] "ExecSync cmd from runtime service failed" err="rpc error: code = ...bird-ready]
Hint: Some lines were ellipsized, use -l to show in full.


---------------------------------------------------------------------------------------

[root@centos7 kubelet.service.d]# cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf 
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=cgroupfs"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
[root@centos7 kubelet.service.d]# 
---------------------------------------------------------------------------------------


Xshell配色美化: https://blog.csdn.net/makersy/article/details/106608936
Xshell 一款很养眼的配色方案推荐: https://www.cnblogs.com/weifeng1463/p/8594319.html
推荐几款比较顺眼的XShell配色方案:https://51.ruyo.net/6304.html
Xshell配色方案大全（250+套）:  https://www.jianshu.com/p/e190ce424e31
xshell美化操作教程之设置护眼背景和字体: https://jingyan.baidu.com/article/11c17a2cdcd4c9f447e39d5e.html
Xshell 7(SSH远程终端工具) v7.0.0076 官方中文正式版(附补丁+安装教程):https://www.jb51.net/softs/732916.html



