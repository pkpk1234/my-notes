# Reactor学习--Flux高级静态工厂方法

这里所谓的高级指的是静态工厂方法的输入一般为其他Publisher实例，和之前简单的静态工厂方法的输入相比高级一些。

这些静态工厂方法又可以细分为如下几类：

1. 构造一个周期性产生递增Long序列的Flux。
2. 接收一个Publisher，将其包装为Flux流。
3. 接收一个Supplier，延迟构造Publisher。
4. 接收多个已有Flux，将其组合为一个Flux。
5. create方法，将已有的异步事件流，包装为Flux流

### interval方法

interval方法周期性生成从0开始的的Long。周期从delay之后启动，每隔period时间返回一个加1后的Long。

注意，interval方法返回的Flux运行在另外的线程中，main线程需要休眠或者阻塞之后才能看到周期性的输出。如下：

```java
public class Interval {
    public static void main(String[] args) throws InterruptedException {
        Flux.interval(Duration.ofSeconds(1), Duration.ofSeconds(1)).subscribe(System.out::println);
        Thread.sleep(5000);
    }
}
```

运行之后输出如下：

![](/assets/interval.png)

### from\(Publisher&lt;? extends T&gt; source\)方法

将已有的Publisher包装为一个Flux流。如下例子将已有的Flux和Mono包装为Flux。

```java
public class FromPublisher {
    public static void main(String[] args) {
        Publisher<Integer> fluxPublisher = Flux.just(1, 2, 3);
        Publisher<Integer> monoPublisher = Mono.just(0);

        System.out.println("Flux from flux");
        Flux.from(fluxPublisher).subscribe(System.out::println);

        System.out.println("Flux from mono");
        Flux.from(monoPublisher).subscribe(System.out::println);
    }
}
```

### defer方法

defer构造出的Flux流，每次调用subscribe方法时，都会调用Supplier获取Publisher实例作为输入。

如果Supplier每次返回的实例不同，则可以构造出和subscribe次数相关的Flux源数据流。

如果每次都返回相同的实例，则和from\(Publisher&lt;? extends T&gt; source\)效果一样。

如下例子构造了一个和subscribe次数相关的Flux。

```java
public class Defer {
    public static void main(String[] args) {
        AtomicInteger subscribeTime = new AtomicInteger(1);
        //实现这一的效果，返回的数据流为1~5乘以当前subscribe的次数
        Supplier<? extends Publisher<Integer>> supplier = () -> {
            Integer[] array = {1, 2, 3, 4, 5};
            int currentTime = subscribeTime.getAndIncrement();
            for (int i = 0; i < array.length; i++) {
                array[i] *= currentTime;
            }
            return Flux.fromArray(array);
        };

        Flux<Integer> deferedFlux = Flux.defer(supplier);

        subscribe(deferedFlux, subscribeTime);
        subscribe(deferedFlux, subscribeTime);
        subscribe(deferedFlux, subscribeTime);
    }

    private static void subscribe(Flux<Integer> deferedFlux, AtomicInteger subscribeTime) {
        System.out.println("Subscribe time is "+subscribeTime.get());
        deferedFlux.subscribe(System.out::println);
    }
}
```

输出如下：

![](/assets/defer.png)

### concat方法和merge方法

concat 及其重载方法接收 多个Publisher拼接为一个Flux返回，返回元素时首先返回接收到的第一个Publisher流中的元素，直到第一个Publisher流结束之后，才开始返回第二个Publisher流中的元素，依次类推... 如果发生异常，Flux流会立刻异常终止。

```java
public class Concat {
    public static void main(String[] args) {
        Flux<Integer> source1 = Flux.just(1, 2, 3, 4, 5);
        Flux<Integer> source2 = Flux.just(6, 7, 8, 9, 10);

        Flux<Integer> concated = Flux.concat(source1, source2);
        concated.subscribe(new MySubscriber("concated"));

    }

}
```

有些场景不希望前面流中的异常影响后面的流，可以使用concatDelayError方法。

