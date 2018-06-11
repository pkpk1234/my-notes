# Project Reactor学习--使用Flux包装返回多个值的阻塞方法

上一节介绍了如何将返回单个值的阻塞方法包装为非阻塞方法的套路，现在来介绍一下如何将返回多个值的阻塞方法包装为非阻塞方法的套路。注意此处“返回多个值”指的是返回的值是一个数据流，比如一个List、Resultset，等包含多个元素的对象。

Project Reactor中的套路主要为Flux&lt;T&gt; create\(Consumer&lt;? super FluxSink&lt;T&gt;&gt; emitter\)方法，当数据到来时，调用emitter.next将数据推送给Subscriber;当发生异常时，调用emitter.error传递异常;当数据结束时，调用emitter.complete结束流。

例子：假设有书籍页面，左侧列出了所有的作者，中间主窗口列出了所有的书籍。数据全部来自数据库中，使用JDBC进行查询。

### 使用传统的阻塞编程

查询所有作者的DAO类：

```java
public class AuthorRepository {
    private static final String SELECTALLBOOKS = "SELECT id ,name FROM AUTHOR";

    public List<Author> getAllAuthors() {
        List<Author> result = new ArrayList<>(2);
        Connection connection = null;
        try {
            connection = H2DataSource.getInstance().getConnection();
            Statement statement = connection.createStatement();
            ResultSet allAthors = statement.executeQuery(SELECTALLBOOKS);
            while (allAthors.next()) {
                int id = allAthors.getInt(1);
                String name = allAthors.getString(2);
                result.add(new Author(id, name));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return result;
    }
}
```

查询所有数据的DAO类：

```java
public class BookRepository {

    private static final String SELECTALLBOOKS = "SELECT id ,title,author_id FROM BOOK";

    public List<Book> getAllBooks() {
        List<Book> result = new ArrayList<>(10);
        Connection connection = null;
        try {
            connection = H2DataSource.getInstance().getConnection();
            Statement statement = connection.createStatement();
            ResultSet allBooks = statement.executeQuery(SELECTALLBOOKS);
            while (allBooks.next()) {
                int id = allBooks.getInt(1);
                String title = allBooks.getString(2);
                int author_id = allBooks.getInt(3);
                result.add(new Book(id, title, author_id));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return result;
    }

}
```

调用者：

```java
public class BookPageService {

    private static Consumer<Book> bookConsumer = book -> System.out.println("\t" + book);
    private static Consumer<Author> authorConsumer = author -> System.out.println("\t" + author);

    public static void main(String[] args) throws InterruptedException {
        //初始化数据
        H2DataSource.getInstance();
        getPage();
    }

    private static void getPage() {
        System.out.println("----------------start get page----------------");
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        getAuthors();
        getBooks(bookConsumer);
        stopWatch.stop();
        System.out.println("getPage costs " + stopWatch.getTime() + " mills");
    }

    private static void getAuthors() {
        AuthorRepository authorRepository = new AuthorRepository();
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        authorRepository.getAllAuthors().stream().forEach(authorConsumer);
        stopWatch.stop();
        System.out.println("\tgetAuthors costs " + stopWatch.getTime() + " mills");
    }

    private static void getBooks(Consumer<Book> consumer) {

        BookRepository bookRepository = new BookRepository();
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        bookRepository.getAllBooks().stream().forEach(bookConsumer);
        stopWatch.stop();
        System.out.println("\tgetBooks costs " + stopWatch.getTime() + " mills");
    }
}
```

虽然getAuthor s和getBooks没有依赖关系，但是还是必须顺序执行。

### 使用Flux.create包装

异步查询所有作者的DAO类：

```java
public class AuthorAsyncRepository {
    private static final String SELECTALLBOOKS = "SELECT id ,name FROM AUTHOR";

    public Flux<Author> getAllAuthorsAsync() {
        Flux<Author> objectFlux = Flux.create(fluxSink -> {
            Connection connection = null;
            try {
                connection = H2DataSource.getInstance().getConnection();
                Statement statement = connection.createStatement();
                ResultSet allAthors = statement.executeQuery(SELECTALLBOOKS);
                while (allAthors.next()) {
                    int id = allAthors.getInt(1);
                    String name = allAthors.getString(2);
                    //推送数据
                    fluxSink.next(new Author(id, name));
                }
            } catch (SQLException e) {
                e.printStackTrace();
                //传播异常
                fluxSink.error(e);
            } finally {
                try {
                    if (connection != null) {
                        connection.close();
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
                //终止关闭
                fluxSink.complete();
            }
        });
        return objectFlux.subscribeOn(Schedulers.parallel(), false);
    }
}
```

同样的套路：

```java
public class BookAsyncRepository {
    private static final String SELECTALLBOOKS = "SELECT id ,title,author_id FROM BOOK";

    Flux<Book> getAllBooksAsync() {

        Flux<Book> objectFlux = Flux.create(fluxSink -> {
            Connection connection = null;
            try {
                connection = H2DataSource.getInstance().getConnection();
                Statement statement = connection.createStatement();
                ResultSet allBooks = statement.executeQuery(SELECTALLBOOKS);
                while (allBooks.next()) {
                    int id = allBooks.getInt(1);
                    String title = allBooks.getString(2);
                    int author_id = allBooks.getInt(3);
                    fluxSink.next(new Book(id, title, author_id));
                }
            } catch (SQLException e) {
                e.printStackTrace();
                fluxSink.error(e);
            } finally {
                try {
                    if (connection != null) {
                        connection.close();
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
                fluxSink.complete();
            }
        });
        return objectFlux.subscribeOn(Schedulers.parallel(), false);
    }
}
```

调用者需要等待两个异步方法完成后再退出：

```java
    private static void getPageAsync() throws InterruptedException {
        System.out.println("----------------start get page async----------------");
        CountDownLatch countDownLatch = new CountDownLatch(2);
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        AuthorAsyncRepository authorAsyncRepository = new AuthorAsyncRepository();
        Flux<Author> authorFlux = authorAsyncRepository
                .getAllAuthorsAsync().doOnComplete(() -> countDownLatch.countDown());
        authorFlux.subscribe(authorConsumer);

        BookAsyncRepository bookAsyncRepository = new BookAsyncRepository();
        Flux<Book> flux = bookAsyncRepository
                .getAllBooksAsync().doOnComplete(() -> countDownLatch.countDown());
        flux.subscribe(bookConsumer);
        //等待异步方法都完成
        countDownLatch.await();
        stopWatch.stop();
        System.out.println("getPage costs " + stopWatch.getTime() + " mills");
    }
```

运行结果如下：可以发现异步方法明显更快完成。

![](/assets/BookPageService.png)



