1. RBAC - 基于⻆⾊的访问控制

RBAC 使⽤ rbac.authorization.k8s.io API Group 来实现授权决策，允许管理员通过 Kubernetes API 动态配置策略，要启⽤ RBAC ，需要在 apiserver 中添加参数 --authorization-mode=RBAC ，如果 使⽤的 kubeadm 安装的集群，1.6 版本以上的都默认开启了 RBAC ，可以通过查看 Master 节点上 apiServer的静态 Pod 定义⽂件：

```javascript

cat /etc/kubernetes/manifests/kube-apiserver.yaml
// 运行上面命令可以看到有一项配置为"- --authorization-mode=Node,RBAC"
// "/etc/kubernetes/manifests"是 k8s v1.22.0 版本放静态Pod yaml文件的路径

```

如果是⼆进制的⽅式搭建的集群，在配置apiServer的时候也需要在authorization-mode的值添加上RBAC，记得要重启 apiserver  服务。





RBAC API 对象：Kubernetes 有⼀个很基本的特性就是它的所有资源对象都是模型化的 API 对象，允许执⾏ CRUD(Create、Read、Update、Delete)操作(也就是我们常说的增、删、改、查操作)，⽐如下⾯的这 下资源：

- Pods 

- ConfigMaps 

- Deployments 

- Nodes 

- Secrets 

- Namespaces

上⾯这些资源对象的可能存在的操作有：

- create 

- get 

- delete 

- list 

- update 

- edit 

- watch

-  exec



在更上层，这些资源和 API Group 进⾏关联，⽐如 Pods 属于 Core API Group，⽽ Deployements 属 于 apps API Group，要在 Kubernetes 中进⾏ RBAC 的管理，除了上⾯的这些资源和操作以外，我们 还需要另外的⼀些对象：

- Rule：规则，规则是⼀组属于不同 API Group 资源上的⼀组操作的集合.

- Role 和 ClusterRole：⻆⾊和集群⻆⾊，这两个对象都包含上⾯的 Rules 元素，⼆者的区别在 于，在 Role 中，定义的规则只适⽤于单个命名空间，也就是和 namespace 关联的，⽽ ClusterRole 是集群范围内的，因此定义的规则不受命名空间的约束。另外 Role 和 ClusterRole 在 Kubernetes 中都被定义为集群内部的 API 资源，和我们前⾯学习过的 Pod、ConfigMap 这些 类似，都是我们集群的资源对象，所以同样的可以使⽤我们前⾯的 kubectl 相关的命令来进⾏操 作

- Subject：主题，对应在集群中尝试操作的对象，集群中定义了3种类型的主题资源：

- User Account：⽤户，这是有外部独⽴服务进⾏管理的，管理员进⾏私钥的分配，⽤户可以 使⽤ KeyStone或者 Goolge 帐号，甚⾄⼀个⽤户名和密码的⽂件列表也可以，前提是要进行私钥的认证。对于⽤户的管 理集群内部没有⼀个关联的资源对象，所以⽤户不能通过集群内部的 API 来进⾏管理,也就是说普通用户在k8s集群当中没有对象和它关联，所以不能用kubectl来管理UserAccount.

- Group：组，这是⽤来关联多个账户的，集群中有⼀些默认创建的组，⽐如cluster-admin

- Service Account：服务帐号，通过 Kubernetes API 来管理的⼀些⽤户帐号，和 namespace 进⾏关联的，适⽤于集群内部运⾏的应⽤程序，需要通过 API 来完成权限认证，所以在集群 内部进⾏权限操作，我们都需要使⽤到 ServiceAccount，这是本章的重点.Service Account是集群内部使用的用户

- RoleBinding 和 ClusterRoleBinding：⻆⾊绑定和集群⻆⾊绑定，简单来说就是把声明的 Subject 和我们的 Role 进⾏绑定的过程(给某个⽤户绑定上操作的权限)，⼆者的区别也是作⽤范围的区 别：RoleBinding 只会影响到当前 namespace 下⾯的资源操作权限，⽽ ClusterRoleBinding 会影 响到所有的 namespace。



总结:

1.  要在集群外部来访问集群就要使用到普通用户(UserAccount).



1.  是集群内部的应用程序要做认证就要使用ServiceAccount.



1.  Subject(相当于用户)绑定到一个Role或ClusterRole, Role或ClusterRole绑定到Rule(Rule是一组规则,定义了能执行哪些操作),这个绑定的过程就是RoleBinding或ClusterRoleBinding。





2. 创建⼀个只能访问某个 namespace 的普通⽤户



建⼀个 User Account，只能访问 kube-system 这个命名空间：

```javascript
# 创建下面这样的普通用户
username: aaron 
group: hero
```

