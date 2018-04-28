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

#### 指定日志category、loglevel、SignalType

不同的log Operator可以配置不同的日志category、loglevel，实现日志输出的pattern和appender的灵活配置。

同时还可以指定SignalType，仅仅记录想关注的信号类型。如下：

```java
public class LogOperator {
    public static void main(String[] args) {
        Flux.just(1, 2, 3, 4, 5)
                //日志记录详细的执行步骤
                .log()
                .subscribe();

        Flux.just(1, 2, 3, 4, 5)
                //使用自定义日志配置
                .log("myCategory")
                .subscribe();

        Flux.just(1, 2, 3, 4, 5)
                //使用自定义日志配置，仅仅关注onComplete信号
                .log("myCategory", Level.WARNING, SignalType.ON_COMPLETE)
                .subscribe();
    }
}
```

修改log4j2.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration status="OFF">
    <appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="%d{HH:mm:ss} [%t] %-5level %logger{36} - %msg%n"/>
        </Console>

        <Console name="Console2" target="SYSTEM_OUT">
            <PatternLayout pattern="[%d{yy-MMM-dd HH:mm:ss:SSS}] [%p] [%c{1}:%L] - %m%n"/>
        </Console>

    </appenders>


    <Loggers>
        <Root level="info">
            <AppenderRef ref="Console"/>
        </Root>
        <!-- name必须和log方法中category相同 -->
        <logger level="info" name="myCategory">
            <AppenderRef ref="Console2"/>
        </logger>
    </Loggers>
</configuration>
```

### 输出如下：不同颜色框对应了不同的日志配置的输出。![](/assets/log-category-level.png)

### elapsed

elapsed Operator将Flux&lt;T&gt;转为Flux&lt;Tuple2&lt;Long, T&gt;&gt;，Tuple2类似于Pair对象，将获取数据的耗时和数据本身保存在一个对象中。

耗时单位是毫秒。例子如下：

```java
 public class ElapsedOperator {

    public static void main(String[] args) {
        Flux<Integer> sourceFlux = Flux.range(0, 5)
                .map(integer -> {
                    try {
                        //随机休眠一段时间再返回，增加耗时
                        Thread.sleep((long) (Math.random() * 1000));
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    return integer;
                });
        /**
         * elapsed之后返回Flux<Tuple2<Long, Integer>>，Tuple2.getT1()返回
         * 耗时，Tuple2.getT2()返回数据值
         * 如果使用log，则会打印出信号、耗时和数据值
         */

        Flux<Tuple2<Long, Integer>> timedFlux = sourceFlux.elapsed();
        timedFlux.log().subscribe();
    }
}

```

输出如下:

![](/assets/ElapsedOperator.png)

可以看到第一个数据耗时900毫秒，第二个数据耗时291毫秒，等等。

### timestamp

和elapsed方法类似，只不过不是返回耗时，而是返回当前时钟时间（current clock time），即数据返回时的System.currentTimeMillis\(\)值。

例子如下：

```java
public class TimestampOperator {
    private static final Logger LOGGER = LoggerFactory.getLogger(TimestampOperator.class);

    public static void main(String[] args) {
        Flux<Integer> sourceFlux = Flux.range(0, 5)
                .map(integer -> {
                    try {
                        //随机休眠一段时间再返回，增加耗时
                        Thread.sleep((long) (Math.random() * 1000));
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    return integer;
                });

        /**
         * elapsed之后返回Flux<Tuple2<Long, Integer>>，Tuple2.getT1()返回
         * 耗时，Tuple2.getT2()返回数据值
         * 如果使用log，则会打印出信号、当前时钟时间和数据值
         */
        Flux<Tuple2<Long, Integer>> timedFlux = sourceFlux.timestamp();
        LOGGER.info("current clock time is {} ", System.currentTimeMillis());
        timedFlux.log().subscribe();
    }
}
```

输出如下:

![](/assets/TimestampOperator.png)

完整代码：https://github.com/pkpk1234/learn-reactor

