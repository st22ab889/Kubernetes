



1. Helm仓库



Helm官方Hub地址: https://artifacthub.io/，可以使用GitHub账号登录



Helm 的 Repo 仓库和 Docker Registry ⽐较类似，Chart 库可以⽤来存储和共享打包 Chart 的位置.

```javascript
// list chart repositories
[root@centos7 40helm]# helm repo list
Error: no repositories to show

```

创建 Chart 仓库⾮常简单，Chart 仓库其实就是⼀个带有 index.yaml 索引⽂件和任意个 Chart 包的 HTTP 服务器⽽已，⽐如想要分享⼀个 Chart 包的时候，将我们本地的 Chart 包上传到该服务器上⾯，别⼈拉下来就可以使⽤了，所以⾃⼰托管 ⼀个 Chart 仓库⾮常简单，⽐如阿⾥云的 OSS、Github Pages，甚⾄⾃⼰创建⼀个简单服务器都可以.(可以尝试主机建⼀个 Github Pages 仓库，每天⾃动和官⽅的仓库进⾏同步,这样就可以将 Helm 默认仓库地址 更改成⾃⼰的仓库地址)

如果⾃⼰创建⼀个 web 服务器来服务 Helm Chart ，只需要实现下⾯⼏个功能点就可以提供服务：

- 将索引和 Chart 置于服务器⽬录中

- 确保索引⽂件 index.yaml 可以在没有认证要求的情况下访问

- 确保 yaml ⽂件的正确内容类型（text/yaml 或 text/x-yaml）

如果 web 服务提供了上⾯⼏个功能，那么也就可以当做 Helm Chart 仓库来使⽤。





2.添加Helm仓库以及其它操作

https://helm.sh/docs/intro/quickstart/



```javascript
// 1.Initialize a Helm Chart Repository(to add a chart repo). Check Artifact Hub for available Helm chart repositories.
// Artifact Hub: https://artifacthub.io/packages/search?kind=0
// 格式: helm repo add [RepoName] [RepoLink]
[root@centos7 40helm]#  helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories

// 2.查看已经添加的 chart repo
[root@centos7 40helm]# helm repo list
NAME   	URL                               
bitnami	https://charts.bitnami.com/bitnami

// 3.查看有哪些 Charts 是可⽤的
// helm search hub [KEYWORD] [flags] => search for charts in the Artifact Hub or your own hub instance
// helm search repo [keyword] [flags] => search repositories for a keyword in charts
// 3.1 如果没有使⽤过滤条件, helm search 显示所有可⽤的 charts
[root@centos7 aaron]# helm search repo
NAME                                        	CHART VERSION	APP VERSION  	DESCRIPTION                                       
bitnami/airflow                             	11.1.7       	2.2.1        	Apache Airflow is a platform to programmaticall...
bitnami/apache                              	8.9.2        	2.4.51       	Chart for Apache HTTP Server 
......
// 3.2 使⽤过滤条件进⾏搜索来缩⼩搜索的结果范围
[root@centos7 aaron]# helm search repo mysql
NAME                   	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/mysql          	8.8.12       	8.0.27     	Chart to create a Highly available MySQL cluster  
bitnami/phpmyadmin     	8.2.18       	5.1.1      	phpMyAdmin is an mysql administration frontend  
......

// 4 查看到 chart 所有的描述信息、包括运⾏⽅式、配置信息等等
// 4.1 helm2 使⽤ inspect 命令可以查看到该 chart 
// helm inspect [CHART]
// 4.2 helm3 使⽤ show 命令
// helm show all [CHART] [flags]    => show all information of the chart
// helm show chart [CHART] [flags]  => show the chart's definition
// helm show crds [CHART] [flags]   => show the chart's CRDs
// helm show readme [CHART] [flags] => show the chart's README
// helm show values [CHART] [flags] => show the chart's values
[root@centos7 aaron]# helm show chart bitnami/mysql
annotations:
  category: Database
apiVersion: v2
appVersion: 8.0.27
......

```



其它命令

