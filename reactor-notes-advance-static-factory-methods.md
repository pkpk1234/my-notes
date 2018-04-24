# Reactor学习--Flux高级静态工厂方法

这里所谓的高级指的是静态工厂方法的输入一般为其他Publisher实例，和之前简单的静态工厂方法的输入相比高级一些。

这些静态工厂方法又可以细分为如下几类：

1. 构造一个周期性产生递增Long序列的Flux。
2. 接收一个Publisher，将其包装为Flux流。
3. 接收一个Supplier，延迟构造Publisher。
4. 接收多个已有Flux，将其组合为一个Flux。concat、merge
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







![](/assets/mergedFlux.png)

