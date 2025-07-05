

[aaron@centos7 ~]$ sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.ustc.edu.cn
 * extras: mirrors.ustc.edu.cn
 * updates: mirrors.ustc.edu.cn
base                                                                       | 3.6 kB  00:00:00     
docker-ce-stable                                                           | 3.5 kB  00:00:00     
docker-ce-test                                                             | 3.5 kB  00:00:00     
extras                                                                     | 2.9 kB  00:00:00     
kubernetes/signature                                                       |  844 B  00:00:00     
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Importing GPG key 0x307EA071:
 Userid     : "Rapture Automatic Signing Key (cloud-rapture-signing-key-2021-03-01-08_01_09.pub)"
 Fingerprint: 7f92 e05b 3109 3bef 5a3c 2d38 feea 9169 307e a071
 From       : https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
kubernetes/signature                                                       | 1.4 kB  00:00:00 !!! 
updates                                                                    | 2.9 kB  00:00:00     
kubernetes/primary                                                         |  95 kB  00:00:00     
kubernetes                                                                                702/702
Resolving Dependencies
--> Running transaction check
---> Package kubeadm.x86_64 0:1.22.1-0 will be installed
--> Processing Dependency: kubernetes-cni >= 0.8.6 for package: kubeadm-1.22.1-0.x86_64
--> Processing Dependency: cri-tools >= 1.13.0 for package: kubeadm-1.22.1-0.x86_64
---> Package kubectl.x86_64 0:1.22.1-0 will be installed
---> Package kubelet.x86_64 0:1.22.1-0 will be installed
--> Processing Dependency: socat for package: kubelet-1.22.1-0.x86_64
--> Processing Dependency: conntrack for package: kubelet-1.22.1-0.x86_64
--> Running transaction check
---> Package conntrack-tools.x86_64 0:1.4.4-7.el7 will be installed
--> Processing Dependency: libnetfilter_cttimeout.so.1(LIBNETFILTER_CTTIMEOUT_1.1)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cttimeout.so.1(LIBNETFILTER_CTTIMEOUT_1.0)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cthelper.so.0(LIBNETFILTER_CTHELPER_1.0)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_queue.so.1()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cttimeout.so.1()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cthelper.so.0()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
---> Package cri-tools.x86_64 0:1.13.0-0 will be installed
---> Package kubernetes-cni.x86_64 0:0.8.7-0 will be installed
---> Package socat.x86_64 0:1.7.3.2-2.el7 will be installed
--> Running transaction check
---> Package libnetfilter_cthelper.x86_64 0:1.0.0-11.el7 will be installed
---> Package libnetfilter_cttimeout.x86_64 0:1.0.0-7.el7 will be installed
---> Package libnetfilter_queue.x86_64 0:1.0.2-2.el7_2 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==================================================================================================
 Package                         Arch            Version                Repository           Size
==================================================================================================
Installing:
 kubeadm                         x86_64          1.22.1-0               kubernetes          9.3 M
 kubectl                         x86_64          1.22.1-0               kubernetes          9.6 M
 kubelet                         x86_64          1.22.1-0               kubernetes           23 M
Installing for dependencies:
 conntrack-tools                 x86_64          1.4.4-7.el7            base                187 k
 cri-tools                       x86_64          1.13.0-0               kubernetes          5.1 M
 kubernetes-cni                  x86_64          0.8.7-0                kubernetes           19 M
 libnetfilter_cthelper           x86_64          1.0.0-11.el7           base                 18 k
 libnetfilter_cttimeout          x86_64          1.0.0-7.el7            base                 18 k
 libnetfilter_queue              x86_64          1.0.2-2.el7_2          base                 23 k
 socat                           x86_64          1.7.3.2-2.el7          base                290 k

Transaction Summary
==================================================================================================
Install  3 Packages (+7 Dependent packages)

