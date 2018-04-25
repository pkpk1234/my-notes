# Project Reactor学习--Publisher线程相关方法

Publisher号称是异步的事件流，Java里面单线程是没法异步的，同时号称底层是否使用并发对上层是透明的，所以Publisher具有若干切换代码执行上下文（其实就是线程）的方法。

Reactor使用reactor.core.scheduler.Scheduler对执行一个异步执行的操作进行抽象，底层使用ExecutorService或者ScheduledExecutorService执行这个异步操作。

Reactor提供了多种Scheduler实现，并提供了工厂类reactor.core.scheduler.Schedulers方便开发者使用。

Publisher则提供了publishOn和subscribeOn两个方法设置要使用的Scheduler。

上代码比较直观：

```java
public class FluxPublishOn {
    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(1);
        Flux.range(1, 20)
                //使用Schedulers.parallel()线程池执行之后的操作
                .publishOn(Schedulers.parallel())
                .doOnComplete(() -> countDownLatch.countDown())
                .subscribe(i -> {
                    System.out.println("Current Thread is "
                            + Thread.currentThread().getName() + ", value " + i);
                });
        //如果使用了Scheduler，则subscribe是异步的，主线程必须阻塞才行
        System.out.println(Thread.currentThread().getName() + "-Main thread blocking");
        countDownLatch.await();
        System.out.println(Thread.currentThread().getName() + "-Flow complete,Main thread run and finished");

    }
}
```

输出如下：可以看到subscribe方法执行的线程不在主线程中，所以主线程继续执行到System.out.println了。![](/assets/publishOn.png)

### publishOn方法和subscribeOn方法

这两个方法都可以将程序执行的线程切换到传入的Scheduler上。区别是publishOn会让之后的操作在Scheduler提供的线程中执行，subscribeOn会让之前的操作在Scheduler提供的线程中执行。

如下例子中，在publishOn之前执行了map操作，之后执行subscribe操作。

```java
public class FluxPublishOnThreadSwitch {

    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(1);
        Flux.range(1, 20)
                .map(i -> {
                    System.out.println("map in Thread " + Thread.currentThread().getName() +" value is " + i);
                    return ++i;
                })
                //使用Schedulers.parallel()线程池执行之后的操作
                .publishOn(Schedulers.parallel())
                .doOnComplete(() -> countDownLatch.countDown())
                .subscribe(i -> {
                    System.out.println("Current Thread is "
                            + Thread.currentThread().getName() + ", value " + i);
                });
        //如果使用了Scheduler，则subscribe是异步的，主线程必须阻塞才行
        System.out.println(Thread.currentThread().getName() + "-Main thread blocking");
        countDownLatch.await();
        System.out.println(Thread.currentThread().getName() + "-Flow complete,Main thread run and finished");
    }
}
```

输出如下：可以看map操作还是在主线程中执行的。而subscribe中的操作都是在parallel线程中执行的。

![](/assets/FluxPublishOnThreadSwitch.png)

### 使用Scheduler将阻塞方法包装为异步

本质上就在另一个线程中执行阻塞方法，只不过Flux提供了Api，开发者不用关心线程的管理。

这样做的优点是可以让当前线程不用在阻塞方法上等待，而是继续去做其他事情，让线程充分工作。

如下例子对比了同步读取文件，和使用Scheduler包装同步方法为异步之后的性能。

```java
public class PublisherWrapBlockingCall {
    public static void main(String[] args) throws InterruptedException {
        //提前构造出线程池
        Schedulers.elastic();

        String[] files = {
                "com/ljm/reactor/scheduler/PublisherWrapBlockingCall.class",
                "com/ljm/reactor/scheduler/FluxPublishOn.class",
                "com/ljm/reactor/scheduler/FluxPublishOnThreadSwitch.class"
        };
        //同步读取
        Instant start = Instant.now();
        for (String fileName : files) {
            blockingRead(fileName);
        }
        Instant end = Instant.now();
        System.out.println("\n\n>>>>>>>> blocking read cost mills：" + Duration.between(start, end).toMillis());

        //异步读取
        CountDownLatch latch = new CountDownLatch(3);
        start = Instant.now();

        for (String file : files) {
            Mono.fromRunnable(() -> blockingRead(file))
                    //让前面的操作运行在线程池中
                    .subscribeOn(Schedulers.elastic())
                    .doOnTerminate(() -> latch.countDown())
                    .subscribe();
        }
        latch.await();
        end = Instant.now();
        System.out.println("\n\n>>>>>>>>> async read cost mills：" + Duration.between(start, end).toMillis());
    }

    /**
     * 同步读取文件并打印
     * @param fileName
     */
    private static void blockingRead(String fileName) {

        InputStream in = PublisherWrapBlockingCall.class.getClassLoader().getResourceAsStream(fileName);
        try {
            int i = -1;
            while ((i = in.read()) != -1) {
                System.out.print(i);
            }
            Thread.sleep(1000);
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            try {
                in.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

    }
}
```

运行结果：可以看到包装为异步之后，性能提升不少。

![](/assets/PublisherWrapBlockingCall.png)

