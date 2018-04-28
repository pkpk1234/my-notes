# Project Reactor学习--调试类Operator

上一篇文件中介绍了Reactor中Operator的分类，现在开始介绍其中最简单的调试类Operator。

调试类Operator一般用于开发人员观察Publisher接收到信号的步骤、运行时间等调试类信息。

### log

log Operator输出Publisher接收到信号的每一步的信息。

下面是最简单的例子。

```java
public class LogOperator {
    public static void main(String[] args) {
        Flux.just(1, 2, 3, 4, 5)
                //日志记录详细的执行步骤
                .log()
                .subscribe();
    }
}
```

运行结果如下：可以看到Publisher收到onSubscribe信号，然后接收到request\(unbounded\)信号，然后是若干的onNext信号，最后是一个onComplete信号。

![](/assets/logConsole.png)

log默认使用的是java.util.logging框架，但是同时也支持slf4j门面的日志框架。

### 使用日志框架

log支持使用slf4j门面的日志框架，如果classpath中存在此类日志框架，则优先使用。下面使用slf4j和log4j2为例：

首先添加依赖：

```xml
<!-- sl4j-log4j2-all-deps -->
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-slf4j-impl</artifactId>
    <version>2.9.0</version>
</dependency>
```

log4j-slf4j-impl会包含其他所有需要的间接依赖：

```
+- org.apache.logging.log4j:log4j-slf4j-impl:jar:2.9.0:compile
|  +- org.slf4j:slf4j-api:jar:1.7.25:compile
|  +- org.apache.logging.log4j:log4j-api:jar:2.9.0:compile
|  \- org.apache.logging.log4j:log4j-core:jar:2.9.0:runtime
```

然后添加log4j2.xml配置文件，注意：log Operator默认的日志级别是info。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration status="OFF">
    <appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="%d{HH:mm:ss} [%t] %-5level %logger{36} - %msg%n"/>
        </Console>
    </appenders>
    <Loggers>
        <Root level="info">
            <AppenderRef ref="Console"/>
        </Root>
    </Loggers>
</configuration>
```

输出如下：

![](/assets/log-log4j2.png)



