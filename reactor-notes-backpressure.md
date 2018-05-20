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
        Flux<Integer> flux = Flux.range(0, 50).doOnComplete(() -> countDownLatch.countDown());
        flux.subscribe(new MyLimitedSubscriber(5));
        countDownLatch.await();

        //使用比count还大的limiter，相当于不限流
        System.out.println("use big limiter");
        Flux.range(0, 50)
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


