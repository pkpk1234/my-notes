# Project Reactor学习--背压

背压的作用是当消费者处理能力不足时，让生产者缓下来，不让消费者被压垮。

Reactor提供了多种背压策略。

buffer方法

在Subscriber无法及时消费时，现将数据缓存起来，避免压死Subscriber。