Kubernetes 没有 User Account 的 API 对象，但是可以利⽤管理员分配的⼀个私钥就可以创建了，这个可以参考官⽅⽂档中的⽅法， 这⾥使⽤ OpenSSL 证书来创建⼀个 User，当然也可以使⽤更简单的 cfssl ⼯具来创建. 官⽅⽂档 ：https://kubernetes.io/docs/reference/access-authn-authz/authentication/



2.1 创建⽤户凭证

```javascript

// 创建一个名为"aaron-certs"的目录,并cd到这个目录
mkdir aaron-certs
aaron-certs

// 给用户aaron创建一个私钥, 命名为 aaron.key
openssl genrsa -out aaron.key 2048

// 使用刚刚创建的私钥创建⼀个证书签名请求⽂件 aaron.csr,需要确保在-subj参数中指定⽤户名和组
// CN(Customers Name)表示⽤户名，O(Group))表示组，CN和O都是大写
// 生成的 aaron.csr 就是证书签名请求⽂件
openssl req -new -key aaron.key -out aaron.csr -subj "/CN=aaron/O=hero"

// 找到k8s集群的CA证书机构,如果使⽤kubeadm安装的集群，CA相关证书位于"/etc/kubernetes/pki/"⽬录下⾯.
// "ca.crt"和"ca.key"就是k8s的相关证书. ca.crt 是ca证书, ca.key 是ca私钥文件.
// 如果是⼆进制⽅式搭建集群，在最开始搭建的时候就已经指定好了CA⽬录并已经手动生成"ca.crt"和"ca.key"文件.
// 利⽤该⽬录下⾯的"ca.crt"和"ca.key"两个⽂件来批准刚刚生成的证书请求.

// ⽣成最终的证书⽂件,这⾥设置证书的有效期为3600天. aaron.crt就是生成的最终证书文件
openssl x509 -req -in aaron.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out aaron.crt -days 3600

// 用 aaron.crt 这个最终证书文件和私钥⽂件在集群中创建新的凭证和上下⽂(Context)
// 也就是说这一步已经在k8s集群中创建了一个名为 aaron 的普通用户.
kubectl config set-credentials aaron --client-certificate=aaron.crt --client-key=aaron.key

// 为新创建的aaron这个普通⽤户设置新的 Context
// "--namespace=kube-system"表示用户只能在这个命名空间下操作,也就是说这里把用户和命名空间绑定在一起
kubectl config set-context aaron-context --cluster=kubernetes --namespace=kube-system --user=aaron

// 到这⾥，普通⽤户 aaron 就已经创建成功了
// 但是使用"kubectl get pods"同样能成功,因为目前默认还是使用之前的那个context,这是集群搭建时kubeadm创建的,具有很高的权限.

// 使用aaron-context查看Pod出现错误，因为还没有为aaron这个普通⽤户定义任何操作的权限
kubectl get pods --context=aaron-context 


```



2.2 创建⻆⾊

⽤户创建完成后，接下来就需要给该⽤户添加操作权限，来定义⼀个 YAML ⽂件，创建⼀个允许⽤户操作 Deployment、Pod、ReplicaSets 的⻆⾊.

[aaron-role.yaml](attachments/EC5A830CB9A842B988FBEBD803BA094Eaaron-role.yaml)

```javascript
# aaron-role.yaml   创建角色,为用户添加操作权限
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: aaron-role
  # 因为aaron这个用户已经和kube-system这个命名空间绑定
  # 为了让这个用户能访问kube-system,Role也需要定义在kube-system这个命名空间下
  namespace: kube-system
# 给Role指定操作权限规则
rules:
# Pod属于core这个API Group, Deployment和ReplicaSet属于apps这个API Group
# 如果是属于core这个API Group, 注意要用空字符表示这个apiGroups.
# 如果写成["core", "apps"], 用户将不会有操作Pod的权限
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "replicasets"]
  # 定义具有哪些操作权限， patch表示更新一部分
  # verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # 如果具有所有权限,可以直接写为 ["*"]
  verbs: ["*"]
```

Pod 属于 core 这个 API Group，注意在 YAML 中要⽤空字符，⽽ Deployment和ReplicaSets 属于 apps 这个 API Group(如果不知道资源对象属于哪个组就查看官方⽂档)，rules 下⾯的 apiGroups 就综合了这⼏个资源的 API Group：["", "apps"]，其中 verbs 就是可以对这些资源对象执⾏的操作. 如果需要所有的操作⽅法，也可以使⽤['*']来代替.

