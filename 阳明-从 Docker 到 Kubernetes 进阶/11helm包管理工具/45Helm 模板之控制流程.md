1. 模板函数和管道 是通过转换信息并将其插⼊到 YAML ⽂件中的强⼤⽅法。但有时候需要添加⼀些⽐插⼊字符串更复杂⼀些的模板逻辑。这就需要使⽤到模板语⾔中提供的控制结构。



1.1 控制流程提供了控制模板⽣成流程的⼀种能⼒，Helm 的模板语⾔提供了以下⼏种流程控制：

- if/else 条件块

- with 指定范围

- range 循环块



1.2 除此之外，它还提供了⼀些声明和使⽤命名模板段的操作：

- define 在模板中声明⼀个新的命名模板

- template 导⼊⼀个命名模板

- block 声明了⼀种特殊的可填写的模板区域



2.  控制流程

2.1  if/else 条件

if/else 块是⽤于在模板中有条件地包含⽂本块的⽅法, 条件块的基本结构如下：

```javascript
{{ if PIPELINE }}
# Do something
{{ else if OTHER PIPELINE }}
# Do something else
{{ else }}
# Default case
{{ end }}
```



使⽤条件块就得判断条件是否为真，如果值为下⾯的⼏种情况，则管道的结果为 false，除了下⾯的这些情况外，其他所有条件都为真 。

- ⼀个布尔类型的 假

- ⼀个数字 零

- ⼀个 空 的字符串

- ⼀个 nil （空或 null ）

- ⼀个空的集合（ map 、 slice 、 tuple 、 dict 、 array ）



示例1：

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
  myvalue: {{ .Values.hello | default "Hello Helm" | quote }}
  k8s: {{ .Values.course.k8s | upper | quote }}
  python: {{ .Values.course.python | repeat 3 | quote }}
  {{ if eq .Values.course.python "Tornado" }}web: true {{ end }}

```

{{ if eq .Values.course.python "django" }}web: true{{ end }} 是⼀个条件判断语句，运算符 eq 是判断是否相等的操作。Helm 模板还实现了 ne 、 lt 、 gt 、 and 、 or  等运算符，都可以直接使⽤。

```javascript
// {{ .Values.course.python }} 的值在 values.yaml ⽂件中被设置为Tornado,所以条件语句判断为真
// 可以看到模板⽂件最终被渲染后有 web: true 这样的的⼀个条⽬
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run 
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 09:59:06 2021
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
  web: true
```





示例2：安装的时候使用  --set 参数覆盖 python 值

```javascript

