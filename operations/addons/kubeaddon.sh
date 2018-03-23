#!/usr/bin/env bash

#set -x
#如果任何语句的执行结果不是true则应该退出,set -o errexit和set -e作用相同
# set -e

#id -u显示用户ID,root用户的ID为0
root=$(id -u)
#脚本需要使用root用户执行
if [ "$root" -ne 0 ] ;then
    echo "must run as root"
    exit 1
fi

#
#系统判定
#
linux_os()
{
    cnt=$(cat /etc/centos-release|grep "CentOS"|grep "release 7"|wc -l)
    if [ "$cnt" != "1" ];then
       echo "Only support CentOS 7...  exit"
       exit 1
    fi
}


install_dashboard()
{
    echo "install dashboard"

}

uninstall_dashboard()
{
    echo "uninstall dashboard"
}

install_efk()
{
    echo "install efk"
    kubectl apply -f efk/fluentd-es-configmap.yaml  
    kubectl apply -f efk/fluentd-es-ds.yaml 
    kubectl apply -f efk/es-statefulset.yaml
    kubectl apply -f efk/es-service.yaml 
    kubectl apply -f efk/kibana-deployment.yaml 
    kubectl apply -f efk/kibana-service.yaml 
    
    echo "EFK installation is complete,Follow-up:"
    echo "kubectl label node [node-name] beta.kubernetes.io/fluentd-ds-ready=true"
}

uninstall_efk()
{
    echo "uninstall efk"
    kubectl delete -f efk/kibana-service.yaml 
    kubectl delete -f efk/kibana-deployment.yaml 
    kubectl delete -f efk/es-service.yaml 
    kubectl delete -f efk/es-statefulset.yaml
    kubectl delete -f efk/fluentd-es-ds.yaml 
    kubectl delete -f efk/fluentd-es-configmap.yaml  
    
    echo "EFK uninstallation is complete"
}

kube_help()
{
    echo "usage: $0 i|d --dashboard --efk"
    echo "       unkown command $0 $@"
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
            # install
            i|install)
                export TYPE="install"
            ;;
            # delete
            d|delete)
                export TYPE="delete"
            ;;
            #dashboard
            --dashboard)
                export ADDON_DASHBOARD="yes"
                export IS_HAVE_INSTALL="yes"
            ;;
            #efk
            --efk)
                export ADDON_EFK="yes"
                export IS_HAVE_INSTALL="yes"
            ;;
            
            #获取kubeadm的token
            -h|--help)
                kube_help
                exit 1
            ;;
            *)
                # unknown option
                echo "unkonw option [$key]"
            ;;
        esac
        shift
    done

    if [ ! -n "$TYPE" ]; then
        echo "please type the type  i | d"
        exit 1
    fi

    if [ ! -n "$IS_HAVE_INSTALL" ]; then
        echo 'at least one addon is required'
        exit 1
    fi

    if [ -n "$ADDON_DASHBOARD" ]; then
        if [ "$TYPE" = "install" ]; then
            install_dashboard
        else
            uninstall_dashbaord
        fi
    fi

    if [ -n "$ADDON_EFK" ]; then
        if [ "$TYPE" = "install" ]; then
            install_efk
        else
            uninstall_efk
        fi
    fi
}

main $@
