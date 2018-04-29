# Project Reactor学习--异常处理Operator

之前的文章中介绍了Reactor中Operator的分类和日志相关的Operator，现在介绍下异常处理相关的Operator。

对于异常处理，Reactor除了默认的立刻抛出的处理方式之外，还提供三类处理方式：简单记录日志、fallback方法以及retry重试。

如果对Spring Cloud中的Hystrix比较熟悉，可以发现这也是Hystrix处理异常的方式，所以使用Reactor，我们应该也可以实现类似于断路器的功能，后续我们可以试试。

这里继续介绍异常处理Operator。

### 静态fallback值（StaticFallbackValue）

通过onErrorReturn方法加工返回的Publisher，提供了静态fallback值，即Publisher异常时，返回一个编译时写死的值，这也StaticFallbackValue中Static的意思。如下例子：

```java
public class StaticFallbackValue {
    public static void main(String[] args) {
        Flux<Integer> flux = Flux.just(0)
                .map(i -> 1 / i)
                //异常时返回0
                .onErrorReturn(0);
        //输出应该为0
        flux.log().subscribe(System.out::println);
    }
}
```

例子中我们还有log Operator记录每个step，根据预期Flux不会抛出异常，而是返回静态fallbakc值0，运行结果如下：完全符合我们的预期。

![](/assets/StaticFallbackValue.png)

### 静态fallback条件值（StaticFallbackConditionValue）

在编译时写死fallbakc value并不灵活，所以Reactor提供了根据异常信息返回不同fallback value的功能。

onErrorReturn可以根据异常的信息，返回不同的值。如下：

```java
public class StaticFallbackConditionValue {
    public static void main(String[] args) {
        //1. 根据异常类型进行判断
        Flux<Integer> flux = Flux.just(0)
                .map(i -> 1 / i)
                //ArithmeticException异常时返回1
                .onErrorReturn(NullPointerException.class, 0)
                .onErrorReturn(ArithmeticException.class, 1);
        //输出应该为1
        flux.log().subscribe(System.out::println);

        final String nullStr = null;
        //just不允许对象为null
        Flux<String> stringFlux = Flux.just("")
                .map(str -> nullStr.toString())
                //NullPointerException异常时返回字符串NullPointerException
                .onErrorReturn(NullPointerException.class, "NullPointerException")
                .onErrorReturn(ArithmeticException.class, "ArithmeticException");
        //输出应该为NullPointerException
        stringFlux.log().subscribe(System.out::println);

        //2. 根据Predicate进行判断
        AtomicInteger index = new AtomicInteger(0);
        Flux.just(0, 1, 2, 3)
                .map(i -> {
                    index.incrementAndGet();
                    return 1 / i;
                })
                .onErrorReturn(NullPointerException.class, 0)
                .onErrorReturn(e -> index.get() < 2, 1)
                //因为上一个onErrorReturn匹配了条件，所以异常传播被关闭，之后的
                //onErrorReturn不会再被触发
                .onErrorReturn(e -> index.get() < 1, 2)

                //因为异常类型为NumberFormatException，此处应打印1
                .log().subscribe(System.out::println);
    }
}
```

可以多次调用onErrorReturn，最匹配的一个会处理异常，一旦异常被处理，异常传播则会结束，后面的onErrorReturn不会再接收到异常。

运行结果如下：

![](/assets/StaticFallbackConditionValue.png)

onErrorResume

onErrorReturn在发生异常时结束流，后面的数据也不会再被发送。 但是很多场景中，并不希望一个异常数据影响整个流，此时可以使用onErrorResume。