```javascript
// 1.删除仓库
// 格式1: helm repo remove [REPO1 [REPO2 ...]] [flags]
// 格式2: helm repo rm [REPO1 [REPO2 ...]] [flags]

// 2.仓库更新  
// 格式1: helm repo update [REPO1 [REPO2 ...]] [flags]
// 格式2: helm repo up [REPO1 [REPO2 ...]] [flags] 

// 3.安装 Chart, 安装 chart 会创建⼀个新 release 对象
// 格式1(指定名称): helm install [NAME] [CHART] [flags]
// 格式2(随机生成名称): helm install [CHART] --generate-name
[root@centos7 40helm]# helm install helm-demo-nginx hello-helm
NAME: helm-demo-nginx
LAST DEPLOYED: Sat Nov 13 10:30:53 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
......
[root@centos7 40helm]# helm list
NAME           	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART           	APP VERSION
helm-demo-nginx	default  	1       	2021-11-13 10:30:53.580689316 -0500 EST	deployed	hello-helm-0.1.0	1.16.0     

//4.要跟踪 release 状态或重新读取配置信息，可以使⽤ helm status 查看
// 格式: helm status RELEASE_NAME [flags]
// 可以看到当前release的状态是deployed,下⾯还有安装的时候出现的信息
[root@centos7 40helm]# helm status helm-demo-nginx
NAME: helm-demo-nginx
LAST DEPLOYED: Sat Nov 13 10:30:53 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
......

```



通过 helm search 命令可以找到想要的 chart 包，找到后可以通过 helm install 命令来进⾏安装.





3.使用helm安装Mysql 以及 ⾃定义 chart

3.1 使用helm安装Mysql

```javascript
// 安装chart的过程中helm将打印release 的状态以及其他有⽤的配置信息
// 这⾥安装mysql的chart打印出了访问mysql服务的⽅法、获取root⽤户的密码以及连接mysql的⽅法等信息
[root@centos7 40helm]#  helm install helm-demo-mysql bitnami/mysql
NAME: helm-demo-mysql

// 为什么Pod处于Pending状态,可以使用describe查看原因
[root@centos7 40helm]# kubectl get pods
NAME                                         READY   STATUS      RESTARTS        AGE
helm-demo-mysql-0                            0/1     Pending     0               23h 

// 可以发现原因是PVC没有被绑定上,这⾥我们可以通过storageclass或者⼿动创建⼀个合适的PV对象来解决
[root@centos7 40helm]# kubectl describe pod helm-demo-mysql-0
Name:           helm-demo-mysql-0
......
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  10s (x3 over 2m40s)  default-scheduler  0/2 nodes are available: 2 pod has unbound immediate PersistentVolumeClaims.
......

// 查看service可以发现类型是ClusterIP
[root@centos7 40helm]# kubectl get svc | grep  mysql
helm-demo-mysql              ClusterIP   10.106.104.179   <none>        3306/TCP         23h
helm-demo-mysql-headless     ClusterIP   None             <none>        3306/TCP         23h

```

值得注意的是 Helm 并不会⼀直等到所有资源都运⾏才退出。因为很多 charts 需要的镜像资源⾮常⼤，所以可能需要很⻓时间才能安装到集群中去。



3.2 ⾃定义 chart

上⾯的安装⽅式是使⽤ chart 的默认配置选项。但是在很多时候都需要⾃定义 chart 以满⾜⾃身的需求，要⾃定义 chart就需要知道使⽤的 chart ⽀持的可配置选项。

```javascript
// 查看 chart 上可配置的选项,格式: helm show values [ChartName]
[root@centos7 40helm]# helm show values bitnami/mysql
global:
  imageRegistry: ""
  imagePullSecrets: []
......

```

[show values mysql](attachments/BECDAC10FC9E4AB086D8E9E332C7FB31show values mysql)



方式1:  可以直接在 YAML 格式的⽂件中来覆盖上⾯的任何配置，在安装的时候直接使⽤该配置⽂件即可：

[config.yaml](attachments/951E304E3AB64134948E349362D60C3Dconfig.yaml)

```javascript
# config.yaml, 注意:文件的层级和缩进要和 chart的默认配置 一致
# 这⾥通过yaml⽂件定义了user和Database,并且把service的类型更改为了NodePort
auth:
  # root用户
  rootPassword: admin000
  #定义database
  database: admin_database
  # 创建一个新用户
  username: demo
  password: demo000
primary:  
  service:
    type: NodePort
  #禁用数据持久化
  persistence:
    enabled: false
```



在安装的时候直接指定 config.yaml ⽂件

