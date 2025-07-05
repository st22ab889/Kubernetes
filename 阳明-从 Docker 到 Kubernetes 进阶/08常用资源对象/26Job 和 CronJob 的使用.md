1.⼯作中经常都 会遇到⼀些需要进⾏批量数据处理和分析的需求，当然也会有按时间来进⾏调度的⼯作，在我们 的 Kubernetes 集群中为我们提供了 Job 和 CronJob 两种资源对象来应对我们的这种需求。 

- Job 负责处理任务，即仅执⾏⼀次的任务，它保证批处理任务的⼀个或多个 Pod 成功结束。 

- ⽽ CronJob 则就是在 Job 上加上了时间调度。



2.创建Job.

官网文档查询Job的apiVersion.

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#job-v1-batch

[job-demo.yaml](attachments/69ABCC3CE8434790AA62A017AC9EB2D8job-demo.yaml)

```javascript
# job-demo.yaml
---
apiVersion: batch/v1
kind: Job
metadata:
  name: job-demo
spec:
  template:
    metadata:
      name: job-demo
    spec:
      # Job不支持Always,只支持Never和OnFailure,因为Job相当于执行批处理任务,执行完就结束了.
      restartPolicy: Never
      containers:
      - name: counter
        image: busybox
        command:
        - "bin/sh"
        - "-c"
        - "for i in 9 8 7 6 5 4 3 2 1 0; do echo $i; done"

```





```javascript
kubectl create -f job-demo.yaml

kubectl get jobs
#查看Job的详细信息
kubectl describe job job-demo
#Job任务执行完就退出了状态变成了completed,而不是running
kubectl get pods
#查看当前任务的执⾏结果,Job实际上也是个Pod. 格式: kubectl logs $PodName
kubectl logs job-demo--1-m4hjj
```





3.创建CronJob.

CronJob 其实就是在 Job 的基础上加上了时间调度，可以在给定的时间点运⾏⼀个任务，也可以周期性地在给定时间点运⾏。这个实际上和我们 Linux 中的 crontab 就⾮常类似.

⼀个 CronJob 对象其实就对应中 crontab ⽂件中的⼀⾏，它根据配置的时间格式周期性地运⾏⼀ 个 Job ，格式和 crontab 也是⼀样的。crontab 的格式如下：

格式: 分 时 ⽇ ⽉ 星期 要运⾏的命令 

- 第1列分钟0～59 

- 第2列⼩时0～23

- 第3列⽇1～31 

- 第4列⽉1～ 12

-  第5列星期0～7（0和7表示星期天） 

- 第6列要运⾏的命令

```javascript
// 查看linux的定时任务
[root@centos7]# crontab -l
// 编辑定时任务
[root@centos7]# crontab -e
```





创建CronJob：

官网文档查询CronJob的apiVersion.

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#job-v1-batch

[cronJob-demo.yaml](attachments/3B95AF34882D4FDAA62932FA796A3F4FcronJob-demo.yaml)

```javascript
# cronJob-demo.yaml
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjob-demo
spec:
  # 每调度一次都会创建一个Job,这个表示只是保存最近2个成功的Job.不限制默认会被把每个成功的Job都保留下来
  successfulJobsHistoryLimit: 2
  # 设置小了出现错误不好排查.不限制会被把每个失败的Job都保留下来
  failedJobsHistoryLimit: 10
  # 每分钟执行
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          name: cronjob-demo
        spec:
          # Job不支持Always,只支持Never和OnFailure,因为Job相当于执行批处理任务,执行完就结束了.
          restartPolicy: OnFailure
          containers:
          - name: counter
            image: busybox
            command:
            - "bin/sh"
            - "-c"
            - "for i in 9 8 7 6 5 4 3 2 1 0; do echo $i; done"

```



```javascript
# 也可以用命令创建cronJob,如下:
kubectl run cronjob-demo --schedule="*/1 * * * *" --restart=OnFailure --image=busybox -- /bin/sh -c "date; echo Hello from the Kubernetes cluster"
```



```javascript
kubectl create -f cronJob-demo.yaml
#只会显示出cronjob
kubectl get cronjob
#这个命令会把Job和cronjob都显示出来
kubectl get jobs

# cronjob任务执行完就退出了变成了completed,而不是running.
# cronjob每调度一次都会新创建一个Pod,所以cronjob长生的Pod在不断增加
# 因为设置了"successfulJobsHistoryLimit: 2",所以最多也就只保留2个成功的Pod
kubectl get pods
# 查看当前任务的执⾏结果,cronjob实际上也是个Pod. 格式: kubectl logs $PodName
kubectl logs cronjob-demo-27195350--1-xplfr

# 查看cronjob的详细信息
kubectl describe cronjob cronjob-demo

# 删除cronjob,将会终⽌正在创建的Job.运⾏中的Job将不会被终⽌,
# k8s v1.10.0: 不会删除Job或它们的Pod
# k8s v1.22.0: 会删除Job或它们的Pod
kubectl delete cronjob cronjob-demo

# k8s v1.10.0: 为了清理那些Job和Pod，需要列出该CronJob创建的全部Job,然后删除它们
kubectl get jobs
#以下格式的命令可以一次性删除多个
kubectl delete jobs $jobName $jobName 

```



CronJob注意点:

- spec.schedule 字段是必须填写的，⽤来指定任务运⾏ 的周期，格式就和 crontab ⼀样.

- spec.jobTemplate ⽤来指定需要运⾏的任务，格 式当然和 Job 是⼀致.

- spec.successfulJobsHistoryLimit 和 .spec.failedJobsHistoryLimit ，表示历史限制，是可选的 字段。它们指定了可以保留多少完成和失败的 Job ，默认没有限制，所有成功和失败的 Job 都会被保 留。然⽽，当运⾏⼀个 Cron Job 时， Job 可以很快就堆积很多，所以⼀般推荐设置这两个字段的 值。如果设置限制的值为 0，那么相关类型的 Job 完成后将不会被保留

- ⼀旦 Job 被删除，由 Job 创建的 Pod 也会被删除。注意，所有由名称为 “hello” 的 Cron Job 创建的 Job 会以前缀字符串 “hello-” 进⾏命名。如果想要删除当前 Namespace 中的所有 Job，可以通过命令 kubectl delete jobs --all ⽴刻删除它们。

