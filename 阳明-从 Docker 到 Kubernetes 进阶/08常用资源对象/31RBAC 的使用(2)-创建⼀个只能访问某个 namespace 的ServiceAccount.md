 1. 创建⼀个只能访问某个 namespace 的ServiceAccount



1.1 创建ServiceAccount对象

```javascript

#创建⼀个集群内部的⽤户只能操作 kube-system 这个命名空间下⾯的 pods 和 deployments

#使用命令创建,"aaron-sa"为集群内部的⽤户,也可以用yaml文件创建
kubectl create sa aaron-sa -n kube-system  
kubectl get sa -n kube-system

#查看一个系统创建的SA,发现有个secret对象
kubectl get sa coredns -n kube-system -o yaml

#刚刚创建的SA用户,发现也有secret对象
#原因是新建一个SA后,k8s会新建一个secret资源对象和它关联
kubectl get sa aaron-sa  -n kube-system -o yaml


```



1.2 新建Role对象和ServiceAccount对象关联

[aaron-sa-role.yaml](attachments/023B095E37134ADB97EDE36C605EDA59aaron-sa-role.yaml)

```javascript
# aaron-sa-role.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: aaron-sa-role
  namespace: kube-system
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["*"]

```



```javascript
kubectl create -f aaron-sa-role.yaml
kubectl get role -n  -n kube-system
```



1.3 创建⼀个 RoleBinding 对象，将上⾯的 aaron-sa 和⻆⾊ aaron-sa-role 进⾏绑定.

[aaron-sa-rolebinding.yaml](attachments/ED1085FBBB91442AAEDFF0C16BBAF1A4aaron-sa-rolebinding.yaml)

```javascript
# aaron-sa-rolebinding.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: aaron-sa-rolebinding
  namespace: kube-system
subjects:
- kind: ServiceAccount
  name: aaron-sa
  namespace: kube-system
roleRef:
  kind: Role
  name: aaron-sa-role
  apiGroup: rbac.authorization.k8s.io
  # apiGroup也可以写一个空字符串
  # apiGroup: ""
  
```



```javascript

kubectl create -f aaron-sa-rolebinding.yaml
kubectl get RoleBinding -n kube-system

// 到此为止权限绑定成功

```



1.4 验证创建的aaron-sa这个SA对象

创建SA对象时会⽣成⼀个 Secret 对象和它进⾏映射，这个 Secret ⾥⾯包含⼀个 token，可以利⽤这个 token 去登录Dashboard，然后可以在 Dashboard 中来验证功能是否符合预期。

```javascript

kubectl get sa -n kube-system
# 查看aaron-sa这个SA对象的详细信息
kubectl get sa aaron-sa -n kube-system -o yaml

# 找到aaron-sa这个SA对象的Secret对象查看详细信息
kubectl get secret aaron-sa-token-942jc -n kube-system  -o yaml

// 找到token,这个token是经过base64编码后的字符串,对它进行解码
[root@centos7 aaron-sa]# echo ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNkltZFdPRTFRVEZkTlFUZHRabmRHVW5wclpqZGZURjlmYkRsTVRFTjVlalJLYjFkblNGVjNjM1kwVXpRaWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUpyZFdKbExYTjVjM1JsYlNJc0ltdDFZbVZ5Ym1WMFpYTXVhVzh2YzJWeWRtbGpaV0ZqWTI5MWJuUXZjMlZqY21WMExtNWhiV1VpT2lKaFlYSnZiaTF6WVMxMGIydGxiaTA1TkRKcVl5SXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMbTVoYldVaU9pSmhZWEp2YmkxellTSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMblZwWkNJNklqaGpOR0l3T0dRNExUVTVOREl0TkRjeE5DMDVaREF6TFRnME56UTNPVEV6TlRZd09DSXNJbk4xWWlJNkluTjVjM1JsYlRwelpYSjJhV05sWVdOamIzVnVkRHByZFdKbExYTjVjM1JsYlRwaFlYSnZiaTF6WVNKOS5oclprYi1IblZtNnhxMDNncEQtX1RTdDBjdDhwWXRoOWNWYXF1cXk2WFRieTRnZ2k5c09DVGtWX2dOYTlmVzFGQllPNGFNcmNvbk9hZVJlYWo2eURPTUhoU0x4NzZ2WWdyZTFSbTdxOS1MSzZCeTVOb2o3N0NZTm9RTWhSX2FZR2dFMFBuUFhMNzBkY09FTEZQeVh0RGlQSEhxdDlXX0RSV1J1VHVnYlFxWjIycTFFc3dCRTJ0bUpnUlRyN2NYNkpvVmM0UWgwWmE2SjZ3YWNGY2xOZkFvSV9vNXo4VzhldXFqcXhJdHBELWQwZ3FYbGRqUTZaeGRabmdJa2dVZUFtZUFYZnltWjhzWkdTQnVyM1lzLU1Gc2JFV3ozWGJpQUo2ekczNzJrNTVDYXVfT2lCWjZ0b3pXM2VSZkkxa3BHLXNEbzZJWnhUZmZuUHhVblJQUzNJVWc= | base64 -d
// 使用这个token在Dashboard登录并验证功能
eyJhbGciOiJSUzI1NiIsImtpZCI6ImdWOE1QTFdNQTdtZndGUnprZjdfTF9fbDlMTEN5ejRKb1dnSFV3c3Y0UzQifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhYXJvbi1zYS10b2tlbi05NDJqYyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhYXJvbi1zYSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjhjNGIwOGQ4LTU5NDItNDcxNC05ZDAzLTg0NzQ3OTEzNTYwOCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTphYXJvbi1zYSJ9.hrZkb-HnVm6xq03gpD-_TSt0ct8pYth9cVaquqy6XTby4ggi9sOCTkV_gNa9fW1FBYO4aMrconOaeReaj6yDOMHhSLx76vYgre1Rm7q9-LK6By5Noj77CYNoQMhR_aYGgE0PnPXL70dcOELFPyXtDiPHHqt9W_DRWRuTugbQqZ22q1EswBE2tmJgRTr7cX6JoVc4Qh0Za6J6wacFclNfAoI_o5z8W8euqjqxItpD-d0gqXldjQ6ZxdZngIkgUeAmeAXfymZ8sZGSBur3Ys-MFsbEWz3XbiAJ6zG372k55Cau_OiBZ6tozW3eRfI1kpG-sDo6IZxTffnPxUnRPS3IUg
[root@centos7 aaron-sa]#

// 在k8s v1.10.0版本上登录到Dashboard可以看到很多提示信息(警告信息)
// 在k8s v1.22.0版本上登录到Dashboard页面,点击每一个选项都显示"这里没有可以显示的"和"找不到资源"
// 这是因为登录进去后默认是default命名空间
// 在地址栏中把"namespace=default"改为"namespace=kube-system"切换空间
// 验证功能是否符合预期

```



