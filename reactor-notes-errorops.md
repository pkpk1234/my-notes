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

### onErrorResume

onErrorReturn在发生异常时结束流，后面的数据也不会再被发送。 但是很多场景中，并不希望一个异常数据影响整个流，此时可以使用onErrorResume替代onErrorReturn。onErrorResumej接收一个Function&lt;? super Throwable, ? extends Publisher&lt;? extends T&gt;&gt; 对象。可以认为该对象是一个fallback method，接收异常信息，输出和流中数据的类型相同的值，使用这个返回值替代异常的数据值返回给Subscriber。 例子如下:

```java
public class FallbackMethod {
    private static Function<? super Throwable, ? extends Publisher<String>> fallback
            = e -> Mono.just(e.getMessage());

    public static void main(String[] args) {
        //1. 默认方法
        Flux<String> flux = Flux.just("0", "1", "2", "abc")
                .map(i -> Integer.parseInt(i) + "")
                .onErrorResume(e -> Mono.just("input string is not a number ," + e.getMessage()));
        flux.log().subscribe(System.out::println);

        //2. 根据异常类型选择返回方法
        flux = Flux.just("0", "1", "2", "abc")
                .map(i -> Integer.parseInt(i) + "")
                .onErrorResume(ArithmeticException.class, e -> Mono.just("ArithmeticException:" + e.getMessage()))
                .onErrorResume(NumberFormatException.class, e -> Mono.just("input string is not a number"))
                //如果上面列出的异常类型都不满足，使用默认方法
                .onErrorResume(e -> Mono.just(e.getMessage()));
        // 因为异常类型为NumberFormatException，此处应该打印字符串input string is not a number
        flux.log().subscribe(System.out::println);

        //3. 根据Predicate选择返回方法
        flux = Flux.just("0", "1", "2", "abc")
                .map(i -> Integer.parseInt(i) + "")
                .onErrorResume(e -> e.getMessage().equals("For input string: \"abc\""),
                        e -> Mono.just("exception data is abc"))
                //onErrorResume可以和onErrorReturn混合使用
                .onErrorReturn("SystemException");
        //因为判断条件，此处应该打印exception data is abc
        flux.log().subscribe(System.out::println);
    }
}
```

运行结果如下：可以看到，Flux流并没有因为异常数据结束，而是使用fallback method的返回值返回给Subscriber了。

![](/assets/fallback.png)

### doOnError

有些场景下，只是想简单记录下日志，并不想提供异常时作为替代的返回值，也不想影响默认的异常传播机制，此时可以使用doOnError。如下：

```java
public class DoOnError {
    public static void main(String[] args) {

        //1. 默认doOnError方法
        Flux<String> flux = Flux.just("0", "1", "2", "abc","3")
                .map(i -> Integer.parseInt(i) + "")
                .doOnError(e -> e.printStackTrace())
                .onErrorReturn("System exception");
        flux.log().subscribe(System.out::println);

        //2. 根据异常类型选择doError方法
        flux = Flux.just("0", "1", "2", "abc","3")
                .map(i -> Integer.parseInt(i) + "")
                .doOnError(RuntimeException.class, e -> {
                    System.err.println("发生了RuntimeException");
                    e.printStackTrace();
                })
                .doOnError(NumberFormatException.class, e -> {
                    System.err.println("发生了NumberFormatException");
                    e.printStackTrace();
                })
                .onErrorReturn("System exception");
        //因为异常类型为NumberFormatException，此处应打印字符串发生了NumberFormatException
        //又因为doOnError不会阻止异常传播，所以onErrorReturn会执行，返回字符串System exception
        flux.log().subscribe(System.out::println);

        //3. 根据Predicate选择doError方法
        //   注意doOnError不会阻止异常传播，所以onErrorReturn可以多次触发
        flux = Flux.just("0", "1", "2", "abc","3")
                .map(i -> Integer.parseInt(i) + "")
                .doOnError(e -> e instanceof Throwable, e -> {
                    System.err.println("异常类型为Throwable");
                })
                .doOnError(e -> e instanceof Exception, e -> {
                    System.err.println("同时异常类型为Exception");
                })
                .doOnError(e -> e instanceof NumberFormatException, e -> {
                    System.err.println("并且异常类型为NumberFormatException");
                })
                .doOnError(e -> e instanceof Error, e -> {
                    System.err.println("异常类型为Error");
                })
                .onErrorReturn("System exception");
        //因为异常类型为NumberFormatException，所以前面3个doOnError都会被调用
        flux.log().subscribe(System.out::println);
    }
}
```