[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run --set course.python=py
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 10:08:00 2021
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
  python: "pypypy"

// 可以看到没有 web: true 这样一个条目
```



3. 空格控制

如果条件判断语句放在⼀整⾏中看起来就会⾮常不习惯，⼀般会将其格式化为更容易阅读的形式，⽐如：

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
  {{ if eq .Values.course.python "Tornado" }}
  web: true 
  {{ end }}
```



```javascript
// configmap.yaml 看上去⽐之前要清晰很多
// 通过模板引擎渲染后发现会有多余的空⾏
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 10:12:09 2021
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
  
  web: true

[root@centos7 43helm]# 

```

渲染出来会有多余的空⾏，这是因为当模板引擎运⾏时，它将⼀些值渲染过后，之前的指令被删除，但它之前所占的位置完全按原样保留剩余的空⽩了，所以就出现了多余的空⾏。 YAML ⽂件中的空格是⾮常严格的，所以对于空格的管理⾮常重要，⼀不⼩⼼就会导致你 的 YAML ⽂件格式错误。



可以通过使⽤在模板标识来删除空格:

- "{{- "：表示将空白左移。 

- " -}}"：表示应该删除右边的空格,特别注意的是换⾏符也是空格

- 格式说明："{{- "   ==>  "{{ 加-加空格"； " -}}"    ==>  "空格加-加 }}"

- 加" -}}"后, helm3会校验yaml文件的正确性,如果校验的结果不正确，将不会渲染,会出现错误提示



示例1：

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
  {{- if eq .Values.course.python "Tornado" }}
  web: true 
  {{- end }}
```



```javascript
// 可以看到现在没有多余的空格了
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 10:25:34 2021
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
  web: true

[root@centos7 43helm]# 
```





示例2：加" -}}"后, helm3会校验yaml文件的正确性,如果校验的结果不正确，将不会渲染,会出现错误提示

```javascript
// " -}}"这种用法在helm3中是不行的,在helm2中可以
  {{- if eq .Values.course.python "Tornado" -}}
  web: true 
  {{- end }}
```



```javascript
// 在 end 后面加" -}}",helm3中也可以 
  {{- if eq .Values.course.python "Tornado" -}}
  web: true 
  {{- end -}}
```



如下:

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
  {{- if eq .Values.course.python "Tornado" -}}
  web: true 
  {{- end }}
```



```javascript
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
Error: INSTALLATION FAILED: YAML parse error on mychart/templates/configmap.yaml: error converting YAML to JSON: yaml: line 7: did not find expected key

```



有关模板中空格控制的详细信息，请参阅官⽅ Go 模板⽂档:  

https://helm.sh/docs/chart_template_guide/control_structures/





4.使⽤ with 修改范围: with 关键词⽤来控制变量作⽤域

{{ .Release.xxx }} 或者 {{ .Values.xxx }} 其中的 . 就是表示对当前范围的引⽤，.Values 就是告诉模板在当前范围中查找 Values 对象的值。⽽ with 语句就可以来控制变量的作⽤域范围，其语法和⼀个简单的 if 语句⽐较类似:

```javascript
{{ with PIPELINE }}
# restricted scope
{{ end }}
```





示例1：

with 语句允许将当前范围 . 设置为特定的对象，⽐ .Values.course 可以使⽤ with 来将 . 范围指向 .Values.course

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: {{ .Values.hello | default "Hello Helm" | quote }}
  {{- with .Values.course }}
  k8s: {{ .k8s | upper | quote }}
  python: {{ .python | repeat 3 | quote }}
  {{- if eq .python "Tornado" }}
  web: true 
  {{- end }}
  {{- end }}
```



上⾯增加了 {{- with .Values.course }}xxx{{- end }} 这样⼀个块，这样就可以在当前的块⾥⾯直接引⽤ .python 和 .k8s ，⽽不需要进⾏限定，因为该 with 声明将 . 指向了 .Values.course ，在 {{- end }} 后 . 就会复原其之前的作⽤范围。



```javascript
// 使⽤模板引擎渲染模板来查看是否符合预期结果
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 10:49:48 2021
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
  web: true

```





示例2：

不过需要注意的是在 with 声明的范围内，此时将⽆法从⽗范围访问到其他对象了，⽐如下⾯的模板 渲染的时候将会报错，因为显然 .Release 根本就不在当前的 . 范围内：

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: {{ .Values.hello | default "Hello Helm" | quote }}
  {{- with .Values.course }}
  k8s: {{ .k8s | upper | quote }}
  python: {{ .python | repeat 3 | quote }}
  release:  {{ .Release.Name }}
  {{- end }}
```

如果最后两⾏交换 下位置就正常了，因为 {{- end }} 之后范围就被重置了。





5.range 循环

在 Helm 模板语⾔中，是使⽤ range 关键字来进⾏循环操作

```javascript
# values.yaml
course:
  k8s: DevOps
  python: Tornado
courselist:
  - k8s
  - python
  - golang
  - java
```



```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: {{ .Values.hello | default "Hello Helm" | quote }}
  {{- with .Values.course }}
  k8s: {{ .k8s | upper | quote }}
  python: {{ .python | repeat 3 | quote }}
  {{- if eq .python "Tornado" }}
  web: true 
  {{- end }}
  {{- end }}
  courselist: |-
    {{- range .Values.courselist }}
    - {{ . | title | quote }}
    {{- end }}
```



range 函数该函数将会遍历 {{ .Values.courselist }} 列表，循环内部使⽤的是⼀个 . ，这是因为当前的作⽤域就在当前循环内，这个 . 从列表的第⼀个元素⼀ 直遍历到最后⼀个元素，然后在遍历过程中使⽤了 title 和 quote 这两个函数，前⾯这个函数是将字 符串⾸字⺟变成⼤写，后⾯就是加上双引号变成字符串。



```javascript
// 上⾯这个模板被渲染过后的结果为
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 11:11:40 2021
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
  web: true
  courselist: |-
    - "K8s"
    - "Python"
    - "Golang"
    - "Java"

[root@centos7 43helm]# 
```



可以看到 courselist 循环遍历出来了。除了 list 或者 tuple，range 还可以⽤于遍历具有键和值的集合（如map 或 dict），这个就需要⽤到变量的概念。





6.变量

在 Helm 模板中，使⽤变量的场合不是特别多，但是在合适的时候使⽤变量可以很好的解决问题。如下⾯的模板：

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: {{ .Values.hello | default "Hello Helm" | quote }}
  {{- with .Values.course }}
  k8s: {{ .k8s | upper | quote }}
  python: {{ .python | repeat 3 | quote }}
  release:  {{ .Release.Name }}
  {{- end }}
```



上面的模板在 with 语句块内添加了⼀个 .Release.Name 对象，但这个模板是错误的，编译的时候会失败， 这是因为 .Release.Name 不在该 with 语句块限制的作⽤范围之内，但是可以将该对象赋值给⼀个变量可以来解决这个问题。



示例1：

```javascript
# configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  {{- $releaseName := .Release.Name }}
  myvalue: {{ .Values.hello | default "Hello Helm" | quote }}
  {{- with .Values.course }}
  k8s: {{ .k8s | upper | quote }}
  python: {{ .python | repeat 3 | quote }}
  release:  {{ $releaseName }}
  {{- end }}
```



上面的模板 with 语句上⾯加了一行 {{- $releaseName := .Release.Name -}} ，其 中 $releaseName 就是后⾯的对象的⼀个引⽤变量，它的形式就是 $name ，赋值操作使⽤ := ，这 样 with 语句块内部的 $releaseName 变量仍然指向的是 .Release.Name 。



```javascript
// 上⾯这个模板被渲染过后的结果为
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 11:26:06 2021
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
  release:  mychartdemo

[root@centos7 43helm]# 
```





示例2：

变量在 range 循环中也⾮常有⽤，可以在循环中⽤变量来同时捕获索引的值：

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
  courselist: |-
    {{- range $index, $course := .Values.courselist }}
    - {{ $index }}: {{ $course | title | quote }}
    {{- end }}
```



```javascript
// 可以看到 courselist 下⾯将索引和对应的值都打印出来了
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 11:36:51 2021
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
  courselist: |-
    - 0: "K8s"
    - 1: "Python"
    - 2: "Golang"
    - 3: "Java"

[root@centos7 43helm]# 
```





示例3：

实际上具有键和值的数据结构都可以使⽤ range 来循环获得⼆者的值，⽐如可以对 .Values.course 这个字典来进⾏循环：

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
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```



```javascript
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Thu Nov 18 11:47:21 2021
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
  k8s: "DevOps"
  python: "Tornado"

// 删除templates目录下所有的文件
[root@centos7 43helm]# rm -rf mychart/templates/*.*
```



使⽤ range 循环，⽤变量 $key 、 $value 来接收字段 .Values.course 的键和值。这就是变量在 Helm 模板中的使⽤⽅法。