总结:

"aaron-sa-role.yaml"实现了对于不同的资源分别定义不同的操作规则。同样的，可以根据⾃⼰的需求来对访问⽤户的权限进⾏限制，可以⾃⼰通过 Role 定义更加细粒度的权限，也可以使⽤系统内置的⼀些权限(Role)。



2. 创建⼀个可以访问所有 namespace 的ServiceAccount

创建⼀个新的 ServiceAccount，操作权限作⽤于所有的 namespace，这个时候需要使⽤到 ClusterRole 和 ClusterRoleBinding 这两种资源对象。

[aaron-sa-clusterrolebinding.yaml](attachments/49B1DB3D811E48E3A4A4E235C8D48233aaron-sa-clusterrolebinding.yaml)

```javascript
# aaron-sa-clusterrolebinding.yaml

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aaron-sa-cluster
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind:  ClusterRoleBinding
metadata:
  name: aaron-sa-clusterrolebinding
  # 这个是集群角色绑定,和namespace没有关系,作用于整个集群，所以不用指定
subjects:
- kind: ServiceAccount
  name: aaron-sa-cluster
  # ServiceAccount和namespace是有关系的,所以这里要指定命名空间
  namespace: kube-system
roleRef:
  kind: ClusterRole
  # "cluster-admin"拥有最高权限的集群角色，要谨慎使用这个集群角色，不能随便把这个集群角色分配给别人
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io 
  
```

可以看到没有为 ClusterRoleBinding 这个资源对象声明 namespace，因为 ClusterRoleBinding 资 源对象是作⽤于整个集群的，也没有单独新建⼀个 ClusterRole 对象，⽽是使⽤的 cluster-admin 这个对象，这是 Kubernetes 集群内置的 ClusterRole 对象，可以使⽤ kubectl get clusterrole 和 kubectl get clusterrolebinding 查看系统内置的⼀些集群⻆⾊和集群⻆⾊绑定，这⾥使⽤的 cluster-admin 这个集群⻆⾊是拥有最⾼权限的集群⻆⾊，所以⼀般需要谨慎使⽤该集群⻆⾊。