```javascript
[root@centos7 40helm]# helm list
NAME            NAMESPACE REVISION  UPDATED                                 STATUS    CHART             APP VERSION
helm-demo-mysql default   1         2021-11-13 10:42:06.576777644 -0500 EST deployed  mysql-8.8.12      8.0.27 
// 先删除 release
[root@centos7 40helm]# helm delete helm-demo-mysql
release "helm-demo-mysql" uninstalled

// 指定YAML文件安装
// 格式: helm install [Name] [chart] -f [YAML File]
[root@centos7 40helm]# helm install helm-demo-mysql bitnami/mysql -f config.yaml
NAME: helm-demo-mysql
LAST DEPLOYED: Sun Nov 14 11:05:07 2021
......
// 安装后 release 的名字是 helm-demo-mysql
[root@centos7 40helm]# helm list
NAME            NAMESPACE   REVISION    UPDATED                                 STATUS      CHART               APP VERSION
helm-demo-mysql default     1           2021-11-14 11:05:07.405424646 -0500 EST deployed    mysql-8.8.12        8.0.27
// Service 已经变为 NodePort 类型
[root@centos7 40helm]# kubectl get svc
NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
helm-demo-mysql              NodePort    10.111.80.173    <none>        3306:32430/TCP   7s
[root@centos7 40helm]# kubectl get pod
NAME                                         READY   STATUS              RESTARTS        AGE
helm-demo-mysql-0                            0/1     ContainerCreating   0               90s
// Pod已经是Running状态
[root@centos7 40helm]# kubectl get pod
NAME                                         READY   STATUS             RESTARTS        AGE
helm-demo-mysql-0                            1/1     Running            0               112s


```





方式2:  另外⼀种⽅法是在安装过程中使⽤ --set 来覆盖对应的 value 值，这里安装个名为"helm-demo2-mysql"的mysql chart，并且禁⽤数据持久化

```javascript
// 格式: helm install [Name] [chart] --set [key1=val1,key2=val2]
// 禁⽤数据持久化,使用"--set"参数来覆盖
[root@centos7 40helm]# helm install helm-demo2-mysql bitnami/mysql --set primary.persistence.enabled=false
NAME: helm-demo2-mysql
LAST DEPLOYED: Sun Nov 14 11:41:02 2021
......
// 可以看到 helm-demo2-mysql-0 这个 pod 的状态是Running
[root@centos7 40helm]# kubectl get pods
NAME                                         READY   STATUS             RESTARTS          AGE
helm-demo2-mysql-0                           1/1     Running            0                 2m48s


```





3.2 使用helm的  upgrade 命令进行升级

方式1:  在 YAML 格式的⽂件中覆盖配置，在升级的时候直接使⽤配置⽂件：

[upgrade-config.yaml](attachments/956B924DF9AB47C5AD64163CE9959EA2upgrade-config.yaml)

```javascript
# upgrade-config.yaml
primary:
  service:
    # 把 Service 的类型升级为 LoadBalancer
    type: LoadBalancer

```

