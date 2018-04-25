# Project Reactor学习--Flux线程相关方法

Flux号称是异步的事件流，Java里面单线程是没法异步的，同时号称底层是否使用并发对上层是透明的，所以Flux具有若干切换代码执行上下文（其实就是线程）的方法。

Reactor使用reactor.core.scheduler.Scheduler对执行一个异步执行的操作进行抽象，底层使用ExecutorService或者ScheduledExecutorService执行这个异步操作。

Reactor提供了多种Scheduler实现，并提供了工厂类reactor.core.scheduler.Schedulers方便开发者使用。

Flux则提供了publishOn和subscribeOn两个方法设置要使用的Scheduler。

上代码比较直观：



