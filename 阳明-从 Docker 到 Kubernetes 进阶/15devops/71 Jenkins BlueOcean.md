1. 在实际的项⽬中，往往⼀个代码仓库都会有很多分⽀，⽐如开发、测试、线上这些分⽀都是分开的，⼀般情况下 开发或者测试的分⽀希望提交代码后就直接进⾏ CI/CD 操作，⽽线上的话最好增加⼀个⼈⼯⼲预 的步骤，这就需要 Jenkins 对代码仓库有多分⽀的⽀持，当然这个特性是被 Jenkins ⽀持的.

同样的，可以直接把要构建的脚本配置在 Jenkins Web UI 界⾯中就可以，但是最佳的⽅式是将脚本写⼊⼀个名为 Jenkinsfile 的⽂件中，跟随代码库进⾏统⼀的管理。



在git 库中新建⼀个dev分⽀，然后更改 main.go 的代码，打印当前运⾏的代码分⽀，通过环境变量注⼊进去，所以 k8s-jenkins-go-demo.yaml ⽂件的环境变量把当前代码分⽀注⼊进去.

分支地址：https://github.com/st22ab889/jenkins-demo/tree/dev



Jenkinsfile：

```javascript
node("hello-ops"){
    stage('Prepare') {
        echo "1.Prepare Stage"
        // checkout scm命令⽤来检出代码仓库中当前分⽀的代码
        checkout scm
        script {
            build_tag = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            if (env.BRANCH_NAME != 'master') {
                build_tag = "${env.BRANCH_NAME}-${build_tag}"
            }
        }
    }
    stage('Test') {
      echo "2.Test Stage"
    }
    stage('Build') {
        echo "3.Build Docker Image Stage"
        sh "docker build -t st22ab889/jenkins-demo:${build_tag} ."
    }
    stage('Push') {
        echo "4.Push Docker Image Stage"
        // push 到 docker hub 这一步非常慢
        //withCredentials([usernamePassword(credentialsId: 'docekrAuth', passwordVariable: 'dockerPassword', usernameVariable: 'dockerUser')]) {
        //    sh "docker login -u ${dockerUser} -p ${dockerPassword}"
        //    sh "docker push st22ab889/jenkins-demo:${build_tag}"
        //}
    }
    stage('Deploy') {
        echo "5. Deploy Stage"
        if (env.BRANCH_NAME == 'master') {
            input "please confirm deploy to Prod env ?"
        }
		
        sh "sed -i 's/<BUILD_TAG>/${build_tag}/' k8s-jenkins-go-demo.yaml"
        sh "sed -i 's/<BRANCH_NAME>/${env.BRANCH_NAME}/' k8s-jenkins-go-demo.yaml"

        sh "cat k8s-jenkins-go-demo.yaml"
        sh "kubectl apply -f k8s-jenkins-go-demo.yaml --record"
    }
}
```

在第⼀步中增加了checkout scm命令，⽤来检出代码仓库中当前分⽀的代码，为了避免各个环境 的镜像 tag 产⽣冲突，为⾮ master 分⽀的代码构建的镜像增加了⼀个分⽀的前缀，在第五步中如 果是 master 分⽀的话才增加⼀个确认部署的流程，其他分⽀都⾃动部署，并且还需要替换 k8s.yaml ⽂件中的环境变量的值。





k8s-jenkins-go-demo.yaml

```javascript
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins-demo
  namespace: default
spec:
  selector:
    matchLabels:
      app: jenkins-demo    
  template:
    metadata:
      labels:
        app: jenkins-demo
    spec:
      containers:
      - image: st22ab889/jenkins-demo:<BUILD_TAG>
        imagePullPolicy: IfNotPresent
        name: jenkins-demo
        env:
        - name: branch
          value: <BRANCH_NAME>
```





main.go

```javascript
package main
// Import the fmt for formatting strings
// Import os so we can read environment variables from the system
import (
	"fmt"
	"os"
)
func main() {
	fmt.Println("Hello, Kubernetes！I'm from Jenkins CI！")
	fmt.Println("BRANCH_NAME:", os.Getenv("branch"))
}
```





2. BlueOcean

这⾥使⽤ BlueOcean 这种⽅式来完成此处 CI/CD 的⼯作，BlueOcean 是 Jenkins 团队从⽤户体 验⻆度出发，专为 Jenkins Pipeline 重新设计的⼀套 UI 界⾯，仍然兼容以前的 fressstyle 类型的 job， BlueOcean 具有以下的⼀些特性：

