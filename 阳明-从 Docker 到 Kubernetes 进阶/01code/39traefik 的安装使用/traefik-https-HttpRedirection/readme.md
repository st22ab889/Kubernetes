
Traefik & Kubernetes TLS DEMO:
https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/#tls

开启 traefik dashboard 的方法(http和https开启的方式不一样):
https://doc.traefik.io/traefik/operations/dashboard/

traefik 配置文件引入方法:
https://doc.traefik.io/traefik/providers/file/

Configuration Introduction
https://doc.traefik.io/traefik/getting-started/configuration-overview/

basicauth
https://doc.traefik.io/traefik/middlewares/http/basicauth/#usersfile


// 注意3点:
// 1.traefik 的 service type 要改为 NodePort。
// 2.因为这里是通过TLS访问 traefik-dashboard, 所以需要通过 traefik 的动态配置方式才能访问 dashboard, 这里将动态配置文件放入到 ConfigMap 中, 然后通过数据卷的方式挂载 ConfigMap 到 pod 中。
// 3."traefik-dynamic-conf.yaml"中的动态配置说明:
    # Traefik Dynamic Configuration
    http:
      routers:
        dashboard:
          # 这个配置说明只能通过 http://traefik.aaron.com/dashboard/ 这个路径访问
          # 所以需要在主机hosts文件中配置域名,例如： 192.168.32.100  traefik.aaron.com
          rule: Host(`traefik.aaron.com`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))
          service: api@internal
          middlewares:
            # 说明访问 dashboard 需要通过 ahth 验证
            - auth
      middlewares:
        auth:
          basicAuth:
            # 说明是通过用户名密码的方式认证            
            users:
              # 用户名和密码都是test,这里是使用"htpasswd"生成密码
              - "test:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/"
              # 用户名和密码都是test2
              - "test2:$apr1$d9hr9HBB$4HxwgUir3HP4EsggP/QNo0"


[root@centos7 traefik-https]# kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
traefik      NodePort    10.108.121.202   <none>        443:30646/TCP   2d4h
whoami       ClusterIP   10.104.191.105   <none>        80/TCP          2d4h

traefik dashboard (注意路径最后的"/",少了"/"页面会出现404):       
    https://traefik.aaron.com:30646/dashboard/

访问 whoami 服务:
    https://www.example.com:30646/bar
    https://www.example.com:30646/foo
    https://aaron.example.com:30646/bar
    https://aaron.example.com:30646/foo


