# Reactor学习--测试

前面的例子中都使用了System.out.println方法输出数据的方式来验证程序。这种方式需要人工去验证结果是否正确并且无法在单元测试中使用。Reactor为测试准备了相关的工具库reactor-test。

引入reactor-test依赖，我们这里在main中使用reactor-test中工具类，所以scope为默认即可。

```
<dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-test</artifactId>
</dependency>
```

### StepVerifier

reactor-test核心接口为StepVerifier，该接口提供了若干的静态工厂方法，从待测试的Publisher创建测试步骤。测试步骤被抽象为状态机接口FirstStep、Step和LastStep，分别代表了测试的初始阶段、中间阶段和最终阶段。这些Step上都具有一系列的expect和assert方法，用于测试当前状态是否符合预期。

使用StepVerifier测试Publisher的套路如下：

1. 首先将已有的Publisher传入StepVerifier的create方法。
2. 多次调用expectNext、expectNextMatches方法验证Publisher每一步产生的数据是否符合预期。
3. 可选：调用thenRequest
4. 调用expectComplete、expectError验证Publisher是否满足正常结束或者异常结束的预期。
5. 调用verify方法启动测试。

例子：

```java
public class SimpleExpect {
    public static void main(String[] args) {
        StepVerifier.create(Flux.just("one", "two","three"))
                //依次校验每一步的数据是否符合预期
                .expectNext("one")
                .expectNext("two")
                .expectNext("three")
                //校验Flux流是否按照预期正常关闭
                .expectComplete()
                //启动
                .verify();
    }
}
```

如果Publisher满足测试的断言，StepVerifier会正常结束。如果不满足，则会抛出AssertionError异常，如下：



