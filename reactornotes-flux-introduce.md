# Reactor学习--Flux接口简介

上一篇文章中简单介绍了Reactor中的核心接口，现在来看其中很复杂的一个实现Flux。

### Flux方法分类

打开Flux的Java Doc，可以看里面的方法居然多达362个（如果用我司的傻逼的代码扫描工具进行扫描，这个类绝对是质量红线）。这些方法看着多，但是如果我们对它们的功能进行分类，实际上也还在常人接收的范围之内。

方法大致分为

1. 静态工厂方法
2. 异常处理方法
3. 线程方法
4. 调测方法
5. Operator方法
6. subscribe方法

每个大类下又可以继续分出更细的分类。

### Publisher最基本特点

无论是Flux或者Mono还是其他的Publisher实现，都有一个相同的基本特点，就是在subscribe方法调用之前，绝对不会进行运算。

### 最简单的Flux例子

最简单的Flux可以使用静态工厂方法just\(T ... elements\)构造出来，然后使用subscribe\(Consumer&lt;? super T&gt; consumer\)让流启动，并使用consumer进行消费。如下：

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

运行以上的代码，程序会异常输出one、tow、three。

