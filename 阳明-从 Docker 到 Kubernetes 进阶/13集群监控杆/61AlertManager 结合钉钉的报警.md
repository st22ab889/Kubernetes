1.  webhook接收器

上节配置的是 AlertManager ⾃带的邮件报警模板， AlertManager ⽀持很多种报警接收器，⽐如 slack、微信等，其中最为灵活的⽅式当然是使⽤ webhook 了，可以定义⼀个 webhook 来接收报警信息，然后在 webhook ⾥⾯去进⾏处理，需要发送怎样的报警信息⾃定义就可以。⽐如这⾥⽤ Flask 编写了⼀个简单的程序处理钉钉报警的 webhook 的程序：



2.  webhook 程序 - 钉钉报警

```javascript
可以根据⾃⼰的需求来定制报警数据，上述代码仓库地址：
https://github.com/cnych/alertmanager-dingtalk-hook
```



第一步:  编写 Flask 程序

```javascript
# app.py
import os
import json
import logging
import requests
import time
import hmac
import hashlib
import base64
import urllib.parse
from urllib.parse import urlparse

from flask import Flask
from flask import request

app = Flask(__name__)

logging.basicConfig(
    level=logging.DEBUG if os.getenv('LOG_LEVEL') == 'debug' else logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s')


@app.route('/', methods=['POST', 'GET'])
def send():
    if request.method == 'POST':
        post_data = request.get_data()
        app.logger.debug(post_data)
        send_alert(json.loads(post_data))
        return 'success'
    else:
        return 'weclome to use prometheus alertmanager dingtalk webhook server!'


def send_alert(data):
    token = os.getenv('ROBOT_TOKEN')
    secret = os.getenv('ROBOT_SECRET')
    if not token:
        app.logger.error('you must set ROBOT_TOKEN env')
        return
    if not secret:
        app.logger.error('you must set ROBOT_SECRET env')
        return
    timestamp = int(round(time.time() * 1000))
    url = 'https://oapi.dingtalk.com/robot/send?access_token=%s&timestamp=%d&sign=%s' % (token, timestamp, make_sign(timestamp, secret))

    status = data['status']
    alerts = data['alerts']
    alert_name = alerts[0]['labels']['alertname']

    def _mark_item(alert):
        labels = alert['labels']
        annotations = "> "
        for k, v in alert['annotations'].items():
            annotations += "{0}: {1}\n".format(k, v)
        if 'job' in labels:
            mark_item = "\n> job: " + labels['job'] + '\n\n' + annotations + '\n'
        else:
            mark_item = annotations + '\n'
        return mark_item

    if status == 'resolved':  # 告警恢复
        send_data = {
            "msgtype": "text",
            "text": {
                "content": "报警 %s 已恢复" % alert_name
            }
        }
    else:
        title = '%s 有 %d 条新的报警' % (alert_name, len(alerts))
        external_url = alerts[0]['generatorURL']
        prometheus_url = os.getenv('PROME_URL')
        if prometheus_url:
            res = urlparse(external_url)
            external_url = external_url.replace(res.netloc, prometheus_url)
        send_data = {
            "msgtype": "markdown",
            "markdown": {
                "title": title,
                "text": title + "\n" + "![](https://bxdc-static.oss-cn-beijing.aliyuncs.com/images/prometheus-recording-rules.png)\n" + _mark_item(alerts[0]) + "\n" + "[点击查看完整信息](" + external_url + ")\n"
            }
        }

    req = requests.post(url, json=send_data)
    result = req.json()
    if result['errcode'] != 0:
        app.logger.error('notify dingtalk error: %s' % result['errcode'])


def make_sign(timestamp, secret):
    """新版钉钉更新了安全策略，这里我们采用签名的方式进行安全认证
    https://ding-doc.dingtalk.com/doc#/serverapi2/qf2nxq
    """
    secret_enc = bytes(secret, 'utf-8')
    string_to_sign = '{}\n{}'.format(timestamp, secret)
    string_to_sign_enc = bytes(string_to_sign, 'utf-8')
    hmac_code = hmac.new(secret_enc, string_to_sign_enc, digestmod=hashlib.sha256).digest()
    sign = urllib.parse.quote_plus(base64.b64encode(hmac_code))
    return sign


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

```

以上代码⾮常简单，通过⼀个 ROBOT_TOKEN 的环境变量传⼊群机器⼈的 TOKEN，然后直接将 webhook 发送过来的数据直接以⽂本的形式转发给群机器⼈。



第二步:  编写 Dockerfile 并构建镜像

```javascript
# Dockerfile
FROM python:3.6.4

WORKDIR /src

# add app
ADD . /src

# install requirements
RUN pip install -r requirements.txt -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

# run server
CMD python app.py
```



```javascript
// 构建镜像-在命令行中进入到 Dockerfile ⽂件所在⽬录，运行如下命令:
docker build -t cnych/alertmanager-dingtalk-hook:v0.3.6 .
```



第三步:  将服务部署到集群中

