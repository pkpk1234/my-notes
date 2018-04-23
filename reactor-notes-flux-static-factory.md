# Reactor学习--Flux常用的静态工厂方法

Flux静态工厂方法超过七十个，比较常用大致又可以分为如下几类：

1. 使用可变长参数构造
2. 使用数组构造
3. 使用Iterable对象构造
4. 使用Stream对象构造
5. 只用于返回int数据流的range方法
6. 用于返回特殊数据流的empty、never、error方法

### just方法

just方法接收若干个参数，使用这些参数构造一个Flux流，如下：

```java
public class FluxSubscriber {
    public static void main(String[] args) {
        Flux<String> stringFlow = Flux.just("one", "two", "three");

        //subscribe with consumer
        System.out.println("example for subscribe with consumer");
        stringFlow.subscribe(System.out::println);
    }
}
```

如果使用过Java 8 Stream，可以将just方法类比为Stream.of\(T ... t\)方法。

### fromArray方法

fromArray方法使用接收到数组构造Flux流，实际上just\(T ...t\)中接收到变长参数后，如果参数数组长度大于1，就调用fromArray进行构造的。



