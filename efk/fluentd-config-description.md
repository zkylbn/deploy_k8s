# 参数解释
 
kind: ConfigMap
apiVersion: v1
metadata:
  name: fluentd-config            
  namespace: elk                    #flunentd所属命名空间
data:
  system.conf: |-
    <system>
      root_dir /tmp/fluentd-buffers/      #系统日志信息
    </system>
  containers.input.conf: |-              #容器输入日志配置信息
 
 
#日志源配置
    <source>
      @id fluentd-containers.log         #表示引用该日志源的唯一标志符
      @type tail                         #Fluentd内置命令，tail表示Fluentd从上次读取的位置通过tail不断获取数据
      path /var/log/containers/*.log     #日志路径 (docker stdout默认输出路径，如果修改docker引擎配置这里也需要修改)
      pos_file /var/log/es-containers.log.pos  #检查点，将从文件中获取上一次检查数据的时间
      time_format %Y-%m-%dT%H:%M:%S.%NZ   #时间格式
      localtime
      tag raw.kubernetes.*               #用来将日志源与目标或者过滤器匹配的自定义字符串，Fluentd匹配源/目标标签
      format json                        #JSON解析器
      read_from_head true    
    </source>
 
 
路由配置
   
     <match **>             #标示一个目标，后面是一个匹配日志源的正则表达式，获取所有日志*.*并且全部发送给ES
      @id elasticsearch      #ID唯一标示符
      @type elasticsearch    #支持的输出插件标示符 (本选项为内置命令，除了输出到es，还可以输出到kafka、logstash等)
      @log_level info        #日志级别
      include_tag_key true    
      host elasticsearch    #es地址 (由于我们es为无头服务，地址就是elasticsearch)
      port 9200             #es端口
      logstash_format true    # es服务队日志数据构建反索引进行搜索，设置为true，fluentd将会以logstash格式来转发构建的日志数据
      request_timeout    30s   #超时时间
 
       <buffer>               #缓存配置，fluentd允许在目录不可用时进行缓存
        @type file
        path /var/log/fluentd-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
       </buffer>
    </match>