Total download size: 67 M
Installed size: 313 M
Downloading packages:
(1/10): conntrack-tools-1.4.4-7.el7.x86_64.rpm                             | 187 kB  00:00:00     
warning: /var/cache/yum/x86_64/7/kubernetes/packages/14bfe6e75a9efc8eca3f638eb22c7e2ce759c67f95b43b16fae4ebabde1549f3-cri-tools-1.13.0-0.x86_64.rpm: Header V4 RSA/SHA512 Signature, key ID 3e1ba8d5: NOKEY
Public key for 14bfe6e75a9efc8eca3f638eb22c7e2ce759c67f95b43b16fae4ebabde1549f3-cri-tools-1.13.0-0.x86_64.rpm is not installed
(2/10): 14bfe6e75a9efc8eca3f638eb22c7e2ce759c67f95b43b16fae4ebabde1549f3-c | 5.1 MB  00:00:09     
(3/10): 85f74ea1d2a4966b78abec7a9bdc8733d15c42ba2846be798de2229fec82d375-k | 9.3 MB  00:00:17     
(4/10): 44f1e20edafb61bae2cbc459cfe421e5d837ea2349e712b54103b13b38ebb87b-k | 9.6 MB  00:00:17     
(5/10): libnetfilter_cthelper-1.0.0-11.el7.x86_64.rpm                      |  18 kB  00:00:00     
(6/10): libnetfilter_cttimeout-1.0.0-7.el7.x86_64.rpm                      |  18 kB  00:00:01     
(7/10): libnetfilter_queue-1.0.2-2.el7_2.x86_64.rpm                        |  23 kB  00:00:02     
(8/10): socat-1.7.3.2-2.el7.x86_64.rpm                                     | 290 kB  00:00:01     
(9/10): d28d0aca2d81f55ad346f0bffb166b8a5ddb9c9590ee7227ab4b1788bffe1613-k |  23 MB  00:00:42     
(10/10): db7cb5cb0b3f6875f54d10f02e625573988e3e91fd4fc5eef0b1876bb18604ad- |  19 MB  00:00:33     
--------------------------------------------------------------------------------------------------
Total                                                             1.1 MB/s |  67 MB  00:01:00     
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Importing GPG key 0x307EA071:
 Userid     : "Rapture Automatic Signing Key (cloud-rapture-signing-key-2021-03-01-08_01_09.pub)"
 Fingerprint: 7f92 e05b 3109 3bef 5a3c 2d38 feea 9169 307e a071
 From       : https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
Importing GPG key 0x3E1BA8D5:
 Userid     : "Google Cloud Packages RPM Signing Key <gc-team@google.com>"
 Fingerprint: 3749 e1ba 95a8 6ce0 5454 6ed2 f09c 394c 3e1b a8d5
 From       : https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : libnetfilter_cthelper-1.0.0-11.el7.x86_64                                     1/10 
  Installing : socat-1.7.3.2-2.el7.x86_64                                                    2/10 
  Installing : libnetfilter_cttimeout-1.0.0-7.el7.x86_64                                     3/10 
  Installing : kubectl-1.22.1-0.x86_64                                                       4/10 
  Installing : cri-tools-1.13.0-0.x86_64                                                     5/10 
  Installing : libnetfilter_queue-1.0.2-2.el7_2.x86_64                                       6/10 
  Installing : conntrack-tools-1.4.4-7.el7.x86_64                                            7/10 
  Installing : kubernetes-cni-0.8.7-0.x86_64                                                 8/10 
  Installing : kubelet-1.22.1-0.x86_64                                                       9/10 
  Installing : kubeadm-1.22.1-0.x86_64                                                      10/10 
  Verifying  : kubelet-1.22.1-0.x86_64                                                       1/10 
  Verifying  : kubernetes-cni-0.8.7-0.x86_64                                                 2/10 
  Verifying  : kubeadm-1.22.1-0.x86_64                                                       3/10 
  Verifying  : libnetfilter_queue-1.0.2-2.el7_2.x86_64                                       4/10 
  Verifying  : cri-tools-1.13.0-0.x86_64                                                     5/10 
  Verifying  : kubectl-1.22.1-0.x86_64                                                       6/10 
  Verifying  : libnetfilter_cttimeout-1.0.0-7.el7.x86_64                                     7/10 
  Verifying  : socat-1.7.3.2-2.el7.x86_64                                                    8/10 
  Verifying  : libnetfilter_cthelper-1.0.0-11.el7.x86_64                                     9/10 
  Verifying  : conntrack-tools-1.4.4-7.el7.x86_64                                           10/10 

Installed:
  kubeadm.x86_64 0:1.22.1-0       kubectl.x86_64 0:1.22.1-0       kubelet.x86_64 0:1.22.1-0      

