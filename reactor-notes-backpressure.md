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

### 背压策略

背压策略指的是当Subscriber无法及时request更多数据时，Publisher采取的措施。

可选的策略有buffer、error 、drop和latest，默认策略为buffer。

### 背压策略方法

可以通过onBackPressureBuffer、onBackPressureError、onBackPressureDrop、onBackPressureLatest选择不同策略。

##### onBackPressureBuffer

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

onBackPressureBuffer方法还可以指定缓存溢出策略，默认策略为BufferOverflowStrategy.ERROR效果即上面的例子。可选的策略还有DROP\_OLDEST丢弃最旧元素，DROP\_LATEST丢弃最新的元素。如下：

```java
public class BackpressureOnBackpressureBuffer2 {

    public static void main(String[] args) {
        System.out.println("Drop Oldest");
        drop(BufferOverflowStrategy.DROP_OLDEST);
        System.out.println("Drop LASTED");
        drop(BufferOverflowStrategy.DROP_LATEST);
    }

    private static void drop(BufferOverflowStrategy bufferOverflowStrategy) {
        UnicastProcessor<String> hotSource = UnicastProcessor.create();
        //构建Flux，buffer大小为5，BufferOverflowStrategy策略为丢弃最久的元素
        Flux<String> hotFlux = getHotFlux(hotSource, 5, bufferOverflowStrategy);
        CompletableFuture future = produceData(hotSource);
        //构建Subscriber，初次请求20个元素
        BaseSubscriber<String> subscriber = createSubscriber(20);
        hotFlux.subscribe(subscriber);

        future.join();
        System.out.println("get rest elements from buffer");
        //再次获取10个元素，根据策略应返还最后的10个元素
        subscriber.request(10);
    }

    private static BaseSubscriber<String> createSubscriber(int initRequests) {
        return new BaseSubscriber<String>() {
            @Override
            protected void hookOnSubscribe(Subscription subscription) {
                request(initRequests);
            }

            @Override
            protected void hookOnNext(String value) {
                System.out.println("get value " + value);
            }
        };
    }

    private static CompletableFuture produceData(UnicastProcessor<String> hotSource) {
        return CompletableFuture.runAsync(() -> {
            IntStream.range(0, 50).forEach(
                    value -> {
                        hotSource.onNext("value is " + value);
                    }
            );
        });
    }

    private static Flux<String> getHotFlux(UnicastProcessor hotSource, 
    int maxBufferSize, BufferOverflowStrategy strategy) {

        return hotSource
                .publish()
                .autoConnect()
                .onBackpressureBuffer(maxBufferSize, strategy);
    }
}
```

执行结果：注意get rest elements之后的值，Drop Oldest会保存最新的值，反正则是最久的值。

![](/assets/dropOldest.png)  ![](/assets/dropLasted.png)

#### onBackPressureError

onBackPressureError直接抛出异常。

#### onBackPressureLatest

onBackPressureLates相当于onBackpressureBuffer\(1, DROP\_OLDEST\) ，如下：

```java
public class BackPressureOnBackpressureLatest {
    public static void main(String[] args) {
        onBackpressureLatest();
    }

    private static void onBackpressureLatest() {
        UnicastProcessor<String> hotSource = UnicastProcessor.create();
        Flux<String> hotFlux = getHotFlux(hotSource);
        CompletableFuture future = produceData(hotSource);
        //构建Subscriber，初次请求20个元素
        BaseSubscriber<String> subscriber = createSubscriber(20);
        hotFlux.subscribe(subscriber);

        future.join();
        System.out.println("get rest elements");
        //再次获取10个元素，根据策略应返还最后的10个元素
        subscriber.request(10);
    }

    private static BaseSubscriber<String> createSubscriber(int initRequests) {
        return new BaseSubscriber<String>() {
            @Override
            protected void hookOnSubscribe(Subscription subscription) {
                request(initRequests);
            }

            @Override
            protected void hookOnNext(String value) {
                System.out.println("get value " + value);
            }
        };
    }

    private static CompletableFuture produceData(UnicastProcessor<String> hotSource) {
        return CompletableFuture.runAsync(() -> {
            IntStream.range(0, 50).forEach(
                    value -> {
                        hotSource.onNext("value is " + value);
                    }
            );
        });
    }

    private static Flux<String> getHotFlux(UnicastProcessor hotSource) {

        return hotSource
                .publish()
                .autoConnect()
                .onBackpressureLatest();
    }
}
```

运行结果：注意rest element为49，即buffer为1，并且只保存了最新的一个元素。

![](/assets/BackPressureOnBackpressureLatest.png)

#### onBackpressureDrop

onBackpressureDrop会丢弃溢出的所有元素。

### 



