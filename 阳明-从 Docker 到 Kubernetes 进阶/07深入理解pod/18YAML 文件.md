1. YAML 基础 



 yaml文件有两种格式: yml、yaml



它的基本语法规则如下： 

- ⼤⼩写敏感 

- 使⽤缩进表示层级关系 

- 缩进时不允许使⽤Tab键，只允许使⽤空格。

-  缩进的空格数⽬不重要，只要相同层级的元素左侧对⻬即可

-  # 表示注释，从这个字符⼀直到⾏尾，都会被解析器忽略。



注意：在 YAML ⽂件中绝对不要使⽤ tab 键。除非在编辑YAML文件的编辑器中设置tab健等于几个空格.



 在我们的 kubernetes 中，你只需要两种结构类型就⾏了： 

- Lists

- Maps



2. Maps :Map 是字典，就是⼀个 key:value 的键值对，Maps 可以让我们 更加⽅便的去书写配置信息，例如：

```javascript
--- 
apiVersion: v1 
kind: Pod

第⼀⾏的 --- 是分隔符，是可选的，在单⼀⽂件中，可⽤连续三个连字号 --- 区分多个⽂件.
上⾯的 YAML ⽂件转换成 JSON 格式如下
{ 
    "apiVersion": "v1", 
    "kind": "pod" 
}
```



Map嵌套Map(Map的value又是一个Map):

```javascript
---
apiVersion: v1
kind: Pod
metadata:				#Map的value也是Map
  name: kube100-site
  labels:				#这里可以看到是多层Map嵌套
    app: web
    
上面Map嵌套对应的Json文件如下:
{
	"apiVersion": "v1",
	"kind": "Pod",
	"metadata": {
		"name": "kube100-site",
		"labels": {
			"app": "web"
		}
	}
}
        
```





3. Lists ：是列表,也就是数组，在 YAML ⽂件中这样定义：

```javascript
# 每个项的定义以破折号（-）开头的,每项可与父元素对齐,也可与⽗元素直接缩进⼀个空格
args:
 - Cat   
 - Dog
 - Fish

#对应的JSON格式如下:
{
	"args": ["Cat", "Dog", "Fish"]
}    

```





4. Maps 和 Lists 互相嵌套

```javascript


# list 的⼦项也可以是 Maps，Maps 的⼦项也可以是list

# 如下YAML文件:containers 是 List 对象, 因为一个Pod下面可以用多个container
# 每个container又由由 name、image、 ports 组成.
# 每个container又可以暴露多个端口,所以ports又是个数组,数组的每项是个Map


---
apiVersion: v1
kind: Pod
metadata:
  name: kube100-site
  labels:
    app: web
spec:
  containers:
  - name: front-end
    image: nginx
    ports:
    - containerPort: 80
  - name: flaskapp-demo
    image: jcdemo/flaskapp
	ports:
	- containerPort:5000
 
# 转换为JSON格式如下:

{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
        "name": "kube100-site",
        "labels": {
            "app": "web"
        }
    },
    "spec": {
        "containers": [
            {
                "name": "front-end",
                "image": "nginx",
                "ports": [
                    {
                        "containerPort": "80"
                    }
                ]
            },
            {
                "name": "flaskapp-demo",
                "image": "jcdemo/flaskapp",
                "ports": [
                    {
                        "containerPort": "5000"
                    }
                ]
            }
        ]
    }
}
             
```





5. 用YAML文件定义一个Pod



用YAML文件定义k8s中的资源对象要看官方的API说明,这样才知道每个资源对象的apiVersion是哪个版本, 需要定义哪些字段,以及每个字段代表什么意思.



pod api 说明：https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/



```javascript
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: web
    typ: nginx
spec:
  containers:
  - name: frontend
    image: nginx
    ports:
    - containerPort: 80
```



[pod-example.yaml](attachments/C498C2ADE44E49F09238FB23553047DFpod-example.yaml)



定义好YAML后可以用以下命令导入YAML文件:

```javascript
# create: 单纯的创建
kubectl create -f pod-example.yaml

# apply: 如果没有才创建,有的话会去更细, 一般直接使用apply
kubectl apply -f pod-example.yaml
# "pod-example.yaml"中没有定义命名空间,所以使用了默认命名空间,相当于如下命令:
kubectl apply -f pod-example.yaml -n default

#查看pod
kubectl get pods

#查看详细信息
kubectl describe pod test-pod
```



