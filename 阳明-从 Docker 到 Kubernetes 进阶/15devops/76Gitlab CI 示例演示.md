1. GitLab CI .gitlab-ci.yml 文件介绍



Job：

Gitlab CI 的环境都准备好后就来看下⽤于描述 Gitlab CI 的 .gitlab-ci.yml ⽂件。 ⼀个 Job 在 .gitlab-ci.yml ⽂件中⼀般如下定义，下⾯这个 Job 会在 test 这个 Stage 阶段运⾏。 

```javascript
# 运行golang测试用例
test:
  stage: test
  script:
    - go test ./...
```



Stage ：

为了指定运⾏的 Stage 阶段，可以在 .gitlab-ci.yml ⽂件中放置任意⼀个简单的列表：

```javascript
# 所有 Stage
stages:
  - test
  - build
  - release
  - deploy
```



指定全局参数：

可以指定⽤于在全局或者每个作业上执⾏命令的镜像：

```javascript
# 对于未指定镜像的作业，会使用下面的镜像
image: golang:1.10.3-stretch
# 或者对于特定的job使用指定的镜像
test:
  stage: test
  image: python:3
  script:
    - echo Something in the test step in a python:3 image
```

对于 .gitlab-ci.yml ⽂件的的其他部分，请查看如下⽂档介绍： 

- https://docs.gitlab.com/ee/ci/yaml/index.html





2. 回顾上节 Gitlab CI 示例项目 

在上节的项⽬中定义了 4 个构建阶段：

- test

- build

- release

- review

- deploy



2.1 完整的 .gitlabci.yml ⽂件如下：

[.gitlab-ci.yml](attachments/7E9D9F7C1098433CA984414A4C2A0739.gitlab-ci.yml)

```javascript
# ...\gitlab-ci-k8s-demo\.gitlab-ci.yml
image:
  name: golang:1.10.3-stretch
  entrypoint: ["/bin/sh", "-c"]

# The problem is that to be able to use go get, one needs to put
# the repository in the $GOPATH. So for example if your gitlab domain
# is mydomainperso.com, and that your repository is repos/projectname, and
# the default GOPATH being /go, then you'd need to have your
# repository in /go/src/mydomainperso.com/repos/projectname
# Thus, making a symbolic link corrects this.
before_script:
  - mkdir -p "/go/src/git.aaron.com/${CI_PROJECT_NAMESPACE}"
  - ln -sf "${CI_PROJECT_DIR}" "/go/src/git.aaron.com/${CI_PROJECT_PATH}"
  - cd "/go/src/git.aaron.com/${CI_PROJECT_PATH}/"

stages:
  - test
  - build
  - release
  - review
  - deploy

# 这里 test 代表Job, 这里意思是 test 属于 test 阶段的 Job 
test:
  stage: test
  script:
    - make test

test2:
  stage: test
  script:
    - sleep 3
    - echo "We did it! Something else runs in parallel!"

# 这里 compile 代表Job, 这里意思是 compile 属于 build 阶段的 Job 
compile:
  stage: build
  script:
    # Add here all the dependencies, or use glide/govendor/...
    # to get them automatically.
    - make build
  artifacts:
    paths:
      - app

image_build:
  stage: release
  image: docker:latest
  # Docker in Docker原理是: 容器内仅部署 docker 命令行工具(作为客户端)，实际命令交由宿主机内的 docker-engine(服务器)
  # 修改 docker 启动参数原理: docker 命令行工具通过 tcp://localhost:2375 连接到 docker-engine, 发送修改参数的指令给 docker-engine
  variables:
    DOCKER_DRIVER: overlay
    DOCKER_HOST: tcp://localhost:2375
  # dind 是 Docker in Docker 的缩写, dind官方仓库地址为: https://hub.docker.com/_/docker?tab=tags
  services:
    - name: docker:17.03-dind
      #因为这里使用 docker hub, 所以不需要在 docker 启动参数上加 --insecure-registry, 私有仓库可能会加.
      #command: ["--insecure-registry=registry.aaron.com"]
  script:
    - docker info
    
    # 这种方式登录不安全, 因为会把密码打印到 shell 日志上.
    #- docker login -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" registry.aaron.com
    
    # 也可以将仓库地址设置为一个变量, 以参数的形式配置到 GitLab 环境中.
    #docker login -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" "${CI_REGISTRY}"
    
    # 这里仍然使用 docker hub 作为镜像仓库,如果使用私有仓库,需要在后面加上私有仓库地址.
    - echo "${CI_REGISTRY_PASSWORD}" | docker login --username ${CI_REGISTRY_USER} --password-stdin
    
    - docker build -t "${CI_REGISTRY_IMAGE}:latest" .
    - docker tag "${CI_REGISTRY_IMAGE}:latest" "${CI_REGISTRY_IMAGE}:${CI_COMMIT_REF_NAME}"
    - test ! -z "${CI_COMMIT_TAG}" && docker push "${CI_REGISTRY_IMAGE}:latest"
    - docker push "${CI_REGISTRY_IMAGE}:${CI_COMMIT_REF_NAME}"

deploy_review:
  image: st22ab889/kubectl:1.22.1-0
  stage: review
  only:
    - branches
  except:
    - tags
  environment:
    # 这里指定 CI 环境, 一般有 dev、uat、prod 三种环境
    name: dev
    url: https://dev-gitlab-k8s-demo.aaron.com
    on_stop: stop_review
  script:
    - kubectl version
    - cd manifests/
    - sed -i "s/__CI_ENVIRONMENT_SLUG__/${CI_ENVIRONMENT_SLUG}/" deployment.yaml ingress.yaml service.yaml
    - sed -i "s/__VERSION__/${CI_COMMIT_REF_NAME}/" deployment.yaml ingress.yaml service.yaml
    - |
      if kubectl apply -f deployment.yaml | grep -q unchanged; then
          echo "=> Patching deployment to force image update."
          kubectl patch -f deployment.yaml -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"ci-last-updated\":\"$(date +'%s')\"}}}}}"
      else
          echo "=> Deployment apply has changed the object, no need to force image update."
      fi
    - kubectl apply -f service.yaml || true
    - kubectl apply -f ingress.yaml
    - kubectl rollout status -f deployment.yaml
    - kubectl get all,ing -l ref=${CI_ENVIRONMENT_SLUG}

stop_review:
  image: st22ab889/kubectl:1.22.1-0
  stage: review
  variables:
    GIT_STRATEGY: none
  when: manual
  only:
    - branches
  except:
    - master
    - tags
  environment:
    name: dev
    action: stop
  script:
    - kubectl version
    - kubectl delete ing -l ref=${CI_ENVIRONMENT_SLUG}
    - kubectl delete all -l ref=${CI_ENVIRONMENT_SLUG}

deploy_live:
  image: st22ab889/kubectl:1.22.1-0
  stage: deploy
  environment:
    name: live
    url: https://live-gitlab-k8s-demo.aaron.com
  only:
    - tags
  when: manual
  script:
    - kubectl version
    - cd manifests/
    - sed -i "s/__CI_ENVIRONMENT_SLUG__/${CI_ENVIRONMENT_SLUG}/" deployment.yaml ingress.yaml service.yaml
    - sed -i "s/__VERSION__/${CI_COMMIT_REF_NAME}/" deployment.yaml ingress.yaml service.yaml
    - kubectl apply -f deployment.yaml
    - kubectl apply -f service.yaml
    - kubectl apply -f ingress.yaml
    - kubectl rollout status -f deployment.yaml
    - kubectl get all,ing -l ref=${CI_ENVIRONMENT_SLUG}
```

