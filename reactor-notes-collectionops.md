# Project Reactor学习--集合Operator

Reactor中，集合类Operator应用于包含多个元素的Flux上。可以分为如下几类：

1. 判断元素是否满足条件，如all、any、hasElement等。
2. 过滤器filter。
3. 排序sort。
4. 去重distinct、distinctUntilChanged。
5. 映射map、flatMap。
6. 转换求值并结束Flux的操作，如collect、collectList、count等操作。

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



