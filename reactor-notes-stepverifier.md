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
2. 多次调用expectNext、expectNextMatches方法设置断言，验证Publisher每一步产生的数据是否符合预期。
3. 调用expectComplete、expectError设置断言，验证Publisher是否满足正常结束或者异常结束的预期。
4. 调用verify方法启动测试。

##### 最简单的例子

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

```java
StepVerifier.create(Flux.just("one", "two","three"))
                //依次校验每一步的数据是否符合预期
                .expectNext("one")
                .expectNext("two")
                //不满足预期，抛出异常
                .expectNext("Five")
                //校验Flux流是否按照预期正常关闭
                .expectComplete()
                //启动
                .verify();
```

##### 输出：Exception in thread "main" java.lang.AssertionError: expectation "expectNext\(Five\)" failed \(expected value: Five; actual value: three\) 异常信息中输出了断言失败的原因。![](/assets/AssertionError.png)

##### 异常断言

可以使用expectError方法对抛出的异常进行断言。

```java
public class ExpectError {
    public static void main(String[] args) {
        Flux<Integer> integerFluxWithException = Flux.just(
                new DivideIntegerSupplier(1, 2),
                new DivideIntegerSupplier(8, 2),
                new DivideIntegerSupplier(20, 10),
                //异常数据,抛出ArithmeticException
                new DivideIntegerSupplier(1, 0),
                new DivideIntegerSupplier(2, 2)
        ).map(divideIntegerSupplier -> divideIntegerSupplier.get());

        StepVerifier.create(integerFluxWithException)
                .expectNext(1 / 2)
                .expectNext(8 / 2)
                .expectNext(20 / 10)
                //校验异常数据，可以判断抛出的异常的类型是否符合预期
                .expectError(ArithmeticException.class)
                .verify();
    }
}
```

##### assertNext方法、expectNextMatches方法、thenConsumeWhile方法

之前的测试中，Publisher中数据的值都是确定的，所以可以使用expectNext进行判断，但是很多场景下，数据的值不完全确定，只知道数据的特征或者数据量太大，无法一一写出具体的值，此时assertNext方法、expectNextMatches方法、thenConsumeWhile方法可以满足此类需求。

assertNext方法需要利用第三方断言库，如junit断言进行校验，使用此方法，即可将StepVerifier集成到junit中。

expectNextMatches和thenConsumeWhile则直接传入Predicate进行判断。

thenConsumeWhile会持续获取并判断数据，直到不满足Predicate为止。

如下例子：

```java
public class ThenConsumeWhile {
    public static void main(String[] args) {
        //素数数据流
        Flux<Integer> primes = Flux.range(1, 100)
                .filter(integer -> isPrime(integer));

        StepVerifier.create(primes)
                //素数肯定无法整除8
                .thenConsumeWhile(integer -> (integer % 8 != 0))
                .verifyComplete();

    }

    private static boolean isPrime(int n) {
        if (n < 2) {
            return false;
        }
        if (n == 2) {
            return true;
        }
        if (n % 2 == 0) {
            return false;
        }
        for (int i = 3; i < n; i += 2) {

            if (n % i == 0) {
                return false;
            }
        }
        return true;
    }

}
```

如下例子集成junit

```java
public class TestAssertNext {
    @Test
    public void test() {
        Flux<Integer> just = Flux.just(1, 2, 3);
        StepVerifier.create(just)
                .assertNext(integer -> {
                    assertEquals(1, integer.intValue());
                }).assertNext(integer -> {
            assertEquals(2, integer.intValue());
        }).assertNext(integer -> {
            assertEquals(3, integer.intValue());
        }).verifyComplete();
    }

}
```

运行结果如下：

![](/assets/assetNext.png)

完整代码：https://github.com/pkpk1234/learn-reactor