上⾯的 .gitlab-ci.yml ⽂件中还有⼀些特殊的属性，如限制运⾏的的 when 和 only 参数，例如 only: ["tags"] 表示只为创建的标签运⾏，更多的信息可以通过查看 Gitlab CI YAML 介绍：https://docs.gitlab.com/ee/ci/yaml/index.html



注意：如果在 .gitlab-ci.yml ⽂件中将应⽤的镜像构建完成后推送到了私有仓库，且 Kubernetes 资源清单⽂件中使⽤的是这个私有镜像，那么就需要配置⼀个 imagePullSecret ，否则在Kubernetes 集群中是⽆法拉取私有镜像的：

```javascript
# 替换下⾯相关信息为⾃⼰的
$ kubectl create secret docker-registry myregistry --docker-server=registry.aaron.com --docker-username={username} --docker-password={password} --docker-email={email} -n gitlab
secret "myregistry" created
// 如果是使用的私有仓库镜像,在下⾯的 Deployment 的资源清单⽂件中会使⽤到创建的 myregistry
// 这里并不是使用的私有仓库镜像,使用的是 docker hub, 所以用不上创建的 myregistry
```



接下来为应⽤创建 Kubernetes 资源清单⽂件，添加到代码仓库中。



2.2  ⾸先创建 Deployment 资源：

[deployment.yaml](attachments/46E4354363734F758F00DF9E87D88AB6deployment.yaml)

```javascript
# ...\gitlab-ci-k8s-demo\manifests\deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitlab-k8s-demo-__CI_ENVIRONMENT_SLUG__
  namespace: gitlab
  labels:
    app: gitlab-k8s-demo
    ref: __CI_ENVIRONMENT_SLUG__
    track: stable
spec:
  replicas: 2
  selector:
    matchLabels:
      app: gitlab-k8s-demo
      ref: __CI_ENVIRONMENT_SLUG__
  template:
    metadata:
      labels:
        app: gitlab-k8s-demo
        ref: __CI_ENVIRONMENT_SLUG__
        track: stable
    spec:
      # 注意:如果使用的是私有仓库镜像,就要创建一个 secret, 让后配置到 imagePullSecrets
      # 这里并不是使用的私有仓库镜像,使用的是 docker hub, 所以不用配置 imagePullSecrets
      #imagePullSecrets:
      #  - name: myregistry
      containers:
      - name: app
        image: st22ab889/gitlab-ci-demo:__VERSION__
        imagePullPolicy: Always
        ports:
        - name: http-metrics
          protocol: TCP
          containerPort: 8000
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 3
          timeoutSeconds: 2
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 3
          timeoutSeconds: 2
```

