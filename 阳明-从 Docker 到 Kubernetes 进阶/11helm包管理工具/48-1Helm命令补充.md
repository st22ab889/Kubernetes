1. search repositories for a keyword in charts

helm search repo [keyword] [flags]

```javascript
"Helm Search Repo" Examples:
# Search for stable release versions matching the keyword "nginx"
$ helm search repo nginx

# Search for release versions matching the keyword "nginx", including pre-release versions
$ helm search repo nginx --devel

# Search for the latest stable release for nginx-ingress with a major version of 1
$ helm search repo nginx-ingress --version ^1.0.0
```



```javascript
// 以下命令是在windows下操作
// 加上" -l"参数表示列出所有版本
C:\Users\WuJun>helm search repo gitlab -l
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
gitlab-jh/gitlab        5.8.2           14.8.2          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.8.1           14.8.1          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.8.0           14.8.0          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.7.4           14.7.4          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.7.3           14.7.3          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.7.2           14.7.2          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.7.1           14.7.1          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.7.0           14.7.0          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.6.5           14.6.5          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.6.4           14.6.4          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.6.3           14.6.3          Web-based Git-repository manager with wiki and ...
gitlab-jh/gitlab        5.6.2           14.6.2          Web-based Git-repository manager with wiki and ...

// 不加"-l"参数表示列出目前最新版本
C:\Users\WuJun>helm search repo gitlab
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
gitlab-jh/gitlab        5.8.2           14.8.2          Web-based Git-repository manager with wiki and ...
```



2.search for charts in the Artifact Hub or your own hub instance 

helm search hub [KEYWORD] [flags]

```javascript
// 以下命令是在windows下操作
C:\Users\WuJun>helm search hub gitlab
URL                                                     CHART VERSION   APP VERSION     DESCRIPTION
https://artifacthub.io/packages/helm/gitlab/gitlab      5.8.2           14.8.2          Web-based Git-repository manager with wiki and ...
https://artifacthub.io/packages/helm/gitlab-jh/...      5.8.2           14.8.2          Web-based Git-repository manager with wiki and ...
https://artifacthub.io/packages/helm/pascaliske...      0.2.4           14.7.2-ce.0     A Helm chart for GitLab Omnibus
https://artifacthub.io/packages/helm/cncf/gitlab        5.8.2           14.8.2          Web-based Git-repository manager with wiki and ...
//......
```



3. 拉取 helm charts 到本地

```javascript
// 以下命令是在windows下操作
// 获取最新版本的"gitlab-jh/gitlab", 版本下载到"C:\Users\WuJun"目录
C:\Users\WuJun>helm pull gitlab-jh/gitlab

// 获取指定版本的"gitlab-jh/gitlab", 版本下载到"C:\Users\WuJun"目录
C:\Users\WuJun>helm pull gitlab-jh/gitlab --version 5.8.2
```