- 连续交付（CD）Pipeline 的复杂可视化，允许快速直观的了解 Pipeline 的状态

- 可以通过 Pipeline 编辑器直观的创建 Pipeline

- 需要⼲预或者出现问题时快速定位，BlueOcean 显示了 Pipeline 需要注意的地⽅，便于异常处理和提⾼⽣产⼒

- ⽤于分⽀和拉取请求的本地集成可以在 GitHub 或者 Bitbucket 中与其他⼈进⾏代码协作时最⼤限度提⾼开发⼈员的⽣产⼒。



BlueOcean 可以安装在现有的 Jenkins 环境中，也可以使⽤ Docker 镜像的⽅式直接运⾏，这⾥直接在现有的 Jenkins 环境中安装 BlueOcean 插件。⼀般来说 Blue Ocean 在安装后不需要额外的配置，现有 Pipeline 和 Job 将继续照常运⾏。但 是 Blue Ocean 在⾸次创建或添加 Pipeline 的时候需要访问存储库（Git或GitHub）的权限，以便根据这些存储库创建 Pipeline。





2.1 

2.1.1 准备Github的Personal access token

登录GitHub  =>  点击右上方头像  => Settings  => Developer settings  =>  Personal access token  => Generate new token =>  填入Note, 勾选“repo”、 "admin:repo_hook"、"user" =>  Generate token ==> 复制token ==> 这个token只会展示一次，所以要复制下来保存好. 

这里生成的Token是: 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



2.1.2  在BlueOcean中创建pipeline

 打开 Blue Ocean  =>  如果之前没有创建过 Pipeline，则打开 Blue Ocean 后会看到⼀个"创建流水线"的按钮  =>  GitHub  =>  填入"access token"   => 点击 Connect   =>  选择organization  => 选择 repository   =>  点击“创建流水线”



2.2

Blue Ocean 会⾃动扫描仓库中的每个分⽀, 会为根⽂件夹中包含Jenkinsfile 的每个分⽀创建⼀个 Pipeline，⽐如这⾥有 master 和 dev 两个分⽀，并且两个分⽀下⾯都有 Jenkinsfile ⽂件，所以创 建完成后会⽣成两个 Pipeline.

这时可以把 master 分⽀的任务停⽌掉，只运⾏ dev 分⽀，然后点击 dev 这个 pipeline 就可以进⼊本次构建的详细⻚⾯，每个阶段都可以点击进去查看对应的构建结果.

如果dev分支的pipeline运行时创建的镜像TAG为“dev-[commit]”格式,说明是符合 Jenkinsfile 中的定义.



3.  Jenkins Blue Ocean ⾃动触发构建⼯作

如果改变dev分支的代码，然后提交代码到 dev 分⽀并且 push 到 Github 仓库，我们可以看到 Jenkins Blue Ocean ⾥ ⾯⾃动触发了⼀次构建⼯作.



如果把dev分支的代码合并到master分支,也会触发一次自动构建，在Jenkins 的 Blue Ocean ⻚⾯中，可以看到 master 分⽀下⾯的⼀个任务被⾃动触发了.



到这⾥我们就实现了多分⽀代码仓库的完整的 CI/CD 流程，示例很简单，只是单纯为了说明 CI/CD 的步骤，在后⾯会结合其 他的⼯具进⼀步对现有的⽅式进⾏改造，⽐如使⽤ Helm、Gitlab 等等.



另外如果对声明式的Pipeline⽐较熟悉, 推荐使⽤这种⽅式来编写Jenkinsfile ⽂件，因为使⽤声明式的⽅式编写的 Jenkinsfile ⽂件在 Blue Ocean 中不但⽀持得⾮常好，还可以直接在 Blue Ocean Editor 中可视化的对Pipeline 进⾏编辑操作，⾮常⽅便。





4. 资料



Jenkinsfile 的声明式语法相关资料如下:



DevOps CI/CD 实践培训(Jenkins 最佳实践课程2021版全新升级)

https://youdianzhishi.com/web/course/1026



2天搞定微服务 CI/CD 实践

https://youdianzhishi.com/web/course/1024



Jenkins 实践

https://youdianzhishi.com/web/course/1013



GitLabCI 实践课

https://youdianzhishi.com/web/course/1016

2天搞定微服务 CI/CD 实践





DevOps CI/CD 实践培训DevOps CI/CD 实践培训DevOps CI/CD 实践培训DevOps CI/CD 实践培训

DevOps CI/CD 实践培训

DevOps CI/CD 实践培训