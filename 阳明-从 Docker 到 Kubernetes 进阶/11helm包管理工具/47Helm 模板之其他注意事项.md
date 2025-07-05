1. 在开发中有一些要注意的⼀些知识点，⽐如 NOTES.txt ⽂件的使⽤、 ⼦ Chart 的使⽤、全局值的使⽤





2. NOTES.txt ⽂件

在使⽤ helm install 命令的时候，Helm 都会打印出⼀堆介绍信息，这样当别的⽤户 在使⽤ chart 包的时候就可以根据这些注释信息快速了解 chart 包的使⽤⽅法，这些信息就是编写在 NOTES.txt ⽂件之中的，这个⽂件是纯⽂本的，但是它和其他模板⼀样，具有所有可⽤的 普通模板函数和对象。

为创建的 chart 包提供⼀个清晰的 NOTES.txt ⽂件是⾮常有必要的，可以为⽤户提供有关如何使⽤新安装 chart 的详细信息，这是⼀种⾮常友好的⽅式⽅法。



示例1:

```javascript
# templates/NOTES.txt
Thank you for installing {{ .Chart.Name }}.
Your release is named {{ .Release.Name }}.
To learn more about the release, try:
  $ helm status {{ .Release.Name }}
  $ helm get {{ .Release.Name }}
```

上面的 NOTES.txt ⽂件也使⽤了 Chart 和 Release 对象



```javascript
# templates/_helpers.tpl
{{/* ⽣成基本的 labels 标签 */}}
{{- define "mychart.labels" }}
from: helm
data: {{ now | htmlDate }}
chart: {{ .Chart.Name }}
version: {{ .Chart.Version }}
{{- end }}
```



```javascript
# values.yaml
course:
  k8s: DevOps
  python: Tornado
```



```javascript
# templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{- include "mychart.labels" . | indent 4 }}
data:
  {{- if eq .Values.course.python "Tornado" }}
  web: true 
  {{- end }}
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
  courselist:
  - 0: "K8s"
  - 1: "Python"
  - 2: "Search"
  - 3: "Golang"
```



```javascript
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
Error: INSTALLATION FAILED: unable to build kubernetes objects from release manifest: error validating "": error validating data: ValidationError(ConfigMap.data.courselist): invalid type for io.k8s.api.core.v1.ConfigMap.data: got "array", expected "string"

```

可以发现渲染失败,因为 helm 在安装时会检查对应的 kubernetes 资源对象对 yaml ⽂件的格式要求，⽐如这⾥是⼀个 ConfigMap 的资源对象，ConfigMap 对 data 区域的内容是有严格要求， configmap.yaml 虽然的确是⼀个合法的 yaml ⽂件的格式，但是对 ConfigMap 就不合法了，需要把 courselist 这个字典数组变成⼀个多⾏的字符串，这样就是⼀个合法的 ConfigMap了。





示例2:  在示例1的基础上改进

```javascript
# values.yaml
course:
  k8s: DevOps
  python: Tornado
courselist:
- 0: "K8s"
- 1: "Python"
- 2: "golang"
- 3: "java"
```



```javascript
# templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{- include "mychart.labels" . | indent 4 }}
data:
  {{- if eq .Values.course.python "Tornado" }}
  web: true 
  {{- end }}
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
  courselist: |-
    {{- range $index, $course := .Values.courselist }}
    {{- range $key, $value := $course }}
    {{ $key }}: {{ $value | title | quote }}
    {{- end }}
    {{- end }}
```



```javascript
// 可以看到下⾯的注释部分也被渲染出来了
// NOTES.txt ⾥⾯使⽤到的模板对象都被正确渲染了
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 22:06:49 2021
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
  labels:    
    from: helm
    data: 2021-11-19
    chart: mychart
    version: 0.1.0
data:
  web: true
  k8s: "DevOps"
  python: "Tornado"
  courselist: |-
    0: "K8s"
    1: "Python"
    2: "Golang"
    3: "Java"

NOTES:
Thank you for installing mychart.
Your release is named mychartdemo.
To learn more about the release, try:
  $ helm status mychartdemo
  $ helm get mychartdemo

// 验证成功,NOTES文件也被正确渲染
```





注意点1:

```javascript
# templates/configmap.yaml
......
    {{- range $index, $course := .Values.courselist }}
    {{ $course | title | quote }} 
    {{- end }}
......
```



