# 测试 

## RDMA 测试流程 

1. 运行 `testStatus`， 确认网卡状态，确认 qos 生效值，确认 mtu 设置 等基础状态

    把命令输出定向到文件，留档测试报告

2. 运行 `testArping` ， 确认 是否有 IP 冲突或者 arp 代理 ，确认 arp 延时响应是否高 ，是否有丢包。以确认 arp 问题，确认 物理链路问题（可能光纤有问题）

    把命令输出定向到文件，留档测试报告

3. 运行 `testPing` ,  确认延时和丢包，确认三层连通性

    把命令输出定向到文件，留档测试报告

4. 使用 testRdmaPairBw ，两两主机之间进行 同轨 RDMA 打流，验证如下：
   一方面，确认 rdma 跑到多少吞吐
   一方面，确认 qos 生效
   一方面，查看 grafana 面板， 确认 workload 中网卡是否有乱序； 确认所属 node 的 pf 上是否有 qos buffer 丢包，是否有 pfc pause 帧

  （1） `DURATION=60 ASYNCHRONOUS=false SAME_NETWORK_TRACK=true testRdmaPairBw`  , 把命令输出定向到文件，留档测试报告

  （2） `BW_CMD_CLI=ib_read_bw DURATION=60 ASYNCHRONOUS=false SAME_NETWORK_TRACK=true testRdmaPairBw` , 做 read 反向打流，确保光模块的收发双向都是没问题的
    把命令输出定向到文件，留档测试报告

5. 测试 testRdmaPairBw 跨轨打流，以测试 spine 和 leaf 交换机的 负载均衡 性能 , 以及  链路健康状态

   （1） 跨轨打流，write 正向
        `DURATION=60 ASYNCHRONOUS=false SAME_NETWORK_TRACK=false testRdmaPairBw`

   （2） 跨轨打流，read 反向
        `BW_CMD_CLI=ib_read_bw DURATION=60 ASYNCHRONOUS=false SAME_NETWORK_TRACK=false testRdmaPairBw`

6. 使用 testRdmaPairLatency 测试 同轨 和 跨轨 延时 
    
    (1) 使用 testRdmaPairLatency ,  测试 所有主机的 同轨 延时 
        `ASYNCHRONOUS=false SAME_NETWORK_TRACK=false DURATION=15 testRdmaPairLatency`

    (2) 使用 testRdmaPairLatency ,  只测试 两台主机的 跨轨 延时，  覆盖测试 spine 和 leaf 的所有链路 
        `ASYNCHRONOUS=false SAME_NETWORK_TRACK=true DURATION=15 testRdmaPairLatency`

7. 针对 nvidia GPU  , 测试 GDR 性能: 
    测试容器中，需要加载全量的 GPU 和 网卡 ， 在内核开启 GDR 模块情况下，做 testRdmaPairBw 的同轨测试 ( testRdmaPairBw 和 testRdmaPairLatency 需要 适配下，检测网卡和GPU的亲和关系，然后 带上 --use_cuda=序号  的参数 )
