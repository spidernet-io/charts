# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

include ../Makefile.defs
include ./Makefile.defs

PROJECT ?=

.PHONY: all
all: e2e

.PHONY: e2e
e2e:
	# setup global kind
	make init-kind -e KIND_CONFIG_PATH=./yamls/kind.yaml || { echo "error, failed to setup kind " ; exit 1 ; }
	# e2e run
	make e2e_test -e PROJECT=$(PROJECT) || { echo "error, failed to run e2e " ; exit 1 ; }

.PHONY: e2e_test
e2e_test:
	PROJECT_LIST="$(PROJECT)" ; [ -n "$${PROJECT_LIST}" ] || PROJECT_LIST=` ls $(ROOT_DIR)` ; \
	    echo "PROJECT_LIST: $${PROJECT_LIST}" ;\
		FAILED_PROJECT="" ; \
		SUCCEED_PROJECT="" ; \
		for ITEM in $$PROJECT_LIST ; do \
		    [ -d "$(ROOT_DIR)/$${ITEM}/chart" ] || continue ; \
            echo "********************* run e2e for project $${ITEM} ******************"; \
			echo "deploy project $${ITEM}"; \
			make deploy -e PROJECT=$${ITEM} || { echo "error, failed to deploy $${ITEM}" ;FAILED_PROJECT+=" $${ITEM} " ;  ./scripts/clean.sh "$(KIND_KUBECONFIG)" || true ; continue ; } ; \
			./scripts/clean.sh "$(KIND_KUBECONFIG)" || true ; \
			SUCCEED_PROJECT+=" $${ITEM} " ; \
	  	done ; \
  	    echo "============== show final result ====================" ; \
  	    helm list -A  --kubeconfig $(KIND_KUBECONFIG)  ; \
  	    echo "----" ; \
  	    kubectl --kubeconfig $(KIND_KUBECONFIG) get pod -A -o wide || true ; \
  	    echo "============== show projects result  ====================" ; \
  	    echo "succceded prjects: $${SUCCEED_PROJECT} " ; \
  	    if [ -n "$${FAILED_PROJECT}" ] ; then \
  	    		echo "failed project: $${FAILED_PROJECT} " ; \
  	    		exit 1 ; \
  	    else \
  	    		echo "all projects succeed" ; \
  	    fi ; \
	  	exit 0

.PHONY: init-kind
init-kind: KIND_CONFIG_PATH ?=
init-kind: checkBin clean
	-@ kind delete cluster --name $(KIND_CLUSTER_NAME) &>/dev/null
	-@ rm -rf $(CLUSTER_DIR)/$(KIND_CLUSTER_NAME)
	- sudo sysctl -w fs.inotify.max_user_watches=524288 || true
	- sudo sysctl -w fs.inotify.max_user_instances=8192 || true
	- sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
	$(QUIET) mkdir -p -v $(CLUSTER_DIR)/$(KIND_CLUSTER_NAME)
	echo "-------------" ; \
		KIND_OPTION="" ; \
       		[ -n "$(E2E_KIND_IMAGE_TAG)" ] && KIND_OPTION=" --image $(E2E_KIND_IMAGE_NAME):$(E2E_KIND_IMAGE_TAG) " && echo "setup kind with $(E2E_KIND_IMAGE_NAME):$(E2E_KIND_IMAGE_TAG)"; \
            kind create cluster --config ./yamls/kind.yaml \
			--name $(KIND_CLUSTER_NAME) --kubeconfig $(KIND_KUBECONFIG) $${KIND_OPTION}
	- kubectl --kubeconfig $(KIND_KUBECONFIG) taint nodes --all node-role.kubernetes.io/master- || true
	- kubectl --kubeconfig $(KIND_KUBECONFIG) taint nodes --all node-role.kubernetes.io/control-plane- || true
	kubectl get node --kubeconfig $(KIND_KUBECONFIG) &>/dev/null || { echo "error, cluster is not ready" ; exit 1 ; }
	echo "show kubernetes node image " && docker ps
	@echo "===================== deploy prometheus CRD ========== "
	{ timeout 10 kubectl apply --kubeconfig $(KIND_KUBECONFIG) -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml ; } \
		|| kubectl apply --kubeconfig $(KIND_KUBECONFIG)  -f ./yamls/monitoring.coreos.com_servicemonitors.yaml
	{ timeout 10 kubectl apply --timeout 10s --kubeconfig $(KIND_KUBECONFIG) -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml ;} \
		|| kubectl apply --kubeconfig $(KIND_KUBECONFIG) -f ./yamls/monitoring.coreos.com_podmonitors.yaml
	{ timeout 10 kubectl apply --timeout 10s --kubeconfig $(KIND_KUBECONFIG) -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml ;} \
		|| kubectl apply --kubeconfig $(KIND_KUBECONFIG) -f ./yamls/monitoring.coreos.com_prometheusrules.yaml
	{ timeout 10 kubectl apply --timeout 10s --kubeconfig $(KIND_KUBECONFIG) -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml  ;} \
		|| kubectl apply --kubeconfig $(KIND_KUBECONFIG) -f ./yamls/monitoring.coreos.com_probes.yaml
	{ timeout 10 kubectl apply --timeout 10s --kubeconfig $(KIND_KUBECONFIG) -f https://raw.githubusercontent.com/grafana-operator/grafana-operator/master/deploy/manifests/latest/crds.yaml  ;} \
		|| kubectl apply --kubeconfig $(KIND_KUBECONFIG) -f ./yamls/grafanadashboards.yaml

.PHONY: deploy
deploy: PROJECT=
deploy: checkBin
	@echo "helm install for $(PROJECT)"
	ALL_IMAGES=` helm template $(PROJECT) $(ROOT_DIR)/$(PROJECT)/chart | grep ' image: ' | tr -d '"' | awk -F 'image: ' '{print $$2}' | sort | uniq | tr '\n' ' ' ` ; \
	echo "ALL_IMAGES: $${ALL_IMAGES} " ; \
	for IMAGE in $${ALL_IMAGES}; do \
		if ! docker images | awk '{printf("%s:%s\n",$$1,$$2)}' | grep -q "$${IMAGE}"; then \
			echo "==> $${IMAGE} not found, pulling...." ; \
			docker pull $${IMAGE} ; \
		fi ; \
		kind load docker-image $${IMAGE} --name $(KIND_CLUSTER_NAME); \
	done ; \
	set -x ; \
    helm upgrade --install $(PROJECT) $(ROOT_DIR)/$(PROJECT)/chart --wait --debug --timeout 10m0s -n $(PROJECT) --create-namespace --kubeconfig $(KIND_KUBECONFIG) ; \
	kubectl --kubeconfig=$(KIND_KUBECONFIG) wait --for=condition=Ready pods --all -n $(PROJECT) --timeout=300s ; \
	if [ $$? -eq 0 ]; then \
		echo "all pods are ready"; \
		exit 0; \
	else \
		echo "timeout or some pods are not ready"; \
		if [ "$(PROJECT)" = "ofed-driver" ]; then \
			if kubectl --kubeconfig=$(KIND_KUBECONFIG) get pods -n $(PROJECT) --field-selector=status.phase=Running ; then \
			   exit 0 ; \
			fi ; \
		fi ; \
		exit 1; \
	fi

.PHONY: checkBin
checkBin:
	@ bash ./scripts/install-tools.sh
	@ echo "all tools ready"

.PHONY: clean
clean: checkBin
	- kind delete cluster --name  $(KIND_CLUSTER_NAME)
	- rm -f $(KIND_KUBECONFIG)
