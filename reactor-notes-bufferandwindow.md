# Project Reactor学习--Buffer和Window Operator

实际项目中，有时候会遇到这样的场景，处理数据的操作准备阶段或者Finally阶段十分耗时，并且数据可以被批量处理，比如使用JDBC保存数据，此时更有效率的处理数据的方式是批量处理一批数据，而不是单个依次处理。

Flux流提供了两种方法将原始流分割为多个批量的块，方便Subscriber一次接收到多条数据进行批量操作。

buffer和window根据设置的每次批量返回的数据的个数或者时间窗的长度分割数据并返回，区别是buffer会缓存数据，当缓存的数据的数量达到设置的时或者时间窗口结束时，才批量返回数据。而window则是在Publisher发布数据之后，立刻返回数据，直到返回的数据的数量达到设置的值，或者时间窗结束。

## Buffer

如下例子：每次批量返回5个数据

```java
public class BufferOnHotStream {
    public static void main(String[] args) {
        UnicastProcessor<String> hotSource = UnicastProcessor.create();
        Flux<String> hotFlux = hotSource
                .publish()
                .autoConnect()
                .onBackpressureBuffer(10);

        CompletableFuture future = CompletableFuture.runAsync(() -> {
            IntStream.range(0, 50).forEach(
                    value -> {
                        hotSource.onNext("value is " + value);
                    }
            );
        });

        hotFlux.buffer(5).subscribe(new BaseSubscriber<List<String>>() {
            @Override
            protected void hookOnSubscribe(Subscription subscription) {
                request(20);
            }

            @Override
            protected void hookOnNext(List<String> value) {
                System.out.println("get value " + value);

            }
        });
        future.thenRun(() -> hotSource.onComplete());
        future.join();
    }
}
```

运行结果：

![](/assets/hotBuffer.png)

其他更多的buffer操作例子详见：https://github.com/pkpk1234/learn-reactor/blob/master/src/main/java/com/ljm/reactor/operators/BufferOnColdStream.java

本质上没有区别，只是分割方式有些不同。

## window





