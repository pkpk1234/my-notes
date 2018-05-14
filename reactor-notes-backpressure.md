# Project Reactor学习--背压

默认情况下，Subscriber会要求Publisher push as many data as it can，此时有可能出现Subscriber无法及时处理的场景。

背压的作用是当消费者处理能力不足时，让生产者缓下来，不让消费者被压垮。

Reactor提供了多种背压策略。Subscriber使用request反馈消费速度。

buffer方法

在Subscriber无法及时消费时，现将数据缓存起来，避免压死Subscriber。