Dependency Installed:
  conntrack-tools.x86_64 0:1.4.4-7.el7            cri-tools.x86_64 0:1.13.0-0                    
  kubernetes-cni.x86_64 0:0.8.7-0                 libnetfilter_cthelper.x86_64 0:1.0.0-11.el7    
  libnetfilter_cttimeout.x86_64 0:1.0.0-7.el7     libnetfilter_queue.x86_64 0:1.0.2-2.el7_2      
  socat.x86_64 0:1.7.3.2-2.el7                   

Complete!

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

[aaron@centos7 ~]$ sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.ustc.edu.cn
 * extras: mirrors.ustc.edu.cn
 * updates: mirrors.ustc.edu.cn
base                                                                       | 3.6 kB  00:00:00     
docker-ce-stable                                                           | 3.5 kB  00:00:00     
docker-ce-test                                                             | 3.5 kB  00:00:00     
extras                                                                     | 2.9 kB  00:00:00     
kubernetes/signature                                                       |  844 B  00:00:00     
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Importing GPG key 0x307EA071:
 Userid     : "Rapture Automatic Signing Key (cloud-rapture-signing-key-2021-03-01-08_01_09.pub)"
 Fingerprint: 7f92 e05b 3109 3bef 5a3c 2d38 feea 9169 307e a071
 From       : https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
kubernetes/signature                                                       | 1.4 kB  00:00:00 !!! 
updates                                                                    | 2.9 kB  00:00:00     
kubernetes/primary                                                         |  95 kB  00:00:00     
kubernetes                                                                                702/702
Resolving Dependencies
--> Running transaction check
---> Package kubeadm.x86_64 0:1.22.1-0 will be installed
--> Processing Dependency: kubernetes-cni >= 0.8.6 for package: kubeadm-1.22.1-0.x86_64
--> Processing Dependency: cri-tools >= 1.13.0 for package: kubeadm-1.22.1-0.x86_64
---> Package kubectl.x86_64 0:1.22.1-0 will be installed
---> Package kubelet.x86_64 0:1.22.1-0 will be installed
--> Processing Dependency: socat for package: kubelet-1.22.1-0.x86_64
--> Processing Dependency: conntrack for package: kubelet-1.22.1-0.x86_64
--> Running transaction check
---> Package conntrack-tools.x86_64 0:1.4.4-7.el7 will be installed
--> Processing Dependency: libnetfilter_cttimeout.so.1(LIBNETFILTER_CTTIMEOUT_1.1)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cttimeout.so.1(LIBNETFILTER_CTTIMEOUT_1.0)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cthelper.so.0(LIBNETFILTER_CTHELPER_1.0)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_queue.so.1()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cttimeout.so.1()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cthelper.so.0()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
---> Package cri-tools.x86_64 0:1.13.0-0 will be installed
---> Package kubernetes-cni.x86_64 0:0.8.7-0 will be installed
---> Package socat.x86_64 0:1.7.3.2-2.el7 will be installed
--> Running transaction check
---> Package libnetfilter_cthelper.x86_64 0:1.0.0-11.el7 will be installed
---> Package libnetfilter_cttimeout.x86_64 0:1.0.0-7.el7 will be installed
---> Package libnetfilter_queue.x86_64 0:1.0.2-2.el7_2 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==================================================================================================
 Package                         Arch            Version                Repository           Size
==================================================================================================
Installing:
 kubeadm                         x86_64          1.22.1-0               kubernetes          9.3 M
 kubectl                         x86_64          1.22.1-0               kubernetes          9.6 M
 kubelet                         x86_64          1.22.1-0               kubernetes           23 M
Installing for dependencies:
 conntrack-tools                 x86_64          1.4.4-7.el7            base                187 k
 cri-tools                       x86_64          1.13.0-0               kubernetes          5.1 M
 kubernetes-cni                  x86_64          0.8.7-0                kubernetes           19 M
 libnetfilter_cthelper           x86_64          1.0.0-11.el7           base                 18 k
 libnetfilter_cttimeout          x86_64          1.0.0-7.el7            base                 18 k
 libnetfilter_queue              x86_64          1.0.2-2.el7_2          base                 23 k
 socat                           x86_64          1.7.3.2-2.el7          base                290 k

