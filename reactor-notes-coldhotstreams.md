## Cold流和Hot流

Cold流不论订阅者在何时订阅该数据流，总是能收到数据流中产生的全部消息，所以Cold流是肯定保存了数据流中所有数据的。

Hot流则是在持续不断地产生消息，订阅者只能获取到在其订阅之后产生的消息。

## 构造Hot流

两种方式：将已有 Cold流转变为Hot流和使用Processor动态产生数据。

### 将已有Cold流转变为Hot流

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

### 使用Processor构造Hot流

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