上面是⼀个基本的 Deployment 资源清单的描述：

- 像 __CI_ENVIRONMENT_SLUG__ 和 __VERSION__  这样的占位符⽤于区分不同的环境，

- __CI_ENVIRONMENT_SLUG__  将由 CI 环境名称（环境名称可以自己指定，一般有 dev、uat、prod 三种环境）和 __VERSION__ 替换为镜像标签。



2.3  为了能够连接到部署的 Pod，还需要 Service，对应的 Service 资源清单如下：

[service.yaml](attachments/4D9D0ECC90F24C87B297CDF748E7E765service.yaml)

```javascript
# ...\gitlab-ci-k8s-demo\manifests\service.yaml
apiVersion: v1
kind: Service
metadata:
  name: gitlab-k8s-demo-__CI_ENVIRONMENT_SLUG__
  namespace: gitlab
  labels:
    app: gitlab-k8s-demo
    ref: __CI_ENVIRONMENT_SLUG__
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8000"
    prometheus.io/scheme: "http"
    prometheus.io/path: "/metrics"
spec:
  type: ClusterIP
  ports:
    - name: http-metrics
      port: 8000
      protocol: TCP
  selector:
    app: gitlab-k8s-demo
    ref: __CI_ENVIRONMENT_SLUG__
```

从Service 资源清单可知，应用程序运行8000端口，端口名为 http-metrics，前面监控章节使用prometheus-operator为 Prometheus 创建了自动发现的配置，所以在annotations里面配置上上面的这几个注释后，Prometheus 就可以自动获取应用的监控指标数据。



现在 Service 创建成功了，但是外部用户还不能访问到应用，可以把 Service 设置成 NodePort 类型，另外一个常见的方式当然就是使用 Ingress ，可以通过 Ingress 来将应用暴露给外面用户使用。



2.4 Ingress 对应的资源清单文件如下：

[ingress.yaml](attachments/2F5751916E1244068098E047C3388884ingress.yaml)

```javascript
# ...\gitlab-ci-k8s-demo\manifests\ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitlab-k8s-demo-__CI_ENVIRONMENT_SLUG__
  namespace: gitlab
  labels:
    app: gitlab-k8s-demo
    ref: __CI_ENVIRONMENT_SLUG__
spec:
  rules:
  - host: __CI_ENVIRONMENT_SLUG__-gitlab-k8s-demo.aaron.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gitlab-k8s-demo-__CI_ENVIRONMENT_SLUG__
            port:
              number: 8000
```

如果想配置 https 访问，可以⾃⼰⽤ CA 证书创建⼀个 tls 密钥，也可以使⽤ certmanager 来⾃动为应⽤程序添加 https。当然要通过上⾯的域名进⾏访问，还需要进⾏ DNS 解析的，__CI_ENVIRONMENT_SLUG__ 值为 live 或 dev。

需要在主机的 hosts 文件中添加如下域名映射：

```javascript
192.168.32.100  dev-gitlab-k8s-demo.aaron.com
192.168.32.100  live-gitlab-k8s-demo.aaron.com
```



注：域名映射有三种方法可以实现：

- 在主机的 hosts 文件中添加域名映射。

- 可以使⽤ DNS 解析服务商的 API 来⾃动创建域名解析。

- 也可以使⽤ Kubernetes incubator 孵化的项⽬ external-dns operator 来进⾏操作。



2.5 所需要的资源清单和 .gitlab-ci.yml ⽂件准备好后，就可以触发 Gitlab CI 构建。有两种方式可以触发构建：

- 在 GitLab 页面上点击。

- ⼩⼩的添加任意一个文件或任意改动，提交代码后自动触发 Gitlab CI 构建。

触发后在 Gitlab 中就可以看到⼀个新的 Pipeline 在构建项⽬。





2.6 GitLab 以及 GitLab CI 部署的项目测试衔接：

```javascript
GitLab 主页:
     http://git.aaron.com:31293
     登录：
         Username：root
         Password：admin321
 
GitLab CI 部署的项目测试衔接：
     http://dev-gitlab-k8s-demo.aaron.com:31293/
     
需要在访问的主机的 hosts 文件加上域名映射, 当前所使用的主机域名映射如下:
    192.168.32.100  git.aaron.com
    192.168.32.100  dev-gitlab-k8s-demo.aaron.com
```





2.7 Gitlab CI 示例项目用到的文件

[75Gitlab CI 的基本使用.zip](attachments/F27716061E26453B96275E29ECC1FCAB75Gitlab CI 的基本使用.zip)





下节介绍使⽤ Jenkins + Gitlab + Harbor + Helm + Kubernetes 来实现 ⼀个完整的 CI/CD 流⽔线作业。





