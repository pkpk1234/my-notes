# Reactor学习--Flux常用的静态工厂方法

Flux静态工厂方法超过七十个，绝大部分都是使用现有的数据源构造Flux数据流，比较常用大致又可以分为如下几类：

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

fromArray方法使用接收到数组构造Flux流，实际上just\(T ...t\)中接收到变长参数后，如果参数数组长度大于1，就调用fromArray进行构造的。即 Flux.just\("one", "two", "three"\); 实际上就是 Flux.fromArray\({"one", "two", "three"}\);

通过just方法和fromArray方法构造的Flux流，数据返回的顺序和数组中元素的顺序是一致的。

### fromIterable方法

fromIteratble方法使用接收到的Iterable对象构造Flux流，数据返回的顺序和Iterable的next方法返回数据的顺序一致。如下例子中使用fromIteratble构造了JVM支持的字符集的Flux流。

```java
public class FromIterable {
    public static void main(String[] args) {
        SortedMap<String, Charset> charSetMap = Charset.availableCharsets();
        Iterable<String> iterable = charSetMap.keySet();

        Flux<String> charsetFlux = Flux.fromIterable(iterable);
        charsetFlux.subscribe(System.out::println);
    }
}
```

### fromSteam方法

Flux数据流同样可以使用java.util.stream.Stream对象构造出来，数据返回的顺序和Stream.iterator\(\)方法返回的Iterable对象的next方法返回数据的顺序一致。

```java
public class FromStream {
    public static void main(String[] args) {
        SortedMap<String, Charset> charSetMap = Charset.availableCharsets();
        Stream<String> charSetStream = charSetMap.keySet().stream();
        Flux<String> charsetFlux = Flux.fromStream(charSetStream);
        charsetFlux.subscribe(System.out::println);
    }
}
```





