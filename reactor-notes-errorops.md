# Project Reactor学习--异常处理Operator

之前的文章中介绍了Reactor中Operator的分类和日志相关的Operator，现在介绍下异常处理相关的Operator。

对于异常处理，Reactor除了默认的立刻抛出的处理方式之外，还提供三类处理方式：简单记录日志、fallback方法以及retry重试。

如果对Spring Cloud中的Hystrix比较熟悉，可以发现这也是Hystrix处理异常的方式，所以使用Reactor，我们应该也可以实现类似于断路器的功能，后续我们可以试试。

这里继续介绍异常处理Operator。

### 静态fallback值（StaticFallbackValue）

通过onErrorReturn方法加工返回的Publisher，提供了静态fallback值，即Publisher异常时，返回一个编译时写死的值，这也StaticFallbackValue中Static的意思。





