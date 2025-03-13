# rdma tools

images including kinds of RDMA tools for debugging

## image tag

{cuda version of baseImage}-{commit hash of directory}

## chart tag and release chart

the version of chart is '{x of cudaVersion}-{y of cudaVersion}-{custom}'.

For example of chart version 'v12.5.0', '12.5' represents cuda '12.5.x' in the base image, the last '.0' represents any changes of the chart.

tag the code and the CI will automatically release a chart. the image tag will be **chart version** by default.

```shell
git tag rdma-tools-vXX.YY.ZZ 
git push --tags
```

## deploy

```shell
helm repo add spiderchart https://spidernet-io.github.io/charts
helm repo update spiderchart
helm search repo rdma-tools

# run daemonset on worker1 and worker2 
cat <<EOF > values.yaml
# for china user , it could add these to use a domestic registry
image:
  registry: ghcr.m.daocloud.io
  # the default tag is for cuda and nccl, the image is 3G
  #tag: v1.0.0
  # the light tag does not include nccl and cuda, the image is 160 M
  #tag: light-v1.0.0

# just run daemonset in nodes 'worker1' and 'worker2'
# affinity:
#   nodeAffinity:
#     requiredDuringSchedulingIgnoredDuringExecution:
#       nodeSelectorTerms:
#         - matchExpressions:
#           - key: kubernetes.io/hostname
#             operator: In
#             values:
#               - worker1
#               - worker2

# sriov interfaces
extraAnnotations:
  k8s.v1.cni.cncf.io/networks: |-
      [{"name":"gpu1-sriov","namespace":"spiderpool"},
       {"name":"gpu2-sriov","namespace":"spiderpool"}]

# sriov resource
resources:
  limits:
    spidernet.io/gpu1sriov: 1
    spidernet.io/gpu2sriov: 1
    # nvidia.com/gpu: 1

#hostnetwork: false
#ssh_port: 2022

securityContext:
  # required by gdrcopy test or hostnetwork
  privileged: true
  capabilities:
    add: [ "IPC_LOCK" ]
EOF

# for China user, add `--set image.registry=ghcr.m.daocloud.io`
helm install rdma-tools spiderchart/rdma-tools -n rdma --create-namespace -f ./values.yaml

```

## tools in the image

os: ubuntu22.04

| tools         | version                                  | updated time |
|---------------|------------------------------------------|--------------|
| cuda          | 12.5.1                                   | 2024.7.30    |
| nccl          | 2.22.3                                   | 2024.7.30    |
| nccl-test     | v2.13.10                                 | 2024.7.30    |
| hpc-x         | v2.19                                    | 2024.7.30    |
| gdrcopy       | 1366e20d140c5638fcaa6c72b373ac69f7ab2532 | 2024.7.30    |
| perftest      | 24.04.0-0.41                             | 2024.7.30    |
| Bandwidthtest | v12.5                                    | 2024.7.30    |
| nvbandwidth   | v0.5                                     | 2024.8.14    |
| tcpdump       | 4.99.5                                   | 2025.2.27    |

## 最佳实践

### 常规测试 

1. 运行 testArping ， 确认 是否有 IP 冲突或者 arp 代理 ，确认 arp 延时响应是否高 ，是否有丢包。以确认 arp 问题，确认 物理链路问题（可能光纤有问题）

2. 运行 testPing， 确认延时和丢包，确认三层连通性

3. 使用 testRdmaPairBw ， 两两组件之间进行 同轨 RDMA 打流，
   一方面，确认 rdma 跑到多少吞吐
   一方面，确认 qos 生效
   一方面，查看 grafana 面板， 确认 workload 中网卡是否有乱序 ； 确认所属 node 的 pf 上是否有 qos buffer 丢包，是否有 pfc pause 帧

4. 测试 testRdmaPairBw 跨轨打流，以测试 spine 和 leaf 交换机的 负载均衡 性能 

5. 针对 GDR: 使用 grd 同轨 所有卡并行 打流，确认吞吐正常，本地没有硬件瓶颈

6. 使用 testRdmaPairLatency 测试 同轨 和 跨轨 延时 

### NV 环境测试 

* testNcclTest

* testOsu

