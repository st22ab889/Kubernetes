1.许多应⽤经常会从配置⽂件、命令⾏参数或者环境变量中读取 ⼀些配置信息，这些配置信息肯定不会直接固定写在应⽤程序中，因为配置信息一变更就要修改代码,使用镜像的话还要重新制作⼀个镜像。⽽ ConfigMap 就给我们提供了向容器中注⼊配置信息的能⼒，不仅可以⽤来保存单个属性，也可 以⽤来保存整个配置⽂件，⽐如我们可以⽤来配置⼀个 redis 服务的访问地址，也可以⽤来保存整 个 redis 的配置⽂件。

ConfigMap 资源对象使⽤ key-value 形式的键值对来配置数据，这些数据可以在 Pod ⾥⾯使 ⽤， ConfigMap 和我们后⾯要讲到的 Secrets ⽐较类似，⼀个⽐较⼤的区别是 ConfigMap 可以⽐较⽅ 便的处理⼀些⾮敏感的数据，⽐如密码之类的还是需要使⽤ Secrets 来进⾏管理.



2. 使用Yaml文件创建ConfigMap

apiVersion版本:

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#configmap-v1-core

[cm-demo1.yaml](attachments/BB42D19B6BC240C6B46AF29D482FB576cm-demo1.yaml)

```javascript
# cm-demo1.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
   name: cm-demo1
# 配置数据   
data:
  # 保存单个属性
  data.1: hello
  data.2: world
  # 保存配置文件, config就相当于这个配置文件的文件名称
  config: |
    property.1=value-1
    property.2=value-2
    property.3=value-3

```





```javascript

kubectl create -f cm-demo1.yaml

# 可以看到cm-demo1这个ConfigMap的DATA是3,因为它包含两个单一属性和一个配置文件
kubectl get configmap

# 查看ConfigMap的详细信息,可以看到配置文件内容
kubectl describe configmap cm-demo1

```



3. 使用命令行创建ConfigMap

```javascript
# 查看帮助文档,上面有示例来说明怎么用命令行创建一个ConfigMap
kubectl create configmap -h
```



3.1 指定文件夹创建ConfigMap资源对象

[test-cm.zip](attachments/F8DE162F83484F9CB2170DDF615F9399test-cm.zip)

```javascript
// 环境:有一个名为"test-cm"文件夹,下面包含"redis.conf"和"mysql.conf"两个文件
// redis.conf 内容如下:
    host=127.0.0.1
    port=6379
 // mysql.conf 内容如下:
    host=127.0.0.1
    port=3306  
```





```javascript
# from-file 参数指定在该⽬录下⾯的所有⽂件都会被⽤在ConfigMap⾥⾯创建⼀个键值对,键的名字就是⽂件名,值就是⽂件的内容
# test-cm 就是包含包含"redis.conf"和"mysql.conf"两个文件的文件夹
kubectl create configmap cm-demo2 --from-file=test-cm

# 运行下面命令可以看到data是2,因为test-cm包含了两个配置文件
kubectl get configmap

# 配置文件内容很多的话,describe命令不会全部显示出配置信息
# 以yaml文件或json文件的格式输出就能把配置信息全部展示出来
kubectl describe configmap cm-demo2

# 以yaml文件格式输出
kubectl get configmap cm-demo2 -o yaml
# 以json格式文件输出
kubectl get configmap cm-demo2 -o json

# 以yaml文件格式输出并保存到当前文件夹下,文件名称是 cm-demo2.yaml
kubectl get configmap cm-demo2 -o yaml > cm-demo2.yaml
cat cm-demo2.yaml

# 以json格式文件输出并保存到当前文件夹下,文件名称是 cm-demo2.json
kubectl get configmap cm-demo2 -o json > cm-demo2.json
cat cm-demo2.json

```



3.2 指定文件创建ConfigMap资源对象

[test-cm.zip](attachments/37096E1B1B6247DFA18E4F95C2973172test-cm.zip)



```javascript

# "--from-file"参数可以多次使用,键的名字就是⽂件名,值就是⽂件的内容
# 也就是说"--from-file"后面可以指定文件夹,也可以指定文件夹下面的具体某个文件
kubectl create configmap cm-demo3 --from-file=test-cm/redis.conf --from-file=test-cm/mysql.conf

kubectl get configma
kubectl get configmap cm-demo3 -o yaml

```



3.3 指定单个属性创建ConfigMap资源对象



```javascript

# "--from-literal"参数可以多次使用,用多少次就有多少个属性
kubectl create configmap cm-demo4 --from-literal=db.host=localhost --from-literal=db.port=3306

kubectl get configmap

kubectl get configmap cm-demo4 -o yaml
```







4. 使用命令行创建ConfigMap



ConfigMap 这些配置数据可以 通过很多种⽅式在 Pod ⾥使⽤，主要有以下⼏种⽅式：

- 设置环境变量的值 

- 在容器⾥设置命令⾏参数

- 在数据卷⾥⾯创建config⽂件





4.1 设置环境变量的值

[use-cm-by-env-demo.yaml](attachments/2E89DB0FB3614398ADCCBBB77EB8872Euse-cm-by-env-demo.yaml)