```javascript

# 这⾥没有使⽤ aaron-context 这个上下⽂是因为还没有权限
kubectl create -f aaron-role.yaml

# 可以看大 aaron-role 这个Role对象已经被创建
# 以"system::"开头的这些Role对象是系统内置的 Role对象 或是 ClusterRole对象
kubectl get role -n kube-system

# 查看详细信息
kubectl get role aaron-role -n kube-system -o yaml

```





注: "aaron-role.yaml"文件还可以写成如下形式,它们所表示的意思是一样的:

[aaron-role-2.yaml](attachments/A941456C26B3468FBD976B306106E96Eaaron-role-2.yaml)

```javascript
# aaron-role-2.yaml  和"aaron-role.yaml"定义的rule一样,只是不同的写法
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: aaron-role
  namespace: kube-system
rules:
- apiGroups:
  - ""
  - apps
  resources:
  - pods
  - deployments
  - replicasets
  verbs:
  - '*'
```



2.3 创建⻆⾊权限绑定

Role 创建完成了，但是这个 Role 和⽤户 aaron 还没有任何关系，所以需要创建⼀个 RoleBinding 对象把用户和角色关联起来。在 kube-system 这个命名空间下⾯将上⾯的 aaron-role ⻆⾊和⽤户 aaron 进⾏绑定.

[aaron-rolebinding.yaml](attachments/22D80EBDA0E34300BF842465F9626D55aaron-rolebinding.yaml)

```javascript
# aaron-rolebinding.yaml 把Role和用户进行绑定
---
apiVersion: rbac.authorization.k8s.io/v1
# 因为Role和用户都指定了namespace,所以使用RoleBinding
kind: RoleBinding
metadata:
  name: aaron-rolebinding
  # 这里namespace要和Role的namespace一样,否则匹配不上
  namespace: kube-system
# 操作集群的对象,也就是用户
subjects:
- kind: User
  # 用户 绑定下面指定的"aaron-role"角色
  name: aaron
  apiGroup: ""
# 操作集群的对象 引用一个角色 来进行绑定
roleRef:
  kind: Role
  # 角色 被上面指定的用户"aaron"绑定
  name: aaron-role
  apiGroup: ""

```

YAML ⽂件中的subjects 关键字就是⽤来尝试操作集群的对 象， 这⾥对应上⾯的 User 帐号 aaron 。

```javascript

kubectl create -f aaron-rolebinding.yaml

# 运行下面命令可以看到有个"aaron-rolebinding"的对象,说明绑定成功
kubectl get rolebinding -n kube-system
 
# 查看一个系统自带的rolebinding是如何写的
kubectl get rolebinding system::leader-locking-kube-scheduler -n kube-system -o yaml

```





目前为止用户aaron已经具有权限,现在可以用 aaron-context 这个上下⽂来操作集群了：

```javascript


# 这里使⽤ kubectl 并没有指定 namespace 也能操作.因为已经为⽤户aaron分配了权限.
# 用户 aaron 已经被指定了只能访问 kube-system 空间,所以不指定 namespace 也能操作
kubectl get pods --context=aaron-context

# 也不能访问default命名空间,因为⽤户并没有default这个命名空间的操作权限
# 用户aaron只给他绑定了kube-system这个命名空间下面的操作权限
kubectl get pods --context=aaron-context -n default

// 下面的命令用户aaron都能操作
kubectl run test-sa-token --image nginx --context=aaron-context 
kubectl get pods --context=aaron-context
kubectl get deployments --context=aaron-context 
kubectl get rs --context=aaron-context 


```



2.4  扩展:对于不同的资源分别定义不同的操作规则



如果改变用户aaron的操作规则,如下:

- 对于replicasets和deployments有全部操作权限.

- 对于Pod只有get和list的权限

[aaron-role-3.yaml](attachments/D7D7E1161E1F4F20B383D7F53BC4384Faaron-role-3.yaml)

```javascript
# aaron-role-3.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: aaron-role
  # 因为aaron这个用户已经和kube-system这个命名空间绑定
  # 为了让这个用户能访问kube-system,Role也需要定义在kube-system这个命名空间下
  namespace: kube-system
# 给Role指定操作权限规则
rules:
- apiGroups:
  - "apps"
  resources:
  - replicasets
  - deployments
  verbs:
  # '*'表示具有所有权限
  - '*'
- apiGroups:
  # Pod属于core这个API Group, 注意要用空字符表示这个apiGroups.
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
```



```javascript

kubectl apply -f  aaron-role-3.yaml

// 下面的命令用户aaron能操作
kubectl get pods --context=aaron-context
kubectl get deployments --context=aaron-context 
kubectl get rs --context=aaron-context 

// 下面的命令用户aaron不能操作,因为没有Pod的create操作权限,只有get和list操作权限
kubectl run test-sa-token --image nginx --context=aaron-context

```







