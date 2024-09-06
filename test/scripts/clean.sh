# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

#!/bin/bash

CURRENT_FILENAME=$( basename $0 )
CURRENT_DIR_PATH=$(cd $(dirname $0); pwd)

KIND_KUBECONFIG=$1

[ -f "$KIND_KUBECONFIG" ] || { echo "error, failed to find kubeconfig $KIND_KUBECONFIG " ; exit 1 ; }

echo "KIND_KUBECONFIG: $KIND_KUBECONFIG"

#===============

echo "---------- show pods -----------"
kubectl get pod -A -o wide --kubeconfig ${KIND_KUBECONFIG}

FAILED_POD=` kubectl get pod -A -o wide --kubeconfig ${KIND_KUBECONFIG} | sed '1 d' | grep -v -i -E "Running|completed" | awk '{print $1,$2}' | tr ' ' ',' `
for ITEM in ${FAILED_POD} ; do
    POD_INFO=`echo ${ITEM} | tr ',' ' '`
    echo "------ describe pod $POD_INFO "
    kubectl describe pod -n ${POD_INFO} --kubeconfig ${KIND_KUBECONFIG}
    echo "------ logs pod $POD_INFO "
    kubectl logs -n ${POD_INFO} --kubeconfig ${KIND_KUBECONFIG}
    echo "------ logs pod $POD_INFO "
    kubectl logs -n ${POD_INFO} --kubeconfig ${KIND_KUBECONFIG} -p
done

ALL_HELM=` helm list -A  --kubeconfig ${KIND_KUBECONFIG} | sed '1 d' | awk '{print $2,$1}' | tr ' ' ',' `
for ITEM in ${ALL_HELM} ; do
    HELM_INFO=`echo ${ITEM} | tr ',' ' '`
    echo "---- uninstall ${HELM_INFO}"
    helm uninstall --kubeconfig ${KIND_KUBECONFIG} --debug -n ${HELM_INFO} --timeout 1m
done

exit 0