```javascript
# cm-by-env-demo.yaml
---
apiVersion: v1
kind: Pod
metadata:
   name: use-cm-env-pod
spec:
  containers:
  - name: test-cm-by-env
    image: busybox
    # 打印环境变量的值,这里的"env"指的是下面声明的env
    command: ["/bin/sh", "-c", "env"]
    # 申明环境变量
    env:
    - name: DB_HOST
      # 环境变量值的来源 
      valueFrom:
        # 指定引用(ConfigMap资源对象的名称)从ConfigMap中获取环境变量,然后再通过key获取到值,这个值就是DB_HOST的值
        configMapKeyRef:
          name: cm-demo4
          key: db.host
    - name: DB_PORT
      valueFrom:
        configMapKeyRef:
          name: cm-demo4
          key: db.port
    # 也可以通过"envFrom"给容器注入环境变量
    envFrom:
    - configMapRef:
        name: cm-demo2
```



```javascript
 
 kubectl create -f use-cm-by-env-demo.yaml
 
 kubectl get pods
 
 // 运行下面命令可以看到Pod运行完成后又在重启.
 // 这时因为busybox运行完成后就结束了,而Pod的重启策略默认是"Always",所以一直重启
 kubectl describe pod use-cm-env-pod
 
 // 运行下面命令可以看到打印出了如下值:
 // mysql.conf=host=127.0.0.1
// port=3306
// redis.conf=host=127.0.0.1
// port=6379 
 kubectl logs use-cm-env-pod
 
```



4.2 在容器⾥设置命令⾏参数（ConfigMap被⽤来设置容器中的命令或者参 数值）

[use-cm-by-commandLine-demo.yaml](attachments/60342052EDC442D68F72FBF8C41E3004use-cm-by-commandLine-demo.yaml)



```javascript
# use-cm-by-commandLine-demo.yaml
---
apiVersion: v1
kind: Pod
metadata:
   name: use-cm-command-line-pod
spec:
  containers:
  - name: test-cm-by-command-line
    image: busybox
    # 通过命令行参数的形式来使用ConfigMap里面的值
    command: ["/bin/sh", "-c", "echo $(DB_HOST) $(DB_PORT)"]
    # 申明环境变量
    env:
    - name: DB_HOST
      # 环境变量值的来源 
      valueFrom:
        # 指定引用(ConfigMap资源对象的名称)从ConfigMap中获取环境变量,然后再通过key获取到值,这个值就是DB_HOST的值
        configMapKeyRef:
          name: cm-demo4
          key: db.host
    - name: DB_PORT
      valueFrom:
        configMapKeyRef:
          name: cm-demo4
          key: db.port
```



```javascript

kubectl create -f use-cm-by-commandLine-demo.yaml
kubectl get pods

# 运行下面可以看到显示出"localhost 3306"
kubectl logs use-cm-command-line-pod
```





4.3 通过数据卷使⽤，在数据卷⾥⾯使⽤ConfigMap，就是将⽂件填⼊数据卷，在这个⽂件中，键就是⽂件名，键值就是⽂件内容,这种使用方法非常常见!

[use-cm-by-volume-demo.yaml](attachments/9517864D07F6450983B5DA25CA2D244Fuse-cm-by-volume-demo.yaml)

```javascript
# use-cm-by-volume-demo.yaml 
---
apiVersion: v1
kind: Pod
metadata:
   name: use-cm-volume-pod
spec:
  containers:
  - name: test-cm-by-volume
    image: busybox
    # 因为把cm-demo3这个ConfigMap资源对象中的"redis.conf"文件填入到了"/etc/config"这个目录下,所以这里能打印出"redis.conf"的内容
    command: ["/bin/sh", "-c", "cat /etc/config/redis.conf"]
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  # 因为volumes不属于任何一个容器,所以和containers平级.同样volume可以有多个,所以volume是个数组
  volumes:
  - name: config-volume
    configMap:
      # cm-demo3这个ConfigMap资源对象有"redis.conf"和"mysql.conf"两个文件,这两个文件都会被填入到"/etc/config"这个目录下
      name: cm-demo3
```



```javascript

kubectl create -f use-cm-by-volume-demo.yaml 
kubectl get pods

# 运行下面命令可以看到"redis.conf"文件的内容
kubectl logs use-cm-volume-pod
```





也可以在 ConfigMap 值被映射的数据卷⾥去控制路径，如下:

[use-cm-by-volume-demo2.yaml](attachments/6BD4540FB1884BE9AEC986185B8961BCuse-cm-by-volume-demo2.yaml)

```javascript
# use-cm-by-volume-demo2.yaml
---
apiVersion: v1
kind: Pod
metadata:
   name: use-cm-volume-pod2
spec:
  containers:
  - name: test-cm-by-volume2
    image: busybox
    # 这里的路径随便指定
    command: ["/bin/sh", "-c", "cat /etc/config/path/to/mysql.conf"]
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  # 因为volumes不属于任何一个容器,所以和containers平级.同样volume可以有多个,所以volume是个数组
  volumes:
  - name: config-volume
    configMap:
      # cm-demo3这个ConfigMap资源对象有"redis.conf"和"mysql.conf"两个文件,这两个文件都会被填入到"/etc/config"这个目录下
      name: cm-demo3
      items:
      - key: mysql.conf
        # 重新声明路径(也就是ConfigMap值被映射的数据卷⾥去控制路径)
        path: path/to/mysql.conf
```



```javascript

kubectl create -f use-cm-by-volume-demo2.yaml
kubectl get pods

# 运行下面命令可以看到"mysql.conf"文件的内容 
kubectl logs use-cm-volume-pod2
```





另外需要注意的是，当 ConfigMap 以数据卷的形式挂载进 Pod 时，这时更新 ConfigMap（或删掉重建 ConfigMap ），Pod 内挂载的配置信息会热更新。这时可以增加⼀些监测配置⽂件变更的脚本，然后 reload 对应服务，这样就能做到热更新。