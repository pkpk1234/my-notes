# Reactor学习--核心接口简介

Reactor项目核心为reactor-core，一个基于Java8的响应式流标准实现，实现了reactive streams标准。

reactive streams标准核心接口有四个：

* Publisher&lt;T&gt;
* Subscriber&lt;T&gt;
* Subscription
* Processor&lt;T,R&gt;

其中最重要的接口为Publisher，代表了一个响应式的流。

Publisher核心实现为Flux和Mono。

## Flux

Flux代表了一个可以返回0..N个元素的响应式流。

![](/assets/Flux.png)

该流起始于subscribe信号，根据request信号持续返回数据，结束于completion信号或者error信号。

## Mono

Mono&lt;T&gt; 也是标准的Publisher&lt;T&gt;的实现，代表了一个可以返回0或1个元素的数据流。

![](/assets/mono.png)

该流接收到onComplete时返回一个元素并结束，接收到onError信号时返回0个元素并结束。

Mono可以用于表示无数据返回的异步流程，如等同于Runnable的概念，此时可以使用Mono&lt;Void&gt;。

