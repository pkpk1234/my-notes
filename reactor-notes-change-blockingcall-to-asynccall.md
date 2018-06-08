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
        HomePageService homePageService = new HomePageService();
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        String userInfo = homePageService.getUserInfo();
        System.out.println(userInfo);
        System.out.println(homePageService.getNotice());
        System.out.println(homePageService.getTodos(userInfo));
        stopWatch.stop();
        System.out.println("call methods costs " + stopWatch.getTime() + " mills");
    }

}
```

```java
public class HomePageService {
    public String getUserInfo() {
        return EchoMethod.echoAfterTime("get user info", 50, TimeUnit.MILLISECONDS);
    }

    public String getNotice() {
        return EchoMethod.echoAfterTime("get notices", 50, TimeUnit.MILLISECONDS);
    }

    public String getTodos(String userInfo) {
        return EchoMethod.echoAfterTime("get todos", 100, TimeUnit.MILLISECONDS);
    }

}
```

EchoMethod中使用TimeUtil.sleep进行阻塞模拟：

```java
public class EchoMethod {
    /**
     * 模拟阻塞方法
     *
     * @param str
     * @param delay
     * @param timeUnit
     * @return
     */
    public static String echoAfterTime(String str, int delay, TimeUnit timeUnit) {
        try {
            timeUnit.sleep(delay);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return str;
    }

}
```

运行结果如下：

![](/assets/blocking-call-cost-time.png)

如果将阻塞方法包装为非阻塞方法，时间线可以优化为如下：

![](/assets/async-methods-timeline.png)

### 使用Thread和Callback包装

如下HomePageServiceThreadsAndCallbackWrapper使用ThreadPool异步执行任务，并且在任务成功完成，异常终止以及最终完成时，调用相应的Callback函数。

```java
public class HomePageServiceThreadsAndCallbackWrapper {

    private final HomePageService homePageService;
    private final ExecutorService threadPool = Executors.newFixedThreadPool(
            Runtime.getRuntime().availableProcessors()
    );

    public ThreadsAndCallbackWrapper(HomePageService homePageService) {
        this.homePageService = homePageService;
        Runtime.getRuntime().addShutdownHook(new Thread(() -> threadPool.shutdownNow()));
    }

    void getUserInfoAsync(Consumer<String> sucessCallback, Consumer<Throwable> errorCallback, Runnable finallyCallback) {
        threadPool.submit(() -> {
            try {
                String userInfo = this.homePageService.getUserInfo();
                sucessCallback.accept(userInfo);
            } catch (Throwable ex) {
                errorCallback.accept(ex);
            } finally {
                finallyCallback.run();
            }

        });
    }

    void getNoticeAsync(Consumer<String> sucessCallback, Consumer<Throwable> errorCallback, Runnable finallyCallback) {
        threadPool.submit(() -> {
            try {
                String notice = this.homePageService.getNotice();
                sucessCallback.accept(notice);
            } catch (Throwable ex) {
                errorCallback.accept(ex);
            } finally {
                finallyCallback.run();
            }

        });
    }

