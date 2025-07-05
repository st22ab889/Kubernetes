1. kubernetes-dashboard插件官方地址:

   https://github.com/kubernetes/dashboard



2.http和https的默认端口

http的默认端口是80 

https的默认端口是443 



3.操作命令

```javascript
查看节点
kubectl get nodes

查看所有命名空间下阿pod
kubectl get pods --all-namespaces

查看指定命名空间下的pod, "-o wide"显示pod在哪个节点上
kubectl get pods -n [namespaces name] -o wide

查看指定命名空间下的service, 不加命名空间默认就是"default"命名空间
kubectl get svc -n [namespaces name]
kubectl get service


描述service,把详细信息打印出来
kubectl describe svc kubernetes-dashboard -n kube-system
kubectl describe svc [service name] -n [namespaces name]

根据yaml文件执行一些操作
kubectl apply -f [指定yaml文件]

查看serviceaccount
kubectl get serviceaccount -n kube-system

不知道资源对象信息的时候,就可以describe看一下详细信息,可以看到下面有Tokens字段和Mountable secrets字段
#Tokens字段就是登录dashboard需要使用的,但这不是一个直接的Token字符串,这是一个secret资源对象
#Mountable secrets字段，相当于token和serviceaccount进行关联了
kubectl describe serviceaccount admin -n kube-system
kubectl describe serviceaccount [service account name] -n kube-system  


#查看secret,可以找到和"Mountable secrets"对应的secret
kubectl get secret -n kube-system
kubectl get secret -n [namespace name]

#根据secret资源对象可以查到具体的token
kubectl describe secret admin-token-gmwsp -n kube-system
kubectl describe secret [secret name] -n [namespaces name]
```





5.身份认证和成成token.

登录 dashboard 的时候⽀持 Kubeconfig 和token 两种认证⽅式，Kubeconfig 中也依赖token 字段，所 以⽣成token 这⼀步是必不可少的。

我们创建⼀个admin⽤户并授予admin ⻆⾊绑定，使⽤下⾯的yaml⽂件创建admin⽤户并赋予他管理员 权限，然后就可以通过token 登陆dashbaord，这种认证⽅式本质实际上是通过Service Account 的身 份认证加上Bearer token请求 API server 的⽅式实现，参考Kubernetes 中的认证。https://kubernetes.io/docs/reference/access-authn-authz/authentication/



[admin-account.yaml](attachments/099C46483A2D403BA47AA1EB508BDAC6admin-account.yaml)



```javascript
#admin-account.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: admin
  namespace: kubernetes-dashboard

#如果下面要继续写,用"---"表示区分，说明上下是两块
---

#给admin绑定一个角色
apiVersion: rbac.authorization.k8s.io/v1
#RoleBinding是和命名空间相关的,但是如果要访问所有资源对象权限,所以这个地方应该使用ClusterRoleBinding, 它和namespace是没有关系的,它管理整个集群
#kind: RoleBinding
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin	# cluster-admin是k8s集群内置的集群角色,所以不需要去声明角色权限,所以这里不能改成其它名字，cluster-admin的权限是非常高的
subjects:
  - kind: ServiceAccount
    name: admin
    namespace: kubernetes-dashboard
```



```javascript
#创建ServiceAccount
kubectl apply -f admin-account.yaml
```





4.在k8s集群当中, 任意节点IP+NodePord都可以访问到服务,这是k8s组件使k8s与iptables建立了一些规则，然后可以通过每个节点通过nodeport都可以访问服务.



master  	192.168.32.100

node	192.168.32.101



比如node节点有nginx和kubernetes-dashboard两个服务.



下面两个节点都可以访问到nginx:

http://192.168.32.100:31026/

http://192.168.32.101:31026/



下面两个节点都可以访问到kubernetes-dashboard:

https://192.168.32.100:30443/

https://192.168.32.101:30443/