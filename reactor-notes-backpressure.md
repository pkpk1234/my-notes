# Project Reactor学习--背压

Reactive Stream和Java 8 中Stream流的重要一个区别就是Reactive Stream支持背压（Back Pressure），

这也是Reactive Stream的主要卖点之一。

背压指的是当Subscriber请求的数据的访问超出它的处理能力时，Publisher限制数据发送速度的能力。

默认情况下，Subscriber会要求Publisher有多少数据推多少数据，能推多快就推多块。

本质上背压和TCP中的窗口限流机制比较类似，都是让消费者反馈请求数据的范围来进行流控。

