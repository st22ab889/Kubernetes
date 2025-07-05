1. ingress tls 以及 path 路径在 ingress 对象中的使⽤⽅法

现在⼤部分场景下⾯都会使⽤ https 来访问服务，这里将使⽤⼀个⾃签名的证书， 当然有在⼀些正规机构购买的 CA 证书是最好的，这样任何⼈访问服务的时候都是受浏览器信任的证书。

```javascript
# 使⽤ openssl 命令⽣成 CA 证书
openssl req -newkey rsa:2048 -nodes -keyout tls.key -x509 -days 365 -out tls.crt

# 有了证书,可以使⽤ kubectl 创建⼀个 secret 对象来存储上⾯的证书
kubectl create secret generic traefik-cert --from-file=tls.crt --from-file=tls.key -n ku be-system
```



2. 配置 Traefik

前⾯我们使⽤的是 Traefik 的默认配置，现在配置 Traefik，让其⽀持 https：



traefik.toml

```javascript

```







内容版本差异太大,暂时不看