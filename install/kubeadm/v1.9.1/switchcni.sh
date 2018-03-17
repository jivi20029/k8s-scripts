#!/usr/bin/env bash

#set -x
#如果任何语句的执行结果不是true则应该退出,set -o errexit和set -e作用相同
set -e

#id -u显示用户ID,root用户的ID为0
root=$(id -u)
#脚本需要使用root用户执行
if [ "$root" -ne 0 ] ;then
    echo "must run as root"
    exit 1
fi

export FLANNEL_VERSION="v0.9.1"
export CALICO_VERSION="v3.0"

cnis=("calico" "flannel")

scni_help()
{
    echo "usage: $0 --source flannel --target calico"
    echo "       unkown command $0 $@"
}

download_flannel_yml(){
	if [ -f "$HOME/kube-flannel.yml" ]; then
        rm -rf $HOME/kube-flannel.yml
    fi
    wget -P $HOME/ https://raw.githubusercontent.com/coreos/flannel/${FLANNEL_VERSION}/Documentation/kube-flannel.yml
    sed -i 's/quay.io\/coreos\/flannel/registry.cn-hangzhou.aliyuncs.com\/qiaowei\/flannel/g' $HOME/kube-flannel.yml
}

install_flannel(){
	echo "begin install flannel"
	download_flannel_yml
    kubectl --namespace kube-system apply -f $HOME/kube-flannel.yml
    echo "Flannel installed successfully!"
}

uninstall_flannel(){
	echo "begin uninstall flannel"
	download_flannel_yml
    kubectl delete -f $HOME/kube-flannel.yml
    ip link delete flannel.1
    echo "Flannel installed successfully!"
}

download_calico_yml(){
	if [ -f "$HOME/calico.yaml" ]; then
        rm -rf $HOME/calico.yaml
    fi
    wget -P $HOME/ https://docs.projectcalico.org/${CALICO_VERSION}/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
 	sed -i 's/quay.io\/coreos\/etcd:v3.1.10/registry.cn-hangzhou.aliyuncs.com\/qiaowei\/etcd-amd64:3.1.10/g' $HOME/calico.yaml
    sed -i 's/quay.io\/calico\//registry.cn-hangzhou.aliyuncs.com\/qiaowei\/calico-/g' $HOME/calico.yaml
}

install_calico(){
	echo "begin install calico"
	download_calico_yml
    kubectl --namespace kube-system apply -f $HOME/calico.yaml   
    echo "Calico installed successfully!"
}

uninstall_calico(){
	echo "begin uninstall calico"
	download_calico_yml
	kubectl delete -f $HOME/calico.yaml
}

switch(){
	# echo ${cnis[@]}
	if [[ "${cnis[@]}" =~ "$CNI_SOURCE" ]];then 
		echo "the cni:"$CNI_SOURCE" is supported"
	else
		echo "the cni:"$CNI_SOURCE" is not supported"
		exit 1
	fi
	if [[ "${cnis[@]}" =~ "$CNI_TARGET" ]];then 
		echo "the cni type:"$CNI_TARGET" is supported"
	else
		# echo "目录网络类型"$CNI_TARGET"不支持"
		echo "the cni:"$CNI_TARGET" is not supported"
		exit 1
	fi

	if [ $CNI_SOURCE = "flannel" ]; then 
		uninstall_flannel
	fi
	if [ $CNI_SOURCE = "calico" ]; then 
		uninstall_calico
	fi
	if [ $CNI_TARGET = "flannel" ]; then 
		install_flannel
	fi
	if [ $CNI_TARGET = "calico" ]; then 
		install_calico
	fi
}

main()
{
    # 系统检测暂时取消，使得CENTOS和REDHAT都能使用   
    # linux_os
    #$# 查看这个程式的参数个数
    while [[ $# -gt 0 ]]
    do
        #获取第一个参数
        key="$1"

        case $key in
            #目前的网络 
            --source)
                export CNI_SOURCE=$2
                #向左移动位置一个参数位置
                shift
            ;;
            #要改变的网络
            --target)
                export CNI_TARGET=$2
                #向左移动位置一个参数位置
                shift
            ;;
             #获取kubeadm的token
            -h|--help)
                scni_help
                exit 1
            ;;
            *)
                # unknown option
                echo "unkonw option [$key]"
            ;;
        esac
        shift
    done

    # echo $CNI
    # if [ $CNI = "flannel" ]; then
    #     echo "abc"
    # fi

    if [ "" == "$CNI_SOURCE" -o "" == "$CNI_TARGET" ];then
        if [ "$NODE_TYPE" != "down" ];then
            echo "--source and --target must be provided!"
            exit 1
        fi
    fi

    switch
}

main $@