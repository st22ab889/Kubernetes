

当 helm 的 release 更新时，有可能 hook 资源已经存在于群集中。默认情况下，helm 会尝试创建资
源，并抛出错误"... already exists"。

我们可以选择 "helm.sh/hook-delete-policy": "before-hook-creation"，取代 "helm.sh/hook-deletepolicy": "hook-succeeded,hook-failed" 因为：
例如为了⼿动调试，将错误的 hook 作业资源保存在 kubernetes 中是很⽅便的。 出于某种原因，可能
有必要将成功的 hook 资源保留在 kubernetes 中。同时，在 helm release 升级之前进⾏⼿动资源删除
是不可取的。 "helm.sh/hook-delete-policy": "before-hook-creation" 在 hook 中的注释，如果在新的
hook 启动前有⼀个 hook 的话，会使 Tiller 将以前的release 中的 hook 删除，⽽这个 hook 同时它可
能正在被其他⼀个策略使⽤。



