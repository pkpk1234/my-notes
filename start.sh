#!/bin/bash
ulimit -s 20280
ulimit -c unlimited
ulimit -n 20480
 
cd `dirname $0`
BIN_DIR=`pwd`
DEPLOY_DIR=`pwd`
 
APPLICATION_NAME="id-generator-service"
RUN_ENVIRONMENT="production"
EXECUTOR_JAR=${DEPLOY_DIR}/"distributed-id-server-1.0.0.jar"
SERVER_PORT="20802"
LOGS_FILE="/log/app/${APPLICATION_NAME}.log"
JMX_PORT="7199"
NODE_NAME=""
 
if [ -z "$NODE_NAME" ]; then
    NODE_NAME=`hostname`
fi
 
PIDS=`ps -ef | grep java | grep -v grep | grep "DEPLOY_DIR" |awk '{print $2}'`
if [ -n "$PIDS" ]; then
    echo "ERROR: The $APPLICATION_NAME already started!"
    echo "PID: $PIDS"
    exit 1
fi
 
if [ -n "JMX_PORT" ]; then
    SERVER_PORT_COUNT=`netstat -tln | grep ${JMX_PORT} | wc -l`
    if [ ${SERVER_PORT_COUNT} -gt 0 ]; then
        echo "ERROR: The $APPLICATION_NAME jmx port $JMX_PORT already used!"
        exit 1
    fi
fi
 
LOGS_DIR=""
if [ -n "$LOGS_FILE" ]; then
    LOGS_DIR=`dirname ${LOGS_FILE}`
else
    LOGS_DIR=${DEPLOY_DIR}/logs
fi
if [ ! -d ${LOGS_DIR} ]; then
    mkdir -p ${LOGS_DIR}
fi
STDOUT_FILE=${LOGS_DIR}/stdout.log
 
LIB_DIR=${DEPLOY_DIR}/lib
LIB_JARS=""
 
if [ -d ${LIB_DIR} ]; then
    LIB_JARS=`ls ${LIB_DIR}|grep .jar|awk '{print "'${LIB_DIR}'/"$0}'|tr "\n" ":"`
fi
 
PERM_SIZE="256m"
MAX_PERM_SIZE="512m"
 
if [[ "$RUN_ENVIRONMENT" = "dev" ]]; then
    ENVIRONMENT_MEM="-Xms512m -Xmx512m -Xss256K"
    PERM_SIZE="128m"
    MAX_PERM_SIZE="256m"
else
    ENVIRONMENT_MEM="-Xms4096m -Xmx4096m"
fi
 
PINPOINT_DIR="/opt/app/pinpoint-agent"
PINPOINT_OPTS=""
if [ -d "${PINPOINT_DIR}" ]; then
    PINPOINT_OPTS=" -javaagent:${PINPOINT_DIR}/pinpoint-bootstrap-1.6.2.jar -Dpinpoint.agentId=${NODE_NAME} -Dpinpoint.applicationName=${APPLICATION_NAME}"
else
    echo -e "Can not find pinpoint jar !!!"
fi
JMX_OPTS=" -Dcom.sun.management.jmxremote.port=${JMX_PORT} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dsun.rmi.transport.tcp.threadKeepAliveTime=75000"
 
 
JAVA_OPTS="-XX:+PrintCommandLineFlags -XX:-OmitStackTraceInFastThrow -XX:-UseBiasedLocking -XX:AutoBoxCacheMax=20000"
MEM_OPTS="-server ${ENVIRONMENT_MEM} -XX:+AlwaysPreTouch"
CMS_GC_OPTS="-XX:NewRatio=1 -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:MaxTenuringThreshold=6 -XX:+ParallelRefProcEnabled -XX:+ExplicitGCInvokesConcurrent"
GCLOG_OPTS="-Xloggc:${LOGS_DIR}/gc.log  -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCApplicationConcurrentTime -XX:+PrintGCDateStamps -XX:+PrintGCDetails"
CRASH_OPTS="-XX:ErrorFile=${LOGS_DIR}/hs_err_%p.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${LOGS_DIR}/"
SPRING_OPTS=" -Dlogging.path=${LOGS_DIR}"
 
JAVA_VERSION=`java -fullversion 2>&1 | awk -F[\"\.] '{print $2$3$4}' |awk -F"_" '{print $1}'`
if [[ "$JAVA_VERSION" < "1.8" ]]; then
    MEM_OPTS="$MEM_OPTS -XX:PermSize=${PERM_SIZE} -XX:MaxPermSize=${MAX_PERM_SIZE} -Djava.security.egd=file:/dev/./urandom"
else
    MEM_OPTS="$MEM_OPTS -XX:MetaspaceSize=${PERM_SIZE} -XX:MaxMetaspaceSize=${MAX_PERM_SIZE} "
fi
 
echo -e "Starting the $APPLICATION_NAME ...\c"
nohup java ${JAVA_OPTS} ${MEM_OPTS} ${JMX_OPTS} ${GCLOG_OPTS} ${CRASH_OPTS} ${PINPOINT_OPTS} ${SPRING_OPTS} -classpath ${DEPLOY_DIR}:${LIB_JARS} -jar ${EXECUTOR_JAR} > ${STDOUT_FILE} 2>&1 &
 
CHECK_STATUS()
{
    COUNT=0
    while [ ${COUNT} -lt 1 ]; do
        echo -e ".\c"
        sleep 1
        if [ -n "$SERVER_PORT" ]; then
            COUNT=`netstat -an | grep ${SERVER_PORT} | wc -l`
        else
            COUNT=`ps -ef | grep java | grep -v grep | grep "$DEPLOY_DIR" | awk '{print $2}' | wc -l`
        fi
        if [ ${COUNT} -gt 0 ]; then
            break
        fi
    done
}
 
CHECK_STATUS
 
echo "OK!"
PIDS=`ps -ef | grep java | grep -v grep | grep "$DEPLOY_DIR" | awk '{print $2}'`
echo "PID: $PIDS"
echo "STDOUT: $STDOUT_FILE"