```javascript

kubectl create -f aaron-sa-clusterrolebinding.yaml
kubectl get sa -n kube-system
kubectl get sa aaron-sa-cluster -n kube-system -o yaml
kubectl get secret aaron-sa-cluster-token-lq269 -n kube-system -o yaml

// 找到token,这个token是经过base64编码后的字符串,对它进行解码
[root@centos7 aaron-sa]# echo  ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNkltZFdPRTFRVEZkTlFUZHRabmRHVW5wclpqZGZURjlmYkRsTVRFTjVlalJLYjFkblNGVjNjM1kwVXpRaWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUpyZFdKbExYTjVjM1JsYlNJc0ltdDFZbVZ5Ym1WMFpYTXVhVzh2YzJWeWRtbGpaV0ZqWTI5MWJuUXZjMlZqY21WMExtNWhiV1VpT2lKaFlYSnZiaTF6WVMxamJIVnpkR1Z5TFhSdmEyVnVMV3h4TWpZNUlpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WlhKMmFXTmxMV0ZqWTI5MWJuUXVibUZ0WlNJNkltRmhjbTl1TFhOaExXTnNkWE4wWlhJaUxDSnJkV0psY201bGRHVnpMbWx2TDNObGNuWnBZMlZoWTJOdmRXNTBMM05sY25acFkyVXRZV05qYjNWdWRDNTFhV1FpT2lJd1l6QmxaRGd3TVMxalltTm1MVFF6TW1FdE9UZzNZeTB5WkRjMU5UUmtPVFk0WmpVaUxDSnpkV0lpT2lKemVYTjBaVzA2YzJWeWRtbGpaV0ZqWTI5MWJuUTZhM1ZpWlMxemVYTjBaVzA2WVdGeWIyNHRjMkV0WTJ4MWMzUmxjaUo5LktnOTdCeUtGRzY2M0RJY0xPU2p0aUExVGtwcUhVbmQ0UEpOVVZjX3RDUU4zZ3c4Q2dxdWhHRzJzNEk3NFNGTXZGRG4yc1RXaUlPUlFEMzk5cWRuYS01QlFJdFlSeUhMa01DTnZVZm9TcVpnV2wxT1l3N05xeDQ3MXdvZXdMMXpfaEYyMXNMcVlETXVpOFpmb1RhSzdWUXZRVEIwRVo4SkRGUXlQeWdaOFhNbTh6MlJtcG80X1Q4MWNPZG42UkNjMUFfNXhkaWdVNzlxOTI4SW4zUzdiZlhuM3lpVXk4MTdIUGtkblAxNEE4MmNiQlFmVXQ4TkNnYllqdUV6QUE4M1NvWHp2TFZVZ09hLVJsdU1JUTlfeF9PSGdOWHlpeHJMakNqREhBYXgxQWNhZ2p5ejRySVRzR3hiOVcwV2NXVmhTQUpFNWdsbUtXcDdDVGhuYkhPNENnZw== | base64 -d
// 使用这个token在Dashboard登录并验证功能
eyJhbGciOiJSUzI1NiIsImtpZCI6ImdWOE1QTFdNQTdtZndGUnprZjdfTF9fbDlMTEN5ejRKb1dnSFV3c3Y0UzQifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhYXJvbi1zYS1jbHVzdGVyLXRva2VuLWxxMjY5Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFhcm9uLXNhLWNsdXN0ZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIwYzBlZDgwMS1jYmNmLTQzMmEtOTg3Yy0yZDc1NTRkOTY4ZjUiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWFyb24tc2EtY2x1c3RlciJ9.Kg97ByKFG663DIcLOSjtiA1TkpqHUnd4PJNUVc_tCQN3gw8CgquhGG2s4I74SFMvFDn2sTWiIORQD399qdna-5BQItYRyHLkMCNvUfoSqZgWl1OYw7Nqx471woewL1z_hF21sLqYDMui8ZfoTaK7VQvQTB0EZ8JDFQyPygZ8XMm8z2Rmpo4_T81cOdn6RCc1A_5xdigU79q928In3S7bfXn3yiUy817HPkdnP14A82cbBQfUt8NCgbYjuEzAA83SoXzvLVUgOa-RluMIQ9_x_OHgNXyixrLjCjDHAax1Acagjyz4rITsGxb9W0WcWVhSAJE5glmKWp7CThnbHO4Cgg
[root@centos7 aaron-sa]# 

// 使用这个token登录到Dashboard验证
// 可以发现使用这个token登录具有所有的权限，所有的东西都能看到和操作

```



3. 创建⼀个可以访问所有 namespace 的ServiceAccount

最开始接触到 RBAC 认证的时候，可能不太熟悉，特别是不知道应该怎么去编写 rules 规则，可以去分析系统⾃带的 clusterrole、clusterrolebinding 这些资源对象的编写⽅法，利⽤ kubectl 的 get、describe、 -o yaml 这些操作，所以 kubectl 是最基本的，⼀定要掌握好。

```javascript

// 可以根据系统内置的资源对象学习怎么定义这些资源对象：

kubectl get ClusterRole
# 可以看到系统定义"ClusterRole"时也没有指定namespace,因为他是作用于整个集群的Role
kubectl get ClusterRole system:basic-user -o yaml

kubectl get ClusterRoleBinding
# 可以看到系统定义"ClusterRoleBinding"时也没有指定namespace,因为他是作用于整个集群的RoleBinding
kubectl get ClusterRoleBinding system:basic-user -o yaml

```







总结:

Kubernetes中不止RBAC这⼀种安全认证方式，还有一些其它的安全认证方式，但是RBAC是现在最重要的⼀种⽅式，也还需要了解 Kubernetes 中安全设计。

