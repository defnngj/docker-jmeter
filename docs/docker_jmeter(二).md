## 利用 docker 实现JMeter分布式压测（二）

### 前言

上一篇偷懒，只用使用的别人的 images 镜像去实现 JMeter分布式压测。接下来，我尝试自己手写 Dockerfile。

1. 上节使用的 images 镜像是三年前的，内置 JMeter 5.1.1，版本有点旧了。
2. 当然是为了进一步了解 Dockerfile 的编写。

### 寻找基础镜像

寻找基础镜像花了老半天时间，首先，如果是 Linux 镜像，可以是 ubuntu/centos/alpine 等。太麻烦了，还需要在 里面下载安装 JDK 配置 Java 环境变量。

直接使用 JDK 简单一些，相当于在一个 包含 Java 环境的 Linux 里面 构建，oracle JDK、openjdk 二选一，当然为了不必要的麻烦，openjdk 更保险。

openJDK: https://hub.docker.com/_/openjdk

最后是 JDK 版本, JMeter 要求 Java 8 就行。

> JMeter is compatible with Java 8 or higher. We highly advise you to install latest minor version of your major version for security and performance reasons.

我一开始用的 Java 11 ，构建的 镜像 800MB ，实在是有点大，后来换回 Java 8 也要 600MB +。


__目录结构__

```bash
$ tree
.
├── README.md
├── master
│   ├── Dockerfile
│   └── build.sh
└── slave
    ├── Dockerfile
    └── build.sh
```

### 编写 Dockerfile 

由于我们要制作的是JMeter分布式镜像，所以，需要两个 Dockerfile.

#### 创建`/master/Dockerfile` 文件

```dockerfile
# openjdk 8
FROM openjdk:8

# 更新版本1
MAINTAINER defnngj<defnngj@gmail.com>

ARG JMETER_VERSION="5.5"
ENV JMETER_HOME /opt/apache-jmeter-$JMETER_VERSION
ENV JMETER_DOWNLOAD_URL  https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz
ENV SSL_DISABLED true

RUN mkdir -p /tmp/dependencies  \
    && curl -L --silent $JMETER_DOWNLOAD_URL >  /tmp/dependencies/apache-jmeter-$JMETER_VERSION.tgz  \
    && mkdir -p /opt  \
    && tar -xzf /tmp/dependencies/apache-jmeter-$JMETER_VERSION.tgz -C /opt  \
    && rm -rf /tmp/dependencies

# TODO: plugins (later)
# && unzip -oq "/tmp/dependencies/JMeterPlugins-*.zip" -d $JMETER_HOME

# Set global PATH such that "jmeter" command is found
ENV PATH $PATH:$JMETER_HOME/bin

VOLUME ["/data"]

WORKDIR  $JMETER_HOME

RUN sed 's/#server.rmi.ssl.disable=false/server.rmi.ssl.disable=true/g' ./bin/jmeter.properties > ./bin/jmeter_temp.properties
RUN mv ./bin/jmeter_temp.properties ./bin/jmeter.properties
```

为啥不用 JMeter 5.6 ？

>  这里严重吐槽一下，5.6 编写的脚本在非 GUI 模式下运行无法停止。 前两周刚因为这个问题加班到很晚，可把我坑惨了，已经有阴影了。虽然出了 5.6.2 修复版本，我选择暂时不用他。

上述脚本就是 下载 JMeter 5.5 版本，解压到相应目录，然后配置 JMETER_HOME环境变量。


#### 创建`/slave/Dockerfile` 文件

```dockerfile
# openjdk 8
FROM openjdk:8

# 更新版本1
MAINTAINER defnngj<defnngj@gmail.com>

ARG JMETER_VERSION="5.5"
ENV JMETER_HOME /opt/apache-jmeter-$JMETER_VERSION
ENV JMETER_DOWNLOAD_URL  https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz
ENV SSL_DISABLED true

RUN mkdir -p /tmp/dependencies  \
    && curl -L --silent $JMETER_DOWNLOAD_URL >  /tmp/dependencies/apache-jmeter-$JMETER_VERSION.tgz  \
    && mkdir -p /opt  \
    && tar -xzf /tmp/dependencies/apache-jmeter-$JMETER_VERSION.tgz -C /opt  \
    && rm -rf /tmp/dependencies

# TODO: plugins (later)
# && unzip -oq "/tmp/dependencies/JMeterPlugins-*.zip" -d $JMETER_HOME

# Set global PATH such that "jmeter" command is found
ENV PATH $PATH:$JMETER_HOME/bin

VOLUME ["/data"]

WORKDIR $JMETER_HOME

EXPOSE 1099 60001

ENTRYPOINT jmeter-server -Dserver.rmi.localport=60001 -Dserver_port=1099 \
            -Jserver.rmi.ssl.disable=$SSL_DISABLED
```

需要注意：

* `1099` 相当于容器暴露的端口。我们通过访问 宿主机的 1099，即可访问到容器。



### 编写构建脚本

其实，有 Dockerfile 文件就可以用 `docker build` 进行构建了。为了简化操作，我们可以进一步创建 `build.sh` 来实现构建脚本。


#### 创建`/master/build.sh` 文件

```bash
JMETER_VERSION=${JMETER_VERSION:-"5.5"}

# Example build line
docker build  --build-arg JMETER_VERSION=${JMETER_VERSION} -t "defnngj/jmeter-master:${JMETER_VERSION}" .

```

`--build-arg` 设置构建时变量

`-t`  设置镜像名 + TAG。


* 构建 master 镜像

```bash
$ bash ./build.sh

[+] Building 340.5s (9/9) FINISHED                                                                                                                           
...
 => => naming to docker.io/defnngj/jmeter-master:5.5
```

#### 创建`/slave/build.sh` 文件

```bash

JMETER_VERSION=${JMETER_VERSION:-"5.5"}

# Example build line
docker build  --build-arg JMETER_VERSION=${JMETER_VERSION} -t "defnngj/jmeter-slave:${JMETER_VERSION}" .

```

`--build-arg` 设置构建时变量

`-t`  设置镜像名 + TAG。

* 构建 slave 镜像

```bash
$ bash ./build.sh

[+] Building 1.4s (7/7) FINISHED                                                                                                                               
...
 => => naming to docker.io/defnngj/jmeter-slave:5.5 
```

### 查看镜像


```bash
$ docker images

REPOSITORY              TAG    IMAGE ID       CREATED          SIZE
defnngj/jmeter-slave    5.5    9e5c9141fcc4   19 minutes ago   672MB
defnngj/jmeter-master   5.5    c4a2eab57be7   19 minutes ago   673MB
```

### 最后

我已将项目开源（包含文档）：

https://github.com/defnngj/docker-jmeter


参考项目：

https://github.com/justb4/docker-jmeter