```javascript
// 查看Release
[root@centos7 40helm]# helm list
NAME              NAMESPACE REVISION  UPDATED                                 STATUS    CHART             APP VERSION      
helm-demo2-mysql  default   1         2021-11-14 11:41:02.522121873 -0500 EST deployed  mysql-8.8.12      8.0.27 

// 可以看到 helm-demo2-mysql 这个svc的type是ClusterIP类型
[root@centos7 40helm]# kubectl get svc
NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
helm-demo2-mysql             ClusterIP   10.110.124.15    <none>        3306/TCP         10h

// 升级 helm-demo2-mysql 这个 Release
// 格式: helm upgrade [RELEASE] [CHART] [flags]
// 使用YAML文件需要加"-f"这个flag: helm upgrade [RELEASE] [CHART] -f [YamlFime]
// 运行下面命令发现升级失败,原因是需要MySQL的root密码
[root@centos7 40helm]# helm upgrade helm-demo2-mysql bitnami/mysql -f upgrade-config.yaml
Error: UPGRADE FAILED: execution error at (mysql/templates/NOTES.txt:100:8): 
PASSWORDS ERROR: You must provide your current passwords when upgrading the release.
                 Note that even after reinstallation, old credentials may be needed as they may be kept in persistent volume claims.
                 Further information can be obtained at https://docs.bitnami.com/general/how-to/troubleshoot-helm-chart-issues/#credential-errors-while-upgrading-chart-releases

    'auth.rootPassword' must not be empty, please add '--set auth.rootPassword=$MYSQL_ROOT_PASSWORD' to the command. To get the current value:

        export MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace "default" helm-demo2-mysql -o jsonpath="{.data.mysql-root-password}" | base64 --decode)

// 获取MySQL的root密码
[root@centos7 40helm]# kubectl get secret --namespace "default" helm-demo2-mysql -o jsonpath="{.data.mysql-root-password}" | base64 --decode
5c9idtOapo

// 在命令中使用'--set auth.rootPassword=[MySQL的Root密码]'这个flag
// 修改失败,原因是 k8s 对 StatefulSet 类型的资源有字段限制
[root@centos7 40helm]# helm upgrade helm-demo2-mysql bitnami/mysql -f upgrade-config.yaml --set auth.rootPassword=5c9idtOapo
Error: UPGRADE FAILED: cannot patch "helm-demo2-mysql" with kind StatefulSet: StatefulSet.apps "helm-demo2-mysql" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy' and 'minReadySeconds' are forbidden

[root@centos7 40helm]# kubectl get StatefulSet
NAME               READY   AGE
helm-demo2-mysql   1/1     11h

// 可以看到"helm-demo2-mysql"这个Release的版本是8,并且状态是failed
// 因为每运行一次upgrade,不管成功还是失败版本就加1
[root@centos7 40helm]# helm list
NAME              NAMESPACE REVISION  UPDATED                                 STATUS    CHART             APP VERSION   
helm-demo2-mysql  default   8         2021-11-14 23:02:40.898312083 -0500 EST failed    mysql-8.8.12      8.0.27

// upgrade命令加上"--atomic"这个flag后,升级失败会自动回滚到最近成功的一个版本
// 如果升级成功版本号1,  原因是 upgrade 一次加1
// 如果升级失败版本号加2, 原因是 upgrade 一次加1, 回滚一次加1
// 总结: release 的版本是递增的,每次安装、升级或者回滚,版本号都会加1,第⼀个版本号始终为1
[root@centos7 40helm]# helm upgrade helm-demo2-mysql bitnami/mysql -f upgrade-config.yaml --atomic --set auth.rootPassword=5c9idtOapo
Error: UPGRADE FAILED: release helm-demo2-mysql failed, and has been rolled back due to atomic being set: ......

// 因为这里升级失败,然后自动回滚.所以版本号由8变为10
// 并且状态也由failed变为deployed,说明会找到最近一次成功的版本,然后回滚到这个版本. 
[root@centos7 40helm]# helm list
NAME              NAMESPACE REVISION  UPDATED                                 STATUS    CHART             APP VERSION    
helm-demo2-mysql  default   10        2021-11-14 23:22:53.684202598 -0500 EST deployed  mysql-8.8.12      8.0.27  

```



方式2: 在 upgrade 命令中使⽤ --set 来覆盖对应的 value 值

```javascript

// release 的版本是递增的,每次安装、升级或者回滚,版本号都会加1,第⼀个版本号始终为1
// 当前版本是 15
[root@centos7 40helm]# helm list
NAME              NAMESPACE REVISION  UPDATED                                 STATUS    CHART             APP VERSION  
helm-demo2-mysql  default   15        2021-11-14 23:26:53.100689764 -0500 EST failed    mysql-8.8.12      8.0.27

// 使用"--set"来覆盖对应的 value 值,并且没有加"--atomic"这个flag
[root@centos7 40helm]# helm upgrade helm-demo2-mysql bitnami/mysql --set primary.service.type=LoadBalancer,auth.rootPassword=5c9idtOapo 
Error: UPGRADE FAILED: cannot patch "helm-demo2-mysql" with kind StatefulSet: StatefulSet.apps "helm-demo2-mysql" is invalid: ......

// 因为没有加"--atomic"这个flag,版本号由15变为16
[root@centos7 40helm]# helm list
NAME              NAMESPACE REVISION  UPDATED                                 STATUS    CHART             APP VERSION 
helm-demo2-mysql  default   16        2021-11-14 23:37:40.196896734 -0500 EST failed    mysql-8.8.12      8.0.27     

// 加"--atomic"这个flag再次升级
[root@centos7 40helm]# helm upgrade helm-demo2-mysql bitnami/mysql --atomic --set primary.service.type=LoadBalancer,auth.rootPassword=5c9idtOapo 
Error: UPGRADE FAILED: release helm-demo2-mysql failed, and has been rolled back due to atomic being set: ......

// 因为多了一次自动回滚操作,所以版本号加2
// 并且状态也由failed变为deployed,说明会找到最近一次成功的版本,然后回滚到这个版本. 
[root@centos7 40helm]# helm list
NAME              NAMESPACE REVISION  UPDATED                                 STATUS    CHART             APP VERSION    
helm-demo2-mysql  default   18        2021-11-14 23:41:29.160658584 -0500 EST deployed  mysql-8.8.12      8.0.27  

```





