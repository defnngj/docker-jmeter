# openjdk 1.8
FROM openjdk:8-jdk-alpine3.9

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

WORKDIR    $JMETER_HOME

EXPOSE 1099 60001

ENTRYPOINT jmeter-server -Dserver.rmi.localport=60001 -Dserver_port=1099 \
            -Jserver.rmi.ssl.disable=$SSL_DISABLED