# Project Reactor学习--调试类Operator

上一篇文件中介绍了Reactor中Operator的分类，现在开始介绍其中最简单的调试类Operator。

调试类Operator一般用于开发人员观察Publisher的运行步骤、运行时间等调试类信息。

### log

log Operator会想日志文件输出Publisher运行的每一步的信息。

下面是最简单的例子。

```java
public class LogOperator {
    public static void main(String[] args) {
        Flux.just(1, 2, 3, 4, 5)
                //日志记录详细的执行步骤
                .log()
                .subscribe();
    }
}

```

运行结果如下：



![](/assets/logOperator.png)