### 重试

简单粗暴的异常处理方式，一次不成功就来两次，两次不成功就三次，以此类推。之前说过，每添加一个Operator，都是返回一个新的Publisher，此处也不例外，下面的例子可以清晰的证明。

```java
public class Retying {
    public static void main(String[] args) throws InterruptedException {


        //默认异常retry
        Flux<String> flux = Flux.just("0", "1", "2", "abc")
                .map(i -> Integer.parseInt(i) + "")
                .retry(2);
        flux.subscribe(newSub());

        //带条件判断的retry
        System.out.println("-------------------------------------------------");
        Thread.sleep(500);
        flux = Flux.just("0", "1", "2", "abc")
                .map(i -> Integer.parseInt(i) + "")
                .retry(1, e -> e instanceof Exception);

        flux.subscribe(newSub());

    }

    private static Subscriber<String> newSub() {
        return new BaseSubscriber<String>() {
            @Override
            protected void hookOnSubscribe(Subscription subscription) {
                System.out.println("start");
                request(1);
            }

            @Override
            protected void hookOnNext(String value) {
                System.out.println("get value is " + Integer.parseInt(value));
                request(1);
            }

            @Override
            protected void hookOnComplete() {
                System.out.println("Complete");
            }

            @Override
            protected void hookOnError(Throwable throwable) {
                System.err.println(throwable.getMessage());
            }
        };
    }
}

```

运行后输出如下：可以看到每次retry时，Flux中的数据都重新又被Subscriber消费了一次。所以，如果需要使用retry异常机制，应该保证Subscriber在消费数据的方法是幂等的，否则可能出现数据重复消费的情况，从而导致系统和业务异常。

![](/assets/Retying.png)

### 受检异常的处理

非受检异常会被Reactor传播，而受检异常必须被用户代码try catch，为了让受检异常被reactor的异常传播机制和异常处理机制支持，可以使用如下步骤处理：

1. 使用 Exceptions.propagate将受检异常包装为非受检异常并重新抛出传播出去。
2. onError、error回调等异常处理操作获取到异常之后，可以调用Exceptions.unwrap取得原受检的异常。

如下：

```java
public class CheckedExceptionHandle {
    public static void main(String[] args) {
        Flux<String> flux = Flux.just("abc", "def", "exception", "ghi")
                .map(s -> {
                    try {
                        return doSth(s);
                    } catch (FileNotFoundException e) {
                        // 包装并传播异常
                        throw Exceptions.propagate(e);
                    }
                });
        //abc、def正常打印，然后打印 参数异常
        flux.subscribe(System.out::println,
                e -> {
                    //获取原始受检异常
                    Throwable sourceEx = Exceptions.unwrap(e);
                    //判断异常类型并处理
                    if (sourceEx instanceof FileNotFoundException) {
                        System.err.println(((FileNotFoundException) sourceEx).getMessage());
                    } else {
                        System.err.println("Other exception");
                    }
                });

    }

    public static String doSth(String str) throws FileNotFoundException {
        if ("exception".equals(str)) {
            throw new FileNotFoundException("参数异常");
        } else {
            return str.toUpperCase();
        }
    }
}

```

输出如下：可以看到受检异FileNotFoundException被封装后抛出，然后再onErrorCallback中捕获并转换为真实异常类型。![](/assets/CheckedExceptionHandle.png)完整代码：https://github.com/pkpk1234/learn-reactor