```javascript
# dingtalk-hook.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dingtalk-hook
  namespace: kube-ops
spec:
  selector:
    matchLabels:
      app: dingtalk-hook
  template:
    metadata:
      labels:
        app: dingtalk-hook
    spec:
      containers:
      - name: dingtalk-hook
        image: cnych/alertmanager-dingtalk-hook:v0.3.6
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
          name: http
        env:
        - name: PROME_URL
          value: prometheus.local
        - name: LOG_LEVEL
          value: debug
        - name: ROBOT_TOKEN
          valueFrom:
            secretKeyRef:
              name: dingtalk-secret
              key: token
        - name: ROBOT_SECRET
          valueFrom:
            secretKeyRef:
              name: dingtalk-secret
              key: secret
        resources:
          requests:
            cpu: 50m
            memory: 100Mi
          limits:
            cpu: 50m
            memory: 100Mi

---
apiVersion: v1
kind: Service
metadata:
  name: dingtalk-hook
  namespace: kube-ops
spec:
  selector:
    app: dingtalk-hook
  ports:
  - name: hook
    port: 5000
    targetPort: http
```



要注意上⾯声明了⼀个 ROBOT_TOKEN 的环境变量，由于这是⼀个相对于私密的信息，所以这⾥从⼀个 Secret 对象中去获取，通过如下命令创建⼀个名为 dingtalk-secret 的 Secret 对象，然后部署上⾯的资源对象即可：

```javascript
// 第一步:将钉钉机器人TOKEN 创建成 Secret 资源对象
$ kubectl create secret generic dingtalk-secret --from-literal=token=<钉钉群聊的机器人TOKEN> --from-literal=secret=<钉钉群聊机器人的SECRET> -n kube-ops
secret "dingtalk-secret" created

$ kubectl create -f dingtalk-hook.yaml
deployment.apps "dingtalk-hook" created
service "dingtalk-hook" created
```



第四步: 以给 AlertManager 配置⼀个 webhook

```javascript
// alertmanager-conf.yaml 配置中增加⼀个路由接收器
......
      routes:
      - receiver: webhook
        match:
          filesystem: node
    receivers:
    - name: 'webhook'
      webhook_configs:
      - url: 'http://dingtalk-hook:5000'
        send_resolved: true
......
```

这⾥配置了⼀个名为 webhook 的接收器，地址为：http://dingtalk-hook:5000 ，这个地址就是上⾯部署的钉钉的 webhook 的接收程序的 Service 地址。

```javascript
// 更新 AlertManager 配置文件
kubectl apply -f alertmanager-conf.yaml 

// 通过 reload 操作使更新⽣效
curl -X POST "http://10.106.78.77:9093/-/reload"

// AlertManager 和 Prometheus 都可以通过 reload 操作进⾏重新加载
```



第五步:  在报警规则中添加⼀条关于节点⽂件系统使⽤情况的报警规则，注意 labels 标签要带上 filesystem=node ，这样报警信息就会被 webhook 这⼀个接收器所匹配。

```javascript
# prometheus-cm.yaml
......
      - alert: NodeFilesystemUsage
        expr: (node_filesystem_size_bytes{device="rootfs"} - node_filesystem_free_bytes{device="rootfs"}) / node_filesystem_size_bytes{device="rootfs"} * 100 > 10
        for: 2m
        labels:
          filesystem: node
        annotations:
          summary: "{{$labels.instance}}: High Filesystem usage detected"
          description: "{{$labels.instance}}: Filesystem usage is above 10% (current value is: {{ $value }}"
......
```



```javascript
// 更新 Prometheus 的 ConfigMap 资源对象(也可以先删除再创建)
kubectl apply -f prometheus-cm.yaml 
configmap/prometheus-config configured

kubectl get svc -n kube-ops
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                          AGE
prometheus   NodePort    10.106.78.77    <none>        9090:30216/TCP,9093:30950/TCP    12d
......

// 更新完成后, 隔⼀会⼉执⾏ reload 操作使更新⽣效
curl -X POST "http://10.106.78.77:9090/-/reload"
```



第六步:  在 Prometheus 的 Alert 路径下⾯查看报警信息。



可以看到页面多了一个 NodeFilesystemUsage 项目



隔⼀会⼉关于这个节点⽂件系统的报警就会被触发，由于这个报警信息包含⼀ 个 filesystem=node 的 label 标签，所以会被路由到 webhook 这个接收器中，也就是上⾯⾃定义的这个 dingtalk-hook，触发后可以观察这个 Pod 的⽇志：

```javascript
$ kubectl logs -f dingtalk-hook-cc677c46d-gf26f -n kube-ops
* Serving Flask app "app" (lazy loading)
* Environment: production
WARNING: Do not use the development server in a production environment.
Use a production WSGI server instead.
* Debug mode: off
* Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
10.244.2.217 - - [28/Nov/2018 17:14:09] "POST / HTTP/1.1" 200 -
```



可以看到 POST 请求已经成功了，同时这个时候正常来说就可以收到⼀条钉钉消息。



由于程序中是⽤⼀个⾮常简单的⽂本形式直接转发的，所以报警信息不够友好，但是没关系，有 了这个示例完全就可以根据⾃⼰的需要来定制消息模板，可以参考钉钉⾃定义机器⼈⽂ 档。

```javascript
钉钉⾃定义机器⼈⽂档：
https://open.dingtalk.com/document/group/custom-robot-access

AlertManager 的使用：
https://www.qikqiak.com/k8s-book/docs/57.AlertManager%E7%9A%84%E4%BD%BF%E7%94%A8.html
```



到这⾥就完成了完全⼿动的控制 Prometheus、Grafana 以及 AlertManager 的报警功能， 接下来是 k8s 中更加⾃动化的监控⽅案：Prometheus-Operator。