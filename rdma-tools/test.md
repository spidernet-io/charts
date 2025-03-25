# 测试 

## RDMA 测试流程 

1. 运行 testArping ， 确认 是否有 IP 冲突或者 arp 代理 ，确认 arp 延时响应是否高 ，是否有丢包。以确认 arp 问题，确认 物理链路问题（可能光纤有问题）

    把命令输出定向到文件，留档测试报告

2. 运行 testPing， 确认延时和丢包，确认三层连通性

    把命令输出定向到文件，留档测试报告

3. 使用 testRdmaPairBw ，两两主机之间进行 同轨 RDMA 打流，验证如下：
   一方面，确认 rdma 跑到多少吞吐
   一方面，确认 qos 生效
   一方面，查看 grafana 面板， 确认 workload 中网卡是否有乱序； 确认所属 node 的 pf 上是否有 qos buffer 丢包，是否有 pfc pause 帧

  （1） ASYNCHRONOUS=false,  SAME_NETWORK_TRACK=true, DURATION=180
    把命令输出定向到文件，留档测试报告

  （2）BW_CMD_CLI="ib_read_bw" , ASYNCHRONOUS=false,  SAME_NETWORK_TRACK=true, DURATION=180
     做 read 反向打流，确保光模块的收发双向都是没问题的
    把命令输出定向到文件，留档测试报告

4. 测试 testRdmaPairBw 跨轨打流，以测试 spine 和 leaf 交换机的 负载均衡 性能 

   （1） 只使用 两个主机测试 testRdmaPairBw 跨轨（为了避免多组主机测试时的 spine 和 leaf 的链路冲突），这样能够验证 spine 和 leaf 每个光纤链路的 发送 健康
        ASYNCHRONOUS=false,  SAME_NETWORK_TRACK=false, DURATION=180

   （2） 只使用 两个主机测试 testRdmaPairBw 跨轨 ， BW_CMD_CLI="ib_read_bw"，这样能够验证 spine 和 leaf 每个光纤链路的 接收 健康
        BW_CMD_CLI="ib_read_bw" ASYNCHRONOUS=false,  SAME_NETWORK_TRACK=false, DURATION=180

  （3）全部主机一起，做 testRdmaPairBw 跨轨 ， 确认 spine 和 leaf 在拥塞过程中的 表现
        ASYNCHRONOUS=false,  SAME_NETWORK_TRACK=false, DURATION=180

5. 使用 testRdmaPairLatency 测试 同轨 和 跨轨 延时 
    
    (1) 使用 testRdmaPairLatency ,  测试 所有主机的 同轨 延时 
        ASYNCHRONOUS=false,  SAME_NETWORK_TRACK=false, DURATION=20

    (2) 使用 testRdmaPairLatency ,  只测试 两台主机的 跨轨 延时，  覆盖测试 spine 和 leaf 的所有链路 
        ASYNCHRONOUS=false,  SAME_NETWORK_TRACK=true, DURATION=20

6. 测试 GDR 性能: 开启 GDR 下，做 testRdmaPairBw 的同轨测试， 

    （1） ASYNCHRONOUS=true,  SAME_NETWORK_TRACK=true, DURATION=180

    （2） BW_CMD_CLI="ib_read_bw"， ASYNCHRONOUS=true,  SAME_NETWORK_TRACK=true, DURATION=180
