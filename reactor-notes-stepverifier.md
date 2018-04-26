# Reactor学习--测试

前面的例子中都使用了System.out.println方法输出数据的方式来验证程序。这种方式需要人工去验证结果是否正确并且无法在单元测试中使用。Reactor为测试准备了相关的工具。

首先引入reactor-test依赖，我们这里在main方法中使用reactor-test中工具类，所以scope为默认即可。

```
<dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-test</artifactId>
</dependency>
```



