
本示例存在以下问题
1.ingress没起作用
    这个地址都能访问到traefik
        http://aaron.traefik.com:31895
        http://aaron.nginx.com:31895

    这个地址都能访问到nginx
        http://aaron.traefik.com:31320
        http://aaron.nginx.com:32320

2.待确认:ingress不支持ClusterIP的Service
    This ingress controller doesn't support ClusterIP service type yet.ClusterIP is a virtual IP in k8s, which is handled by kube-proxy. 
    Using ClusterIP, will result in Kong being unable to do sticky sessions or other load balancing. It's ideal that your ingress point 
    is aware of all the upstream pods of a service and then load balances between them.

3.参考如下资料:
    ingress的用法与原理: https://www.cnblogs.com/shuiguizi/p/12832450.html
    kubernetes部署traefik: https://blog.csdn.net/networken/article/details/85953346