```javascript
// 渲染错误
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
Error: INSTALLATION FAILED: template: mychart/templates/configmap.yaml:17:17: executing "mychart/templates/configmap.yaml" at <title>: wrong type for value; expected string; got map[string]interface {}
```

渲染错误原因：{{- range $index, $course := .Values.courselist }},这里 $course

拿到的是一个 map[string]interface 对象。把这个对象的值传给 title 函数处理时出现了错误



注意点2:

```javascript
# templates/configmap.yaml
......
    {{- range $index, $course := .Values.courselist }}
    {{ $course | quote }}
    {{- end }}
......
```



```javascript
// 渲染成功
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
......
data:
  web: true
  k8s: "DevOps"
  python: "Tornado"
  courselist: |-
    "map[0:K8s]"
    "map[1:Python]"
    "map[2:golang]"
    "map[3:java]"
......
[root@centos7 43helm]# 
```

这里能正确渲染是因为没有使用  title 函数，map[string]interface 这个对象直接传给 quote  函数，把这个对象渲染成了字符串，所以能够安装成功。虽然安装成功，但不是预期的结果。需要把 map[string]interface 这个对象再次 range 循环，才能拿到正确的key 和 value。



注意点3:

再次修改 configmap.yaml 文件, 渲染成功且结果符合预期：

```javascript
# templates/configmap.yaml
......    
    {{- range $index, $course := .Values.courselist }}
    {{- range $key, $value := $course }}
    {{ $key }}: {{ $value | title | quote }}
    {{- end }}
    {{- end }}
...... 
```



```javascript
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
......
data:
  web: true
  k8s: "DevOps"
  python: "Tornado"
  courselist: |-
    0: "K8s"
    1: "Python"
    2: "Golang"
    3: "Java"
......
[root@centos7 43helm]# 
```





3. ⼦ chart 包

chart 也可以有⼦ chart 的依赖关系，它们也有⾃⼰的值和模板，以下是关于⼦ chart 的说明：

- ⼦ chart 是独⽴的，所以⼦ chart 不能明确依赖于其⽗ chart

- ⼦ chart ⽆法访问其⽗ chart 的值

- ⽗ chart 可以覆盖⼦ chart 的值

- Helm 中有全局值的概念，可以被所有的 chart 访问



第一步: 创建⼦ chart

在创建 chart 包的时候，在根⽬录下⾯有⼀个名为 charts 的空⽬录，这就是⼦ chart 所在的⽬录，在该⽬录下⾯添加⼀个新的 chart：

```javascript
[root@centos7 43helm]# cd mychart/charts/
[root@centos7 charts]# helm create mysubchart
Creating mysubchart
[root@centos7 charts]# tree ../..
../..
└── mychart
    ├── charts
    │   └── mysubchart
    │       ├── charts
    │       ├── Chart.yaml
    │       ├── templates
    │       │   ├── deployment.yaml
    │       │   ├── _helpers.tpl
    │       │   ├── hpa.yaml
    │       │   ├── ingress.yaml
    │       │   ├── NOTES.txt
    │       │   ├── serviceaccount.yaml
    │       │   ├── service.yaml
    │       │   └── tests
    │       │       └── test-connection.yaml
    │       └── values.yaml
    ├── Chart.yaml
    ├── templates
    │   ├── configmap.yaml
    │   ├── _helpers.tpl
    │   └── NOTES.txt
    └── values.yaml

7 directories, 15 files

// 将⼦ chart 模板中的⽂件全部删除
[root@centos7 charts]# rm -rf mysubchart/templates/*
[root@centos7 charts]# ls mysubchart/templates
[root@centos7 charts]# pwd
/k8s-yaml/43helm/mychart/charts

```



第二步: ⼦ chart 创建⼀个简单的模板和 values ⽂件

```javascript
# mychart/charts/mysubchart/values.yaml
in: mysub
```



```javascript
# mychart/charts/mysubchart/templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap2
data:
  in: {{ .Values.in }}
```



```javascript
// 每个⼦ chart 都是独⽴的 chart，所以可以单独给 mysubchart 进⾏测试
[root@centos7 charts]# helm install mysubchartdemo mysubchart/ --dry-run
NAME: mysubchartdemo
LAST DEPLOYED: Fri Nov 19 22:59:20 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: mysubchart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysubchartdemo-configmap2
data:
  in: mysub

[root@centos7 charts]# 
```



第三步: 值覆盖 

