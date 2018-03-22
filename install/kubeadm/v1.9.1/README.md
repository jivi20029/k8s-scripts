1~2台centos7.x or rhel7.x 虚机
(最好7.4及以上,7.4以下的需要将内核升级成kernel-3.10.0-693.el7.x86_64,否则modprobe br_netfilter 执行失败)

| 虚机名称        | IP              |
| -------------  |:---------------:|
| master         | 192.168.136.130 |
| node01         | 192.168.136.131 |



修改主机名
```bash
hostnamectl --static set-hostname  master
hostnamectl --static set-hostname  node01
```

下载kubeadm.sh脚本，设置脚本有可执行权限
```bash
chmod a+x kubeadm.sh
```

在主节点执行下面的命令：
```bash
sh kubeadm.sh --node-type master --master-address 192.168.136.130
```

在从节点执行下面的命令：
```bash
sh kubeadm.sh --node-type node --master-address 192.168.136.130
```

安装重置：
```bash
sh kubeadm.sh reset
```
安装重置默认会备份/etc/kubernetes和/var/lib/etcd，如果你不想备份请使用
```bash
sh kubeadm.sh reset --backup no
```

备份/etc/kubernetes和/var/lib/etcd：
```bash
sh kubeadm.sh backup
```

如果机器重启之后，集群启动失败，kubelet启动报错，可使用
```bash
cat /var/log/messages
```
命令查看是否是因为swap没有关闭，造成启动失败。如果是因为swap没有关闭，可注释/etc/fstab中和swap相关的配置，再重启主机，集群可正常启动。


master节点装完后,默认是无法将POD放置在其上的，如果你只想找一台机子进行测试。
可以执行命令 开启某个MASTER
```bash
kubectl taint nodes master(节点名) node-role.kubernetes.io/master-
```
或者 全部
```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```
这样就可以将POD放在MASTER节点上了                
