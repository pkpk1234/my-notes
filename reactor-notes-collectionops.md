# Project Reactor学习--集合Operator

Reactor中，集合类Operator应用于包含多个元素的Flux上，功能和Java 8 Stream中同名函数基本一致。可以分为如下几类：

1. 判断元素是否满足条件，如all、any、hasElement等。
2. 过滤器filter。
3. 排序sort。
4. 去重distinct、distinctUntilChanged。
5. 映射map、flatMap。
6. reduce。
7. 转换求值并结束Flux的操作，如collect、collectList、count等操作。

### all

all接收一个Predicate类型的参数，使用该Predicate对Flux中所有的元素进行判断，如果所有元素都满足Predicate的判断，则返回true，否则返回false。判断时使用短路策略，即如果有一个元素不满足要求，立刻返回false，后面的元素不用再判断了。

例子如下：

```java
public class AllOperator {
    public static void main(String[] args) {
        Flux<Integer> flux = Flux.range(0, 10).log();
        Predicate<Integer> allSmallerThan10 = integer -> integer < 10;
        flux.all(allSmallerThan10).log().subscribe();

        Predicate<Integer> allSmallerThan5 = integer -> integer < 5;
        flux.all(allSmallerThan5).log().subscribe();
    }
}
```

运行时注意观察flux.range的onNext，注意第二次subscribe时，数据在onNext\(5\)之后就不再满足要求，立刻短路掉了。

![](/assets/all.png)

### any

any和all类似，区别在于any只要求至少有一个元素满足Predicate的要求即返回true。判断时也使用短路策略，即只要发现有一个元素满足要求，立刻返回ture，不再对剩余元素进行判断。

### hasElement

这个操作对于null元素返回false，同时基于any。

hasElement\(T value\) 等价于any\(t -&gt; Objects.equals\(value, t\)\)。

### filter和filterWhen

filter接收一个Predicate参数，使用这个Predicate对元素进行判断，不满足条件的元素都会被过滤掉，满足条件的元素会立刻触发emitted返回给Subscriber。

filterWhen的过程类似，不过将emitted这一步修改为放入buffer中，直到流结束将整个buffer返回。

看代码更直观：

```java
public class Filter {
    public static void main(String[] args) {
        Flux<Integer> just = Flux.range(1, 10);

        /**
         * filter的过程为：
         *    req(1)---> <predicate>--true-->emitted返回元素给Subscriber-->req(1)... 不断循环这个过程直到Flux结束
         *                    |
         *                    false
         *                    |-->drop-->req(1)...
         */
        filter(just);

        /**
         * filterWhen的过程类似，不过将emitted这一步修改为
         * 放入buffer中，直到流结束将整个buffer返回
         */
        filterWhen(just);
    }

    private static void filter(Flux<Integer> just) {
        StepVerifier.create(just.filter(integer -> integer % 2 == 0).log())
                .expectNext(2)
                .expectNext(4)
                .expectNext(6)
                .expectNext(8)
                .expectNext(10)
                .verifyComplete();
    }

    private static void filterWhen(Flux<Integer> just) {
        StepVerifier.create(just
                .filterWhen(v -> Mono.just(v % 2 == 0)).log())
                //一次性返回
                .expectNext(2, 4, 6, 8, 10)
                .verifyComplete();

    }
}
```



