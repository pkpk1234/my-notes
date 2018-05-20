# Project Reactor学习--背压

Reactive Stream和Java 8 中Stream流的重要一个区别就是Reactive Stream支持背压（Back Pressure），

这也是Reactive Stream的主要卖点之一。

背压指的是当Subscriber请求的数据的访问超出它的处理能力时，Publisher限制数据发送速度的能力。

默认情况下，Subscriber会要求Publisher有多少数据推多少数据，能推多快就推多块。

本质上背压和TCP中的窗口限流机制比较类似，都是让消费者反馈请求数据的范围，生产者根据消费者的反馈提供一定量的数据来进行流控。

反馈请求数据范围的操作，可以在Subscriber每次完成数据的处理之后，让Subscriber自行反馈；也可以在Subscriber外部对Subscriber的消费情况进行监视，根据监视情况进行反馈。

如下例子：一个带线程池的Subscriber，当线程池的workQueue未满时，向Publisher请求数据，反之则等待一会再请求。

```java
public class BackpressureDemo {
    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(1);
        //可以观察到明显的限流
        Flux<Long> flux = Flux.interval(Duration.ofMillis(50))
                .take(50)
                .doOnComplete(() -> countDownLatch.countDown());
        flux.subscribe(new MyLimitedSubscriber(5));
        countDownLatch.await();

        //使用比count还大的limiter，相当于不限流
        System.out.println("use big limiter");
        Flux.interval(Duration.ofMillis(50))
                .take(50)
                .subscribe(new MyLimitedSubscriber(100));
    }
}
```

```java
public class MyLimitedSubscriber<T> extends BaseSubscriber<T> {
    private long mills;
    private ThreadPoolExecutor threadPool;
    private int maxWaiting;
    private final Random random = new Random();

    public MyLimitedSubscriber(int maxWaiting) {
        this.maxWaiting = maxWaiting;
        this.threadPool = new ThreadPoolExecutor(
                1, 1, 0L,
                TimeUnit.MILLISECONDS, new LinkedBlockingQueue<>(maxWaiting));
    }

    @Override
    protected void hookOnSubscribe(Subscription subscription) {
        this.mills = System.currentTimeMillis();
        requestNextDatas();
    }

    @Override
    protected void hookOnComplete() {
        long now = System.currentTimeMillis();
        long time = now - this.mills;
        System.out.println("cost time:" + time / 1000 + " seconds");
        this.threadPool.shutdown();
    }

    @Override
    protected void hookOnNext(T value) {
        //提交任务
        this.threadPool.execute(new MyTask(value));
        //请求数据
        requestNextDatas();
    }


    private void requestNextDatas() {
        //计算请求的数据的范围
        int requestSize = this.maxWaiting - this.threadPool.getQueue().size();
        if (requestSize > 0) {
            System.out.println("Thread Pool can handle,request " + requestSize);
            request(requestSize);
            return;
        } else {
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            requestNextDatas();
        }

    }

    class MyTask<T> implements Runnable {
        private T data;

        public MyTask(T data) {
            this.data = data;
        }

        @Override
        public void run() {
            try {
                Thread.sleep(random.ints(100, 500).findFirst().getAsInt());
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("data is " + data);
            //可以在处理完成数据之后，立刻进行请求，此时Subscriber肯定是能够可以可靠处理数据的
            //requestNextDatas()或者调用BaseSubscriber#request(1)
        }

    }
}
```

上面例子中Publisher在收到request之后，实际上是采用了默认的OverflowStrategy，即将数据缓存起来，当Subscriber有能力处理时，再推送过去。

### Cold流和Hot流

Cold流不论订阅者在何时订阅该数据流，总是能收到数据流中产生的全部消息，所以Cold流是肯定保存了数据流中所有数据的。

Hot流则是在持续不断地产生消息，订阅者只能获取到在其订阅之后产生的消息。

### 构造Hot流

两种方式：将已有 Cold流转变为Hot流和使用Processor动态产生数据。

##### 将已有Cold流转变为Hot流