3.3 使用helm的 rollback 命令进行回滚

```javascript

// 查看release的 helm list 命令也可以缩写为 helm ls
// release 的版本是递增的,每次安装、升级或者回滚,版本号都会加1,第⼀个版本号始终为1
[root@centos7 40helm]# helm ls
NAME            	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART           	APP VERSION
helm-demo2-mysql	default  	18      	2021-11-14 23:41:29.160658584 -0500 EST	deployed	mysql-8.8.12    	8.0.27 

// 使⽤ helm history 命令查看 release 的历史版本
// 格式: helm history RELEASE_NAME [flags]
// 默认显示出最近的11个版本信息
[root@centos7 40helm]# helm history helm-demo2-mysql
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION 
......
14      	Sun Nov 14 23:26:11 2021	superseded	mysql-8.8.12	8.0.27     	Rollback to 12 
15      	Sun Nov 14 23:26:53 2021	failed    	mysql-8.8.12	8.0.27     	Upgrade ......
16      	Sun Nov 14 23:37:40 2021	failed    	mysql-8.8.12	8.0.27     	Upgrade ......
17      	Sun Nov 14 23:41:28 2021	failed    	mysql-8.8.12	8.0.27     	Upgrade ......
18      	Sun Nov 14 23:41:29 2021	deployed  	mysql-8.8.12	8.0.27     	Rollback to 14  

// 回滚到某一个版本
// 格式: helm rollback <RELEASE> [REVISION] [flags]
// 回滚到16这个版本
[root@centos7 40helm]# helm rollback helm-demo2-mysql 16
Error: cannot patch "helm-demo2-mysql" with kind StatefulSet: StatefulSet.apps "helm-demo2-mysql" is invalid: spec: Forbidden: ......

// 因为16这个版本是failed的,当回滚到这个版本后,所以当前19这个版本的状态也是failed
[root@centos7 40helm]# helm ls
NAME            	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART           	APP VERSION
helm-demo-mysql 	default  	1       	2021-11-14 11:05:07.405424646 -0500 EST	deployed	mysql-8.8.12    	8.0.27     
helm-demo-nginx 	default  	1       	2021-11-13 10:30:53.580689316 -0500 EST	deployed	hello-helm-0.1.0	1.16.0     
helm-demo2-mysql	default  	19      	2021-11-15 00:49:20.15906158 -0500 EST 	failed  	mysql-8.8.12    	8.0.27     

[root@centos7 40helm]# helm history helm-demo2-mysql
REVISION	UPDATED                 	STATUS    	CHART       	APP VERSION	DESCRIPTION
......
16      	Sun Nov 14 23:37:40 2021	failed    	mysql-8.8.12	8.0.27     	Upgrade ......
17      	Sun Nov 14 23:41:28 2021	failed    	mysql-8.8.12	8.0.27     	Upgrade ......
18      	Sun Nov 14 23:41:29 2021	superseded	mysql-8.8.12	8.0.27     	Rollback to 14
19      	Mon Nov 15 00:49:20 2021	failed    	mysql-8.8.12	8.0.27     	Rollback 

```





3.4 使用helm的 delete 命令删除 release

```javascript
[root@centos7 40helm]# helm ls
NAME            	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART           	APP VERSION
......
helm-demo2-mysql	default  	19      	2021-11-15 00:49:20.15906158 -0500 EST 	failed  	mysql-8.8.12    	8.0.27 

// 格式: helm uninstall RELEASE_NAME [...] [flags]
// Aliases: uninstall, del, delete, un 
// 因为uninstall的别名有del、delete、un, 所以命令中的uninstall也可以用这些别名替代
[root@centos7 40helm]# helm delete helm-demo2-mysql
release "helm-demo2-mysql" uninstalled

// "--all"这个flag表示:show all releases without any filter applied
[root@centos7 40helm]# helm list --all
NAME           	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART           	APP VERSION
helm-demo-mysql	default  	1       	2021-11-14 11:05:07.405424646 -0500 EST	deployed	mysql-8.8.12    	8.0.27     
helm-demo-nginx	default  	1       	2021-11-13 10:30:53.580689316 -0500 EST	deployed	hello-helm-0.1.0	1.16.0
```