Transaction Summary
==================================================================================================
Install  3 Packages (+7 Dependent packages)

Total download size: 67 M
Installed size: 313 M
Downloading packages:
(1/10): conntrack-tools-1.4.4-7.el7.x86_64.rpm                             | 187 kB  00:00:00     
warning: /var/cache/yum/x86_64/7/kubernetes/packages/14bfe6e75a9efc8eca3f638eb22c7e2ce759c67f95b43b16fae4ebabde1549f3-cri-tools-1.13.0-0.x86_64.rpm: Header V4 RSA/SHA512 Signature, key ID 3e1ba8d5: NOKEY
Public key for 14bfe6e75a9efc8eca3f638eb22c7e2ce759c67f95b43b16fae4ebabde1549f3-cri-tools-1.13.0-0.x86_64.rpm is not installed
(2/10): 14bfe6e75a9efc8eca3f638eb22c7e2ce759c67f95b43b16fae4ebabde1549f3-c | 5.1 MB  00:00:08     
(3/10): 85f74ea1d2a4966b78abec7a9bdc8733d15c42ba2846be798de2229fec82d375-k | 9.3 MB  00:00:16     
(4/10): 44f1e20edafb61bae2cbc459cfe421e5d837ea2349e712b54103b13b38ebb87b-k | 9.6 MB  00:00:27     
(5/10): libnetfilter_cthelper-1.0.0-11.el7.x86_64.rpm                      |  18 kB  00:00:01     
(6/10): libnetfilter_cttimeout-1.0.0-7.el7.x86_64.rpm                      |  18 kB  00:00:02     
(7/10): libnetfilter_queue-1.0.2-2.el7_2.x86_64.rpm                        |  23 kB  00:00:02     
(8/10): socat-1.7.3.2-2.el7.x86_64.rpm                                     | 290 kB  00:00:02     
(9/10): d28d0aca2d81f55ad346f0bffb166b8a5ddb9c9590ee7227ab4b1788bffe1613-k |  23 MB  00:00:28     
(10/10): db7cb5cb0b3f6875f54d10f02e625573988e3e91fd4fc5eef0b1876bb18604ad- |  19 MB  00:00:23     
--------------------------------------------------------------------------------------------------
Total                                                             1.1 MB/s |  67 MB  00:01:00     
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Importing GPG key 0x307EA071:
 Userid     : "Rapture Automatic Signing Key (cloud-rapture-signing-key-2021-03-01-08_01_09.pub)"
 Fingerprint: 7f92 e05b 3109 3bef 5a3c 2d38 feea 9169 307e a071
 From       : https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
Retrieving key from https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
Importing GPG key 0x3E1BA8D5:
 Userid     : "Google Cloud Packages RPM Signing Key <gc-team@google.com>"
 Fingerprint: 3749 e1ba 95a8 6ce0 5454 6ed2 f09c 394c 3e1b a8d5
 From       : https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : libnetfilter_cthelper-1.0.0-11.el7.x86_64                                     1/10 
  Installing : socat-1.7.3.2-2.el7.x86_64                                                    2/10 
  Installing : libnetfilter_cttimeout-1.0.0-7.el7.x86_64                                     3/10 
  Installing : kubectl-1.22.1-0.x86_64                                                       4/10 
  Installing : cri-tools-1.13.0-0.x86_64                                                     5/10 
  Installing : libnetfilter_queue-1.0.2-2.el7_2.x86_64                                       6/10 
  Installing : conntrack-tools-1.4.4-7.el7.x86_64                                            7/10 
  Installing : kubernetes-cni-0.8.7-0.x86_64                                                 8/10 
  Installing : kubelet-1.22.1-0.x86_64                                                       9/10 
  Installing : kubeadm-1.22.1-0.x86_64                                                      10/10 
  Verifying  : kubelet-1.22.1-0.x86_64                                                       1/10 
  Verifying  : kubernetes-cni-0.8.7-0.x86_64                                                 2/10 
  Verifying  : kubeadm-1.22.1-0.x86_64                                                       3/10 
  Verifying  : libnetfilter_queue-1.0.2-2.el7_2.x86_64                                       4/10 
  Verifying  : cri-tools-1.13.0-0.x86_64                                                     5/10 
  Verifying  : kubectl-1.22.1-0.x86_64                                                       6/10 
  Verifying  : libnetfilter_cttimeout-1.0.0-7.el7.x86_64                                     7/10 
  Verifying  : socat-1.7.3.2-2.el7.x86_64                                                    8/10 
  Verifying  : libnetfilter_cthelper-1.0.0-11.el7.x86_64                                     9/10 
  Verifying  : conntrack-tools-1.4.4-7.el7.x86_64                                           10/10 