    void getTodos(String userInfo, Consumer<String> sucessCallback, Consumer<Throwable> errorCallback, Runnable finallyCallback) {
        threadPool.submit(() -> {
            try {
                String todos = this.homePageService.getTodos(userInfo);
                sucessCallback.accept(todos);
            } catch (Throwable ex) {
                errorCallback.accept(ex);
            } finally {
                finallyCallback.run();
            }

        });
    }

}
```

调用方也需要进行相应修改，以适应异步特点。

```java
private static void threadAndCallbackCall() {
        //用于让调用者线程等待多个异步任务全部结束
        CountDownLatch ct = new CountDownLatch(3);
        HomePageService homePageService = new HomePageService();
        HomePageServiceThreadsAndCallbackWrapper homePageServiceFutureWrapper
                = new HomePageServiceThreadsAndCallbackWrapper(homePageService);
        //统一的finallyCallback
        Runnable finallyCallback = () -> {
            ct.countDown();
        };
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        //获取用户信息
        homePageServiceFutureWrapper.getUserInfoAsync(
                (userInfo) -> {
                    System.out.println(userInfo);
                    //由于获取todo依赖于用户信息，必须在此处调用
                    homePageServiceFutureWrapper.getTodos(userInfo,
                            (todos) -> {
                                System.out.println(todos);
                            }, System.err::println, finallyCallback);
                }, System.err::println, finallyCallback
        );
        //获取notice
        homePageServiceFutureWrapper.getNoticeAsync(System.out::println, System.err::println, finallyCallback);
        //等待异步操作全部结束并统计耗时
        ct.await();
        stopWatch.stop();
        System.out.println("thread and callbakc async call methods costs " + stopWatch.getTime() + " mills");
        //退出JVM线程，触发HomePageServiceThreadsAndCallbackWrapper中线程池的shutdownHook
        System.exit(0);
    }
```

注意异步任务之间如果有依赖，则需要在回调中进行调用，如此处todo依赖于用户信息。

运行结果：可以看到异步调用的确比同步调用快不少。

![](/assets/threadAndCallbackCall.png)

使用Thread和Callback的缺点：需要在代码中显示对线程或者线程池进行操作；如果依赖链很长，则可能出现回调地狱。

### 使用CompletableFuture进行包装

CompletableFuture是Java8新增的异步任务工具类，对Future进行了扩展，解决了Future只能阻塞获取结果，Future之间无法链式依赖调用，Future没有异常处理接口的缺点。

CompletableFuture.supplyAsync\(\)可以将阻塞方法包装为异步，同时thenCompose\(\)则可以链式调用依赖的方法，即将上一个异步调用的结果推送给下一个异步调用作为输入，如果将thenRun放置到最后，则相当于finallyCallback，exceptionally\(\)则可以设置异常处理器。

```java
public class HomePageSerivceCompletableFutureWrapper {
    private final HomePageService homePageService;

    public HomePageSerivceCompletableFutureWrapper(HomePageService homePageService) {
        this.homePageService = homePageService;
    }

    CompletableFuture<String> getUserInfoAsync() {
        return CompletableFuture.supplyAsync(this.homePageService::getUserInfo);
    }

    CompletableFuture<String> getNoticeAsync() {
        return CompletableFuture.supplyAsync(this.homePageService::getNotice);
    }

    CompletableFuture<String> getTodosAsync(String userInfo) {
        return CompletableFuture.supplyAsync(() -> this.homePageService.getTodos(userInfo));
    }
}
```

调用者：

```java
private static void completableFutureCall() throws InterruptedException {
        //用于让调用者线程等待多个异步任务全部结束
        CountDownLatch ct = new CountDownLatch(2);
        HomePageService homePageService = new HomePageService();
        HomePageSerivceCompletableFutureWrapper homePageSerivceCompletableFutureWrapper =
                new HomePageSerivceCompletableFutureWrapper(homePageService);
        //统一的finallyCallback
        Runnable finallyCallback = () -> {
            ct.countDown();
        };
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        homePageSerivceCompletableFutureWrapper
                .getUserInfoAsync()
                //依赖调用
                .thenCompose(userInfo -> {
                    System.out.println(userInfo);
                    return homePageSerivceCompletableFutureWrapper.getTodosAsync(userInfo);
                  })
                .thenAcceptAsync(System.out::println)
                .thenRun(finallyCallback);

        homePageSerivceCompletableFutureWrapper
                .getNoticeAsync()
                .thenAcceptAsync(System.out::println)
                .thenRun(finallyCallback);
        //等待异步操作全部结束并统计耗时
        ct.await();
        stopWatch.stop();
        System.out.println("CompletableFuture async call methods costs " + stopWatch.getTime() + " mills");

    }
```

可以明显看到代码简洁了不少。

运行结果:

![](/assets/completableFutureCall.png)

