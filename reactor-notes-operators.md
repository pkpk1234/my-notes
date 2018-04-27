# Project Reactor学习--Operators

在Reactor中，一个Operator会给一个Publisher添加某种行为，并返回一个新的Publisher实例。还可以对返回的Publisher再添加Operator，以此类推，可以连成一个链条，原始数据从第一个Publisher沿着链条开始向下流动，连接中每个节点都会以某种方式去转换流入的数据。链条的终点是一个Subscriber，Subscriber以某种方式消费这些数据。

![](/assets/ops.png)

### 最简单的例子

下面例子中使用filter获取100以内的能同时被2和7整除的整数，并逆序返回。



