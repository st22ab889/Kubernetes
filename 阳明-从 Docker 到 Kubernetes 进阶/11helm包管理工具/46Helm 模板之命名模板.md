1. 在实际的应⽤中，往往有多个应⽤模板，这就需要⽤到新的概念--命名模板。命名模板也可以称为⼦模板，是限定在⼀个⽂件内部的模板，然后给⼀个名称。在使⽤命名模板 的时候有⼀个需要特别注意的是：模板名称是全局的，如果声明了两个相同名称的模板，最后加载的⼀个模板会覆盖掉另外的模板，由于⼦ chart 中的模板也是和顶层的模板⼀起编译的，所以在命名 的时候⼀定要注意，不要重名了。

为了避免重名，有个通⽤的约定就是为每个定义的模板添加上 chart 名称： {{ define "mychart.labels" }} ， define 关键字就是⽤来声明命名模板的，加上 chart 名称就可以避免不同 chart 间的模板出现冲突的情况。





1.1 声明和使⽤命名模板

使⽤ define 关键字就可以在模板⽂件内部创建⼀个命名模板，语法格式如下：

```javascript
{{ define "ChartName.TplName" }}
# 模板内容区域
{{ end }}
```



示例 1:

定义⼀个模板来封装⼀个 label 标签，然后将该模板嵌⼊到现有的 ConfigMap 中，然后使⽤ template 关键字在需要的地⽅包含进来：

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
{{- define "mychart.labels" }}
  labels:
    from: helm
    data: {{ now | htmlDate }}
{{- end }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" }}
data:
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```



```javascript
// 这个模板⽂件被渲染过后的结果如下所示：
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 10:12:33 2021
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
data:
  k8s: "DevOps"
  python: "Tornado"

```



可以看到 define 区域定义的命名模板被嵌⼊到了 template 所在的区域，但是如果将命名模板全都写⼊到⼀个模板⽂件中的话⽆疑也会增⼤模板的复杂性。





示例 2:

创建 chart 包时会在 templates ⽬录下⾯默认⽣成⼀个 _helpers.tpl ⽂件。 在 templates ⽬录下⾯除了 NOTES.txt ⽂件和以下划线 _ 开头命令的⽂件之外，都会被当做 kubernetes 的资源清单⽂件，⽽这个下划线开头的⽂件不会被当做资源清单外，还可以被其他 chart 模板中调⽤，这个就是 Helm 中的 partials ⽂件，所以完全可以将命名模板定义在这些 partials ⽂件中，默认 partials ⽂件就是  _helpers.tpl 。

```javascript
# templates/_helpers.tpl
{{/* ⽣成基本的 labels 标签 */}}
{{- define "mychart.labels" }}
  labels:
    from: helm
    data: {{ now | htmlDate }}
{{- end }}

```

⼀般情况下都会在命名模板头部加⼀个简单的⽂档块，⽤ /* */ 包裹起来，⽤来描述这个命名模板的⽤途。



```javascript
# templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" }}
data:
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

命名模板从模板⽂件 templates/configmap.yaml 中移除， 因为要嵌⼊命名模板内容，所以要保留 template，名称还是之前的 mychart.lables，这是因为模板名称是全局的，可以直接获取到。



```javascript
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 10:24:58 2021
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
data:
  k8s: "DevOps"
  python: "Tornado"

```





2. 模板范围



示例 1:

```javascript
# templates/_helpers.tpl
{{/* ⽣成基本的 labels 标签 */}}
{{- define "mychart.labels" }}
  labels:
    from: helm
    data: {{ now | htmlDate }}
    chart: {{ .Chart.Name }}
    version: {{ .Chart.Version }}
{{- end }}
```



```javascript
# templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" }}
data:
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```



```javascript
// 直接进⾏渲染出现了报错信息
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run
Error: INSTALLATION FAILED: unable to build kubernetes objects from release manifest: error validating "": error validating data: [unknown object type "nil" in ConfigMap.metadata.labels.chart, unknown object type "nil" in ConfigMap.metadata.labels.version]

```



报错的原因是，Chart对象不在定义的模板范围内，当命名模板被渲染时，它会接收由 template 调⽤时传⼊的作⽤域，由于这⾥并没有传⼊对应的作⽤域，因此模板中我们⽆法调⽤到 .Chart 对象。



示例 2:

在 template 后⾯加上作⽤域范围，渲染时传递给命名模板。

```javascript
# templates/_helpers.tpl
{{/* ⽣成基本的 labels 标签 */}}
{{- define "mychart.labels" }}
  labels:
    from: helm
    data: {{ now | htmlDate }}
    chart: {{ .Chart.Name }}
    version: {{ .Chart.Version }}
{{- end }}
```



```javascript
# templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" . }}
data:
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

在 template 末尾传递了 . ，表示当前的最顶层的作⽤范围.  如果template 末尾传递的是 .Values ，表示命名模板中可以使⽤ .Values 范围内的数据。



```javascript
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 10:39:58 2021
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
  k8s: "DevOps"
  python: "Tornado"

[root@centos7 43helm]# 
```





3. include 函数



示例 1:

将定义的 labels 单独提取出来放置到 _helpers.tpl ⽂件中：

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



然后将该命名模板插⼊到 configmap 模板⽂件的 labels 部分：

```javascript
# templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
    {{- template "mychart.labels" . }}
data:
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```



```javascript
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run
Error: INSTALLATION FAILED: unable to build kubernetes objects from release manifest: error validating "": error validating data: [ValidationError(ConfigMap): unknown field "chart" in io.k8s.api.core.v1.ConfigMap, ValidationError(ConfigMap): unknown field "from" in io.k8s.api.core.v1.ConfigMap, ValidationError(ConfigMap): unknown field "version" in io.k8s.api.core.v1.ConfigMap]

```

渲染出错, 这是因为 template 只是表示 ⼀个嵌⼊动作⽽已，不是⼀个函数，所以原本命名模板中是怎样的格式就是怎样的格式被嵌⼊进来. template 不能控制空格.



如果在命名模板中给内容区域都加上四个空格：

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
// 渲染结果正常
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 10:53:09 2021
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
  k8s: "DevOps"
  python: "Tornado"

[root@centos7 43helm]#
```





示例 2:

因为 template 不能控制空格，Helm 提供了 include 函数来代替 template  ，在需要控制空格的地⽅使⽤ indent 管道函数来⾃⼰控制。

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
# templates/configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{- include "mychart.labels" . | indent 4 }}
data:
  {{- range $key, $value := .Values.course }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

在 labels 区域需要4个空格，所以在管道函数 indent 中，传⼊参数4就可以。



```javascript
// 渲染模板结果正常
[root@centos7 43helm]#  helm install mychartdemo mychart/ --dry-run
NAME: mychartdemo
LAST DEPLOYED: Fri Nov 19 11:03:55 2021
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
  k8s: "DevOps"
  python: "Tornado"

// 删除templates目录下所有的文件
[root@centos7 43helm]# rm -rf mychart/templates/*.*
```



总结：在 Helm 模板中使⽤ include 函数要⽐ template 更好，因为 include 函数可以更好地处理 YAML ⽂件输出格式。





命名模板是 Helm 模板中⾮常重要的⼀个功能，在实际开发 Helm Chart 包的时候⾮常有⽤，到这⾥基本上把 Helm 模板中经常⽤到的⼀些知识点介绍完了。