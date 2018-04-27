# Project Reactor学习--Operators

在Reactor中，一个Operator会给一个Publisher添加某种行为，并返回一个新的Publisher实例。还可以对返回的Publisher再添加Operator，以此类推，可以连成一个链条，原始数据从第一个Publisher沿着链条开始向下流动，连接中每个节点都会以某种方式去转换流入的数据。链条的终点是一个Subscriber，Subscriber以某种方式消费这些数据。

![](/assets/ops.png)

如果对Java 8 Stream比较熟悉，可以将Operator类比为Stream的中间操作，将subscribe类比为Stream的终结操作。

同时，如果对函数编程比较熟悉的话，也可以看出Operator、Subscriber都是典型的函数，接收输入进行计算给出输出，并且计算时并不会修改输入的值。

### 

### 最简单的例子

下面例子中使用filter获取100以内的能同时被2和7整除的整数，并逆序返回。

```java
public class SimplestOperator {
    public static void main(String[] args) {
        //源Flux实例
        Flux<Integer> sourceFlux = Flux.range(0, 100);
        //添加filter Operators之后，返回新的Flux实例
        Flux<Integer> filteredFlux = sourceFlux.filter(integer -> (integer % 2 == 0 && integer % 7 == 0));
        //添加sort Operators之后，返回新的Flux实例
        Flux<Integer> sortedFlux = filteredFlux.sort((j, k) -> {
            if (k < j) {
                return 1;
            } else if (k.equals(j)) {
                return 0;
            } else {
                return -1;
            }
        });
        //调用subscribe终结链条
        sortedFlux.subscribe(System.out::println);
    }
}
```



