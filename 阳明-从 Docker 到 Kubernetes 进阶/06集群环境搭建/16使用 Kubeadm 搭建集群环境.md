1. 课程中用的kubeadm版本是1.10.0-0, 当前版本是1.22.1-0,配置kubelet的"--cgroup-driver"为cgroupfs有区别: 



kubelet 1.10.0-0 版本改配置文件路径为:

```javascript
/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```



kubelet  1.22.1-0 版本改配置文件路径为:

```javascript
/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

// lib 目录其实就是指向 /usr/lib 目录
lrwxrwxrwx.   1 root root    8 Aug 20 07:20 sbin -> usr/sbin
```



改yaml文件，/var/lib/kubelet/config.yaml 中cgroupDriver的值指定为“cgroupfs”.

```javascript
[root@centos7 /]# cat /var/lib/kubelet/config.yaml 
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging: {}
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
rotateCertificates: true
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
[root@centos7 53 install prometheus]#
```





[1 安装 k8s 的准备工作.md](attachments/DA4E476FE3284E56A5DA8B30D74CA9661 安装 k8s 的准备工作.md)



[2 在master和node节点安装k8s.md](attachments/B1C1D3A8138E48FE892CB8ECEDDC82232 在master和node节点安装k8s.md)



[3 访问DashBoard的Token.md](attachments/57E53452D94D425BBBE2097FC1A2C0613 访问DashBoard的Token.md)





