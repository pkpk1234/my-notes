# Reactor学习--Flux高级静态工厂方法

这里所谓的高级指的是静态工厂方法的输入一般为其他Publisher实例，和之前简单的静态工厂方法的输入相比高级一些。

这些静态工厂方法又可以细分为如下几类：

1. 接收多个已有Flux，将其组合为一个Flux。concat、merge
2. create方法，将已有的异步事件流，包装为Flux流
3. 接收一个Publisher，将其包装为Flux流。
4. 接收一个Supplier，延迟构造Publisher。
5. 构造一个周期性产生Long序列的Flux。



![](/assets/mergedFlux.png)