只需要调用publish方法即可，只是要注意，添加非第一个Subscriber前，需要调用一下connect方法。如下例子：

```java
public class ConvertCold2Hot {
    public static void main(String[] args) throws InterruptedException {
        ConnectableFlux<Long> flux = Flux.interval(Duration.ofSeconds(1))
                .take(10)
                .publish();
        flux.subscribe(aLong -> {
            System.out.println("subscriber1 ,value is " + aLong);
        });

        Thread.sleep(5000);
        //加入第二个Subscriber之前，需要connect一下
        flux.connect();
        flux.subscribe(aLong -> {
            System.out.println("subscriber2 ,value is " + aLong);
        });
        flux.blockLast();
    }
}
```

执行结果如下：注意subscriber2获取的值从5开始了，因为此时Hot流中的数据从5开始的。

![](/assets/ConvertCold2Hot.png)

##### 使用Processor构造Hot流

使用Processor的publish方法即可构造出一个Hot Stream，调用同一个Processor实例的onNext方法即可为之前构造的Hot Stream提供数据。如下例子：

```java
public class HotStreamByProcessor {
    public static void main(String[] args) throws InterruptedException {
        //使用Reactor提供的Processor工具类
        UnicastProcessor<String> hotSource = UnicastProcessor.create();
        //构造Hot Stream，同时配置为autoConnect，避免每加入一个Subscriber都需要调用一次connect方法
        Flux<String> hotFlux = hotSource
                .publish()
                .autoConnect();

        //异步为Hot Stream提供数据
        CompletableFuture future = CompletableFuture.runAsync(() -> {
            IntStream.range(0, 10).forEach(
                    value -> {
                        try {
                            Thread.sleep(100);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        //调用Processor的onNext即可以为Processor关联的Hot Stream提供数据
                        hotSource.onNext("value is " + value);
                    }
            );
        });

        hotFlux.subscribe(s -> System.out.println("subsciber1: " + s));
        Thread.sleep(500);
        hotFlux.subscribe(s -> System.out.println("subsciber2: " + s));
        //提供完数据之后，调用Processor的onComplete关闭Hot Stream
        future.thenRun(() -> hotSource.onComplete());
        future.join();
    }
}
```

执行结果如下：可以看到subscribe2的值从4开始。

![](/assets/HotStreamByProcessor.png)

### 背压策略

背压策略指的是当Subscriber无法及时request更多数据时，Publisher采取的措施。

可选的策略有buffer、error 、drop和latest，默认策略为buffer。

##### 背压策略方法

可以通过onBackPressureBuffer、onBackPressureError、onBackPressureDrop、onBackPressureLatest选择不同策略。

例子如下：

```java
public class BackpressureOnBackpressureError {
    public static void main(String[] args) throws InterruptedException {
        ExecutorService threadPool = Executors.newFixedThreadPool(4);
        UnicastProcessor<String> hotSource = UnicastProcessor.create();
        Flux<String> hotFlux = hotSource
                .publish()
                .autoConnect()
                .onBackpressureError();

        CompletableFuture future = CompletableFuture.runAsync(() -> {
            IntStream.range(0, 50).parallel().forEach(
                    value -> {
                        threadPool.submit(() -> hotSource.onNext("value is " + value));
                    }
            );
        });
        System.out.println("future run");

        hotFlux.subscribe(new BaseSubscriber<String>() {
            @Override
            protected void hookOnSubscribe(Subscription subscription) {
                request(1);
            }

            @Override
            protected void hookOnNext(String value) {
                System.out.println("get value " + value);
            }

            @Override
            protected void hookOnError(Throwable throwable) {
                throwable.printStackTrace();
            }
        });
        Thread.sleep(500);
        System.out.println("shutdown");
        threadPool.shutdownNow();
    }
}
```

执行结果如下：

![](/assets/BackpressureOnBackpressureError.png)

##### 背压策略类

除了策略方法，Reactor还提供了对应的策略类，FluxOnBackpressureBufferStrategy、