Installed:
  kubeadm.x86_64 0:1.22.1-0       kubectl.x86_64 0:1.22.1-0       kubelet.x86_64 0:1.22.1-0      

Dependency Installed:
  conntrack-tools.x86_64 0:1.4.4-7.el7            cri-tools.x86_64 0:1.13.0-0                    
  kubernetes-cni.x86_64 0:0.8.7-0                 libnetfilter_cthelper.x86_64 0:1.0.0-11.el7    
  libnetfilter_cttimeout.x86_64 0:1.0.0-7.el7     libnetfilter_queue.x86_64 0:1.0.2-2.el7_2      
  socat.x86_64 0:1.7.3.2-2.el7   

=====================================================================================================================================

[root@centos7 aaron]# sudo kubeadm init \
>    --apiserver-advertise-address=192.168.32.100 \
>    --image-repository registry.aliyuncs.com/google_containers \
>    --kubernetes-version v1.22.1 \
>    --service-cidr=10.96.0.0/12 \
>    --pod-network-cidr=10.244.0.0/16 \
>    --ignore-preflight-errors=all
[init] Using Kubernetes version: v1.22.1
[preflight] Running pre-flight checks
	[WARNING Port-6443]: Port 6443 is in use
	[WARNING Port-10259]: Port 10259 is in use
	[WARNING Port-10257]: Port 10257 is in use
	[WARNING FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml]: /etc/kubernetes/manifests/kube-apiserver.yaml already exists
	[WARNING FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml]: /etc/kubernetes/manifests/kube-controller-manager.yaml already exists
	[WARNING FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml]: /etc/kubernetes/manifests/kube-scheduler.yaml already exists
	[WARNING FileAvailable--etc-kubernetes-manifests-etcd.yaml]: /etc/kubernetes/manifests/etcd.yaml already exists
	[WARNING Port-10250]: Port 10250 is in use
	[WARNING Port-2379]: Port 2379 is in use
	[WARNING Port-2380]: Port 2380 is in use
	[WARNING DirAvailable--var-lib-etcd]: /var/lib/etcd is not empty
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
	[WARNING ImagePull]: failed to pull image registry.aliyuncs.com/google_containers/coredns:v1.8.4: output: Error response from daemon: manifest for registry.aliyuncs.com/google_containers/coredns:v1.8.4 not found: manifest unknown: manifest unknown
, error: exit status 1
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Using existing ca certificate authority
[certs] Using existing apiserver certificate and key on disk
[certs] Using existing apiserver-kubelet-client certificate and key on disk
[certs] Using existing front-proxy-ca certificate authority
[certs] Using existing front-proxy-client certificate and key on disk
[certs] Using existing etcd/ca certificate authority
[certs] Using existing etcd/server certificate and key on disk
[certs] Using existing etcd/peer certificate and key on disk
[certs] Using existing etcd/healthcheck-client certificate and key on disk
[certs] Using existing apiserver-etcd-client certificate and key on disk
[certs] Using the existing "sa" key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/admin.conf"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Using existing kubeconfig file: "/etc/kubernetes/scheduler.conf"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 0.012253 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.22" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node centos7.master as control-plane by adding the labels: [node-role.kubernetes.io/master(deprecated) node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node centos7.master as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: b7hxey.dlylk39rou0k48xe
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.32.100:6443 --token b7hxey.dlylk39rou0k48xe \
	--discovery-token-ca-cert-hash sha256:9fcd4850525d6a5006c76810c39ee78f20c98d400c0e410a3afd5807b6206749 
[root@centos7 aaron]# 


kubeadm join 192.168.32.100:6443 --token gwoyy6.38xvi7d39l3n03yy \
	--discovery-token-ca-cert-hash sha256:9fcd4850525d6a5006c76810c39ee78f20c98d400c0e410a3afd5807b6206749