⽗ chart 可以覆盖⼦ chart 的值。

现在 mysubchart 这个⼦ chart 属于 mychart 这个⽗ chart ，由于 mychart 是⽗级，所以可以在 mychart 的 values.yaml ⽂件中直配置⼦ chart 中的值。

如下是 ⽗ chart 的配置:

```javascript
# mychart/values.yaml
course:
  k8s: DevOps
  python: Tornado

mysubchart:
  in: parent
```

注意最后两⾏，mysubchart 部分内的任何指令都会传递到 mysubchart 这个⼦ chart 中去。mysubchart 这个名称一定要和子 chart 的目录名称一样。



```javascript
# mychart/templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{- include "mychart.labels" . | indent 4 }}
data:
  {{- if eq .Values.course.python "Tornado" }}
  web: true 
  {{- end }}
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```



如下是 ⼦ chart 的配置：

```javascript
# mychart/charts/mysubchart/values.yaml
in: mysub
```



```javascript
# mychart/charts/mysubchart/templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap2
data:
  in: {{ .Values.in }}
```



在⽗ chart  所在的根⽬录中执⾏调试命令：

```javascript
[root@centos7 43helm]# pwd
/k8s-yaml/43helm
[root@centos7 43helm]# ls
mychart
// 可以查看到⼦ chart 也被⼀起渲染了
// 可以看到⼦ chart 中的值已经被顶层的值给覆盖了
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 23:17:43 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: mychart/charts/mysubchart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap2
data:
  in: parent
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap
  labels:    
    from: helm
    data: 2021-11-19
    chart: mychart
    version: 0.1.0
data:
  web: true
  k8s: "DevOps"
  python: "Tornado"

NOTES:
Thank you for installing mychart.
Your release is named mychartdemo.
To learn more about the release, try:
  $ helm status mychartdemo
  $ helm get mychartdemo
[root@centos7 43helm]# 
```



第四步: 全局值

在某些场景需要某些值在所有模板中都可以使⽤，这就需要⽤到全局 chart 值。全局值可以从任何 chart 或者⼦ chart中进⾏访问使⽤，values 对象中有⼀个保留的属性 是 Values.global ，就可以被⽤来设置全局值。注意：全局值只能设置在⽗ chart 的 values.yaml ⽂件中。



如下是 ⽗ chart 的配置:

```javascript
# mychart/values.yaml
course:
  k8s: DevOps
  python: Tornado

mysubchart:
  in: parent

global:
  allin: helm
```

在 values.yaml ⽂件中添加了⼀个 global 的属性，这样的话⽆论在⽗ chart 中还是在⼦ chart 中都可以通过 {{ .Values.global.allin }} 来访问这个全局值。



```javascript
# mychart/templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{- include "mychart.labels" . | indent 4 }}
data:
  {{- if eq .Values.course.python "Tornado" }}
  web: true 
  {{- end }}
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
  allin: {{ .Values.global.allin }}
```



如下是 ⼦ chart 的配置：

```javascript
# mychart/charts/mysubchart/values.yaml
in: mysub
```



```javascript
# mychart/charts/mysubchart/templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap2
data:
  in: {{ .Values.in }}
  allin: {{ .Values.global.allin }}
```



在⽗ chart  所在的根⽬录中执⾏调试命令：

```javascript
[root@centos7 43helm]# pwd
/k8s-yaml/43helm
[root@centos7 43helm]# ls
mychart
// 可以看到两个模板中都输出了 allin: helm 这样的值
[root@centos7 43helm]# helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 23:29:54 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: mychart/charts/mysubchart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap2
data:
  in: parent
  allin: helm
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychartdemo-configmap
  labels:    
    from: helm
    data: 2021-11-19
    chart: mychart
    version: 0.1.0
data:
  web: true
  k8s: "DevOps"
  python: "Tornado"
  allin: helm

NOTES:
Thank you for installing mychart.
Your release is named mychartdemo.
To learn more about the release, try:
  $ helm status mychartdemo
  $ helm get mychartdemo

[root@centos7 43helm]#

```



总结：全局变量对于传递信息⾮常有⽤， 不过要注意不能滥⽤全局值。





另外值得注意的是⽗ chart 和⼦ chart 可以共享命名模板。任何 chart 中的任何定义块都可⽤于其他 chart，所以在给命名模板定义名称的时候添加了 chart名称这样的前缀，避免冲突。

