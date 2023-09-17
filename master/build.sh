
JMETER_VERSION=${JMETER_VERSION:-"5.6.2"}

# Example build line
docker build  --build-arg JMETER_VERSION=${JMETER_VERSION} -t "defnngj/jmeter-master:${JMETER_VERSION}" .

