# NIO ServerSocketChannel监听端口问题

今天晓风轻遇到了一个问题，nodejs和tomcat8同时监听同一个网卡的同一个端口，监听不会抛出异常，并且访问该端口，其中某个程序可以正常响应。关闭正则响应的程序，另外一个程序会接替被关闭的程序进行响应。

其实这是NIO监听端口的机制造成的。ServerSocketChannel监听端口时，如果该端口已经被监听，ServerSocketChannel不会抛出异常，而是继续执行。这样就导致了程序看上去正常启动了，但是实际上并没有成果监听。

## 重现问题

首先使用ServerSocketChannel编写一个Server，监听8989端口，如下：

```java
public class NIOServer {
    public static void main(String[] args) {
        ServerSocketChannel serverSocketChannel = null;
        try {
            serverSocketChannel = ServerSocketChannel.open();
            serverSocketChannel.bind(new InetSocketAddress("127.0.0.1", 8989));

            serverSocketChannel.configureBlocking(false);
            Selector selector = Selector.open();
            serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
            ByteBuffer buffer = ByteBuffer.allocate(64);
            System.out.println("server started");

            while (true) {
                selector.select();
                Iterator<SelectionKey> selectKeyIt = selector.selectedKeys().iterator();
                ... ... 省略 ... ...
                
```

在进行selector循环之前，输出server started日志。

执行nc -l 8989，提前监听端口8989。

![](/assets/nc)

然后运行



