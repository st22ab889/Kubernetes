1.信息可以直接传⼊模板引擎中进⾏渲染，但有时候需要转换这些数据才进⾏渲染，这就需要⽤到 Go 模板语⾔中的⼀些其他⽤法。



1.1 模板函数

⽐如需要从  values ⽂件中读取的值变成字符串就可以通过调⽤ quote 模板函数来实现，还是使用 mychart 这个 chart 包:

```javascript
# values.yaml
course:
  k8s: DevOps
  python: Tornado
```



```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  k8s: {{ quote .Values.course.k8s }}
  python: {{ .Values.course.python }}
```



```javascript
// 模板函数遵循调⽤的语法为：functionName arg1 arg2 ...
// 在上⾯的模板⽂件中,调⽤ quote 函数将 .Values.course.k8s 的值作为⼀个参数传递给它

[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run 
NAME: mychartdemo
LAST DEPLOYED: Wed Nov 17 09:36:49 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap
data:
  myvalue: "Hello World"
  k8s: "DevOps"
  python: Tornado

// 最终的结果可以看到 .Values.course.k8s 被渲染成了字符串(devops被加上双引号了) 

```

过 Helm 是⼀种 Go 模板语⾔，拥有超过60多种可⽤的内置函数，⼀部分是由Go 模板语⾔本身定义的，其他⼤部分都 是 Sprig 模板库提供的⼀部分.

- Go 模板语言：https://pkg.go.dev/text/template

- Sprig 模板库：https://masterminds.github.io/sprig/

- Sprig 库Github：https://github.com/Masterminds/sprig

这⾥使⽤的 quote 函数就是 Sprig 模板库 提供的⼀种字符串函数，⽤途就是⽤双引号将字符 串括起来，如果需要双引号 " ，则需要添加 \ 来进⾏转义，⽽ squote 函数的⽤途则是⽤双引号将字 符串括起来，⽽不会对内容进⾏转义。

所以在遇到⼀些需求的时候，⾸先要想到的是去查看下上⾯的两个模板⽂档中是否提供了对应的 模板函数，这些模板函数可以很好的解决我们的需求。





1.2 管道

模板语⾔除了提供了丰富的内置函数之外，其另⼀个强⼤的功能就是管道。和 UNIX 中⼀样， 管道通常称为 Pipeline ，是⼀个链在⼀起的⼀系列模板命令的⼯具，以紧凑地表达⼀系列转换。 简单来说，管道是可以按顺序完成⼀系列事情的⼀种⽅法。⽐如⽤管道重写上⾯的 ConfigMap 模板：

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  k8s: {{ .Values.course.k8s | quote }}
  python: {{ .Values.course.python }}
```

这里使⽤⼀个管道符 | 将前⾯的参数发送给后⾯的模板函数 quote ，使⽤管道可以将⼏个功能顺序的连接在⼀起， ⽐如希望上⾯的 ConfigMap 模板中的 k8s 的 value 值被渲染后是⼤写的字符串，就可以使⽤管道来修改，这⾥在管道中增加了⼀个 upper 函数，该函数同样是 Sprig 模板库 提供的，表示将字符串每⼀个 字⺟都变成⼤写.

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  k8s: {{ .Values.course.k8s | upper | quote }}
  python: {{ .Values.course.python }}
```





```javascript
// 查看模板最终渲染的结果
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run 
NAME: mychartdemo
LAST DEPLOYED: Wed Nov 17 09:53:32 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap
data:
  myvalue: "Hello World"
  k8s: "DEVOPS"
  python: Tornado
  
// 可以看到之前的 devops 已经被渲染成了 "DEVOPS" 了
```





要注意的是使⽤管道操作的时候，前⾯的操作结果会作为参数传递给后⾯的模板函数，⽐如这⾥希望将上⾯模板中的 python 的值渲染 为重复出现3次的字符串，就可以使⽤到 Sprig 模板库 提供的 repeat 函数，不过该函数需要传 ⼊⼀个参数 repeat COUNT STRING 表示重复的次数：

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  k8s: {{ .Values.course.k8s | upper | quote }}
  python: {{ .Values.course.python | repeat 3 | quote }}
```



```javascript
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run 
NAME: mychartdemo
LAST DEPLOYED: Wed Nov 17 10:03:48 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap
data:
  myvalue: "Hello World"
  k8s: "DEVOPS"
  python: "TornadoTornadoTornado"

// repeat 函数会将给定的字符串重复3次返回，所以得到 "TornadoTornadoTornado" 这个输出
```



 在使⽤管道操作的时候⼀定要注意是按照 从前到后⼀步⼀步顺序处理的。





1.3 default 函数

default 函数 ： default DEFAULT_VALUE GIVEN_VALUE 。default 函数经常使⽤到，该函数允许在模板内部指定默认值，以防⽌该值被忽略掉了。如下:

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: {{ .Values.hello | default "Hello Helm" | quote }}
  k8s: {{ .Values.course.k8s | upper | quote }}
  python: {{ .Values.course.python | repeat 3 | quote }}
```



```javascript
// values.yaml ⽂件中只定义了course结构的信息,并没有定义hello的值,,所以得不到 {{ .Values.hello }} 的值
// 但这里为 {{ .Values.hello }} 定义了默认值, 如果values.yaml⽂件中没有定义这个值,就会使用默认值
// 如下:
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run 
NAME: mychartdemo
LAST DEPLOYED: Wed Nov 17 10:12:19 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap
data:
  myvalue: "Hello Helm"
  k8s: "DEVOPS"
  python: "TornadoTornadoTornado"

// 删除templates目录下所有的文件
[root@centos7 43helm]# rm -rf mychart/templates/*.*
```