concatDelayError 和 concat的方法功能相同，唯一不同在于异常处理。concatDelayError会等待所有的流处理完成之后，再将异常传播下去。

```java
public class ConcatDelayError {
    public static void main(String[] args) {
        Flux<Integer> sourceWithErrorNumFormat = Flux.just("1", "2", "3", "4", "Five").map(
                str -> Integer.parseInt(str)
        );
        Flux<Integer> source = Flux.just("5", "6", "7", "8", "9").map(
                str -> Integer.parseInt(str)
        );

        Flux<Integer> concated = Flux.concatDelayError(sourceWithErrorNumFormat, source);
        concated.subscribe(new MySubscriber("concatDelayError"));
    }
}
```

运行结果如下，可以看到第一个流中的异常数据类型造成的NumberFormatException异常没有影响后的流，而是最后才传播出去。

![](/assets/ConcatDelayError.png)

concat方法中流只能依次执行，即使后面的流先产生了数据也是如此。如果场景要求尽快返回数据，而无论流的排序，则可以使用merger方法。

merge和concat方法类似，只是不会依次返回每个Publisher流中数据，而是哪个Publisher中先有数据生成，就立刻返回。如果发生异常，会立刻抛出异常并终止。这里使用interval构造两个周期流。subscribe之后，一个等待1秒后启动，一个等待2秒后启动。

```java
public class Merge {
    public static void main(String[] args) throws InterruptedException {
        Flux<Long> flux1 = Flux.interval(Duration.ofSeconds(1), Duration.ofSeconds(1));
        Flux<Long> flux2 = Flux.interval(Duration.ofSeconds(2), Duration.ofSeconds(1));
        Flux<Long> mergedFlux = Flux.merge(flux1, flux2);
        mergedFlux.subscribe(System.out::println);
        Thread.sleep(5000);
    }
}
```

输出如下：可以看到，即使flux1还未complete，flux2就开始从0周期性进行输出了。

![](/assets/mergedFlux.png)

还有一类场景，即要尽快返回数据，又要考虑流的顺序，即同时有数据生成时，优先输出排在前面的流，此时可以使用mergeSequential方法。

### create方法

create方法，将已有的异步事件流，包装为Flux流。

MyEventProcessor是一个异步产生事件的组件，MyEventListener则是监听事件的组件。通过create方法，在事件产生时调用FluxSink的next或者complete方法，即可为Flux产生数据或者结束Flux。

```java
public class FluxBridge {

    private static MyEventProcessor myEventProcessor = new ScheduledSingleListenerEventProcessor();

    public static void main(String[] args) {
        Flux.create(sink -> {
            myEventProcessor.register(
                    new MyEventListener<String>() {
                        public void onEvents(List<String> chunk) {
                            for (String s : chunk) {
                                if ("end".equalsIgnoreCase(s)) {
                                    sink.complete();
                                    myEventProcessor.shutdown();
                                } else {
                                    sink.next(s);
                                }

                            }
                        }
                        public void processComplete() {
                            sink.complete();
                        }
                    });
        }).log().subscribe(System.out::println);
        myEventProcessor.fireEvents("abc", "efg", "123", "456", "end");
        System.out.println("main thread exit");
    }
}


public class ScheduledSingleListenerEventProcessor implements MyEventProcessor {
    private MyEventListener<String> eventListener;
    private ScheduledExecutorService executor = Executors.newSingleThreadScheduledExecutor();

    @Override
    public void register(MyEventListener<String> eventListener) {
        this.eventListener = eventListener;
    }

    @Override
    public void fireEvents(String... values) {
        //每个半秒发送一个事件
        executor.schedule(() -> eventListener.onEvents(Arrays.asList(values)),
                500, TimeUnit.MILLISECONDS);
    }

    @Override
    public void processComplete() {
        executor.schedule(() -> eventListener.processComplete(),
                500, TimeUnit.MILLISECONDS);
    }

    @Override
    public void shutdown() {
        this.executor.shutdownNow();
    }
}
```

输出如下：

![](/assets/create.png)

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



