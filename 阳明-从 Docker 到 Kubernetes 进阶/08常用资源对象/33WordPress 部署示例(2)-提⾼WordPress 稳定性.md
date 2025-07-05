1. 现在 wordpress 应⽤虽然已经部署成功了，但是⽹站访问量突然变⼤了怎么 办，如果我们要更新的镜像该怎么办？如果我们的 mysql 服务挂掉了怎么办？所以要保证 wordpress  能够⾮常稳定的提供服务，还可以通过如下措施提⾼⽹站的稳定性.



- 增加健康检测， liveness probe 和 rediness probe 是提⾼应⽤稳定性⾮常重要的⽅法。

- 增加 HPA，让我们的应⽤能够⾃动应对流量⾼峰期。

- 增加滚动更新策略，这样可以保证我们在更新应⽤的时候服务不会被中断。

- 假如mysql 服务被重新创建了，它的 clusterIP ⾮常有可能就变化了, 所以在环境变量中的 WORDPRESS_DB_HOST 的 clusterIP值就有问题，就会导致访问不了数据库服务，这里可以直接使⽤ Service 的名称来代替 host ，这样即使 clusterIP 变化了，也不会有任何影响。

- 在部署 wordpress 服务的时候，不能确保mysql 服务已经启动起来，如果没有启动起来也没办法连接数据，所以在启动 wordpress 应⽤之前应该先去检查⼀ 下 mysql 服务，服务正常的话就开始部署应⽤，这就是 InitContainer 的⽤法。



2. 提⾼WordPress 稳定性 - 修改"wordpress.yaml"文件

[wordpress.yaml](attachments/57F42F0B2B0E458FADA0BC71777AF614wordpress.yaml)

```javascript
# wordpress.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-deploy
  namespace: blog
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
  replicas: 1
  revisionHistoryLimit: 10
  # 当新的pod启动5s种后,再kill掉旧的pod.如果没有设置该值,Kubernetes会假设该容器启动起来后就提供服务
  minReadySeconds: 5
  # 滚动更新策略
  strategy:
    type: RollingUpdate
    # 根据"replicas: 1"和下面maxSurge和maxUnavailable的值可以知道,当启动一个Pod成功之后,才会把之前Pod停止,这样就做到了滚动更新
    rollingUpdate:
      # 最多能够比更新前的Pod数量多一个
      maxSurge: 1
      # 最多有一个Pod不可用
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      # wordpress依赖mysql,部署wordpress时并不能保证mysql已经启动.
      # 这里使用initContainers检查mysql这个服务,直到mysql服务创建完成后,initContainer才结束,然后再部署wordpress这个Pod
      initContainers:
      - name: init-db
        image: busybox
        imagePullPolicy: IfNotPresent
        command: ['sh', '-c', 'until nslookup mysql; do echo waiting for mysql service; sleep 2; done;']
      containers:
      - name: wordpress
        image: wordpress
        imagePullPolicy: IfNotPresent
        # 健康检查是针对容器的,所以 livenessProbe 和 readinessProbe 和容器平级
        # 存活性探针,容器初始化10秒后检测,每隔3s检测一次80端口,如果检测失败就会重启这个容器   
        livenessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 3
        # 可读性探针是探测应用是否可读,不可读会在Service的Endpoints中给移除掉,可读才加入到Service的Endpoints中
        # 容器启动15s后检测,每隔10s检测一次80端口.因为是通过Service访问,这样就能保证Service的Endpoints中是正常的服务,不正常的会被移除掉了
        readinessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
        ports:
        - containerPort: 80
          name: wdport
        env:
        - name: WORDPRESS_DB_HOST
          # 这里直接设置mysql服务的clusterIP是有问题的,如果mysql服务被重新创建了,它的clusterIP很有可能就变化
          # 可以直接使⽤ Service 的名称来代替 clusterIP(也就是host),这样即使 clusterIP 变化了,也不会有任何影响
          # 如果wordpress和mysql在同一命名空间,直接用 mysql; 如果mysql在db这个namespace下面,就用 mysql.db 这种形式
          value: mysql:3306
        - name: WORDPRESS_DB_USER
          value: wordpress
        - name: WORDPRESS_DB_PASSWORD
          value: wordpress
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: blog
spec:
  selector:
    app: wordpress
  type: NodePort
  ports:
  - name: wordpressport
    protocol: TCP
    port: 80
    targetPort: wdport
    # 注意 ：之前访问是通过30797这个端口,wordpress会把这个url存到数据库中,重新部署后nodePort变了的话也会跳转到30797上面来
    # 最好的方法是在定义wordpress的service指定一个nodeport,以后都通过指定的这个nodeport访问.
    # 不指定nodePort会自动生成一个随机端口,端口的默认范围是"30000-32767",这个范围在安装集群的时候可以配置
    nodePort: 30797
```





