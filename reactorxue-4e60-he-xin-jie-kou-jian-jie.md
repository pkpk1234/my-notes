# Reactor学习--核心接口简介

Reactor项目核心为reactor-core，一个基于Java8的响应式流标准实现，实现了reactive streams标准。

reactive streams标准核心接口有四个：

* Publisher&lt;T&gt;
* Subscriber&lt;T&gt;
* Subscription
* Processor&lt;T,R&gt;

Reactor实现了这四类接口。

Publisher核心实现为Flux和Mono。

Flux代表了一个可以返回0..N个元素的响应式流。

Mono代表了一个可以返回0或者1个元素的响应式流。

