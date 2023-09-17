# docker-jmeter


## 构建镜像

* 构建 master 镜像

```bash
$ cd master
$ bash ./build.sh
```

* 构建 slave 镜像

```bash
$ cd slave
$ bash ./build.sh
```

* 查看镜像

```bash
$ docker images

REPOSITORY              TAG      IMAGE ID       CREATED          SIZE
defnngj/jmeter-slave    5.6.2    ef45d822c218   5 minutes ago   680MB
defnngj/jmeter-master   5.6.2    f59c1e88d83b   5 minutes ago   680MB
```

* `f59c1e88d83b` master 镜像ID, 后面要用。

## 运行

* 启动 slave 节点。

假设有两台主机，可以启动两个slave。

```bash
$ docker run -it -d --name jmeter-slave01 defnngj/jmeter-slave:5.6.2
$ docker run -it -d --name jmeter-slave02 defnngj/jmeter-slave:5.6.2
```

* 查看启动的容器

```bash
$ docker ps

CONTAINER ID   IMAGE                      COMMAND                   CREATED         STATUS         PORTS                 NAMES
57b70df37adb   defnngj/jmeter-slave:5.6.2   "/bin/sh -c 'jmeter-…"   7 minutes ago   Up 7 minutes   1099/tcp, 60001/tcp   slave_b
2c4c3e6b9b26   defnngj/jmeter-slave:5.6.2   "/bin/sh -c 'jmeter-…"   7 minutes ago   Up 7 minutes   1099/tcp, 60001/tcp   slave_a
```

* 查看两个slave 的IP 地址

```bash
$ docker inspect -f '{{ .Name }} => {{ .NetworkSettings.IPAddress }}' $(docker ps -q)

/jmeter-slave02 => 172.17.0.3
/jmeter-slave01 => 172.17.0.2
```

* 发送压测脚本到 slave

```bash
$ result=`date +"%Y%m%d%H%M%S"` && sudo docker run --rm -v ./script:/data defnngj/jmeter-master:5.6.2 jmeter -n -t /data/baidu_script.jmx -l /data/reports/$result.jtl -j /data/reports/$result.log -e -o /data/reports/$result -R 172.17.0.2,172.17.0.3
```

__参数说明__

* `result=`date +"%Y%m%d%H%M%S"`: 指定测试结果的名称，以当前日期时间命名。

* `./script` : 压测脚本的目录，测试结果也会存放到该目录下。

* `baidu_script.jmx` : 压测脚本的名称，存放于 `script/`目录下。 参考[script/](/script/)) 目录下。

* `defnngj/jmeter-master:5.6.2` : jmeter-master 的镜像名称，使用`f59c1e88d83b` 镜像ID 也可以。

* `172.17.0.2,172.17.0.3` ： 两台 slave 的IP 地址。


### 测试结果

* 执行完的目录

```bash
$ pwd
.../github/docker-jmeter/script/reports

$ ll
drwxr-xr-x  6 fnngj  staff   192B  9 17 11:41 20230917114115
-rw-r--r--  1 fnngj  staff    22K  9 17 11:41 20230917114115.jtl
-rw-r--r--  1 fnngj  staff    19K  9 17 11:41 20230917114115.log
```

* 查看报告

进入`20230917114115` 目录，点击 index.html 文件，可以看到压测的结果。

![](./report.png)

## docker compose 运行

通过 docker compose 编排JMeter的运行更加简单。

* 修改名称

```bash  
$ cat .env

RESULT=result01
```

* 运行 docker compose

```bash
$ docker-compose up -d    
[+] Building 0.0s (0/0)                                                                                                                                                                  
[+] Running 3/3
 ✔ Container jmeter-master   Started    0.4s 
 ✔ Container jmeter-slave02  Running    0.0s 
 ✔ Container jmeter-slave01  Running    0.0s 
```

* 查看结果

```
$ pwd
.../github/docker-jmeter/script/reports

$ ll
drwxr-xr-x  6 fnngj  staff   192B  9 17 18:18 result01
-rw-r--r--  1 fnngj  staff    11K  9 17 18:18 result01.jtl
-rw-r--r--  1 fnngj  staff    20K  9 17 18:18 result01.log
```

## 感谢

本项目参考一下文章和项目，表示感谢！

https://developer.aliyun.com/article/769520

https://github.com/justb4/docker-jmeter

https://github.com/apolloclark/jmeter

