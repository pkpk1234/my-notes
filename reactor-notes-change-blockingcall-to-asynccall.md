# Project Reactor学习--如何将阻塞方法包装为非阻塞方法

前面讲了Reactor基础功能如何使用，但是对实际应用没有多大价值，现在来讲一讲如何使用Reactor实现有意义的功能。

Project Reactor作为一个Reactive库，作用就是将阻塞的方法包装为非阻塞的方法，并且为其添加诸如背压等额外的功能。

### 为什么要非阻塞

当方法是阻塞时，调用方法的线程会被阻塞，从而时间浪费在方法等待上。如果线程中还有不依赖于这个阻塞方法调用结果的代码需要执行，那么也需要等待阻塞方法结束之后才能执行，这种情况在微服务架构中很常见。如果是在web容器如果tomcat中，阻塞方法还会阻塞IO线程，导致web容器无法处理新的请求，从而影响性能。

如果方法是非阻塞，则线程可以继续执行其他的操作，当方法执行完成之后，使用某种方式通知调用者。

现在假设有一个网站，用户登录首页，首页需要查询用户基本信息，网站的公告，用户的待处理task。其中查询用户基本信息和网站公告之间是没有任何依赖顺序的，而用户的代办则需要在用户基本信息查询完成之后，依赖于查询出的用户名进行查询（不要纠结于使用用户名查询，而不是用户id查询，举个例子而已）。

假设查询用户信息的方法getUserInfo耗时50ms，查询公告getNotices耗时50ms，查询用户代办getTodos耗时100ms。

那么在阻塞的场景下，时间线应该是这样的：

![](/assets/blocking-method-timeline.png)

使用代码模拟：

```java
public class Caller {
    public static void main(String[] args) {
        blockingCall();
    }

    private static void blockingCall() {
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        System.out.println(EchoMethod.echoAfterTime("get user info", 50, TimeUnit.MILLISECONDS));
        System.out.println(EchoMethod.echoAfterTime("get notices", 50, TimeUnit.MILLISECONDS));
        System.out.println(EchoMethod.echoAfterTime("get todos", 100, TimeUnit.MILLISECONDS));
        stopWatch.stop();
        System.out.println("call methods costs " + stopWatch.getTime() + " mills");
    }
}
```

运行结果如下：

![](/assets/blocking-call-cost-time.png)

如果将阻塞方法包装为非阻塞方法，时间线可以优化为如下：

### 使用Future和Comp



