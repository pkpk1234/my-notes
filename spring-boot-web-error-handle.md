# Spring Boot WebMvc的异常处理

默认情况下，Spring Boot Web环境下，如果有异常发生，异常会以如下两种方法返回给调用者。

#### 使用浏览器时

### 此时浏览器会显示一个Whitelabel Error Page页面，这个页面会显示异常相关的简单信息。如下所示，可以看到500的响应码，请求的path，请求的时间，以及异常信息。![](/assets/default-exception-white-page.png)

### 使用App访问

常见的App和服务器交互一般使用json格式，如下所示：异常json中也包含了请求的path，请求时间，异常信息。![](/assets/default-exception-json.png)