3. 把 WordPress 和 Mysql整合到一个YAML文件中

[wordpress-mysql-all.yaml](attachments/69DDFD834BE74DCBA3582D102C3F1464wordpress-mysql-all.yaml)

```javascript
# wordpress-mysql-all.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deploy
  namespace: blog
  labels:
    app: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
          name: dbport
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootPassWord
        - name: MYSQL_DATABASE
          value: wordpress
        - name: MYSQL_USER
          value: wordpress
        - name: MYSQL_PASSWORD
          value: wordpress
        volumeMounts:
          - name: db
            mountPath: /var/lib/mysql
      volumes:
        - name: db
          hostPath:
            path: /var/lib/mysql
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: blog
spec:
  selector:
    app: mysql
  type: ClusterIP  
  ports:
  - name: mysqlport
    protocol: TCP
    port: 3306
    targetPort: dbport


---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-deploy
  namespace: blog
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
  replicas: 1
  revisionHistoryLimit: 10
  minReadySeconds: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      initContainers:
      - name: init-db
        image: busybox
        imagePullPolicy: IfNotPresent
        command: ['sh', '-c', 'until nslookup mysql; do echo waiting for mysql service; sleep 2; done;']
      containers:
      - name: wordpress
        image: wordpress
        imagePullPolicy: IfNotPresent  
        livenessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 3
        readinessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
        ports:
        - containerPort: 80
          name: wdport
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql:3306
        - name: WORDPRESS_DB_USER
          value: wordpress
        - name: WORDPRESS_DB_PASSWORD
          value: wordpress
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: blog
spec:
  selector:
    app: wordpress
  type: NodePort
  ports:
  - name: wordpressport
    protocol: TCP
    port: 80
    targetPort: wdport
    nodePort: 30797

```



```javascript

kubectl delete -f .
kubectl create -f wordpress-mysql-all.yaml

kubectl get pods -n blog
kubectl describe pod wordpress-deploy-d677778c4-lw4ql -n blog

kubectl get svc -n blog
kubectl describe svc wordpress -n blog

// 增加HPA(Horizontal Pod Autoscaling)自动扩缩容,让应⽤能够⾃动应对流量⾼峰期
// 应用访问量突然增大Pod自动增加,访问量减小自动减少一些不必要的Pod
// 格式：kubectl autoscale deployment $DeploymentName --cpu-percent=$num --min=$num --max=$num -n $namespace
# autoscale 命令为wordpress-deploy 创建⼀个HPA对象,最⼩的pod副本数为1,最⼤为10
# HPA 会根据设定的cpu使⽤率(10%)动态的增加或者减少pod数量,但是最好也为Pod声明⼀些资源限制
kubectl autoscale deployment wordpress-deploy --cpu-percent=10 --min=1 --max=10 -n blog
kubectl get hpa -n blog

```



```javascript


// http://192.168.32.100:30797 和 http://192.168.32.101:30797 都可以测试,它们最终都会访问到同一个Pod

//测试方式一:新开一个终端运行下面的脚本,无线循环访问WordPress这个服务,增⼤负载看Pod是否扩容
while true; do wget -q -O- http://192.168.32.100:30797; done

//测试方式二:写一个脚本测试,创建一个如下内容的"test-wordpres.sh"脚本文件,然后执行这个脚本
while true; do wget -q -O- http://192.168.32.100:30797; done
source test-wordpres.sh


# 观察wordpress-deploy这个Deployment的副本数是否发生变化
kubectl get deployment wordpress-deploy -n blog
  
kubectl get hpa -n blog
kubectl describe hpa wordpress-deploy -n blog

kubectl get pods -n blog

kubectl get svc -n blog
# 可以看到Service的Endpoints中有两个地址,说明Pod实现了扩容
kubectl describe svc wordpress -n blog



```





这⾥主要是针对 wordpress 来做的提⾼稳定性的⽅法，但也需要对 mysql 提⾼⼀些稳定性，接下来了解 mysql 这类有状态的应⽤在 Kubernetes 当中的使⽤⽅法。