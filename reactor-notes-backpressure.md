# Project Reactor学习--背压

Reactive Stream和Java 8 中Stream流的重要一个区别就是Reactive Stream支持背压（Back Pressure）。

背压指的是当Subscriber请求的数据的访问超出它的处理能力时，Publisher限制数据发送速度的能力。

默认情况下，Subscriber会要求Publisher有多少数据推多少数据，能推多快就推多块。

背压的作用是当消费者处理能力不足时，让生产者缓下来，不让消费者被压垮。

Reactor提供了多种背压策略。Subscriber使用request反馈消费速度。

buffer方法

在Subscriber无法及时消费时，现将数据缓存起来，避免压死Subscriber。

