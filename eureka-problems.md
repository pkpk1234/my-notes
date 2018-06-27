# Eureka使用时需要注意的问题

在Java微服务最流行的Spring-Cloud-NetfilixOSS全家桶中，Eureka处于核心地位，提供服务注册和服务发现的功能，所以一旦Eureka出了问题，整个微服务群都会处于瘫痪状态。

下面的问题是我在使用Eureka时遇到的一些问题。

### 问题一：Eureka Client过早进行服务注册

当微服务启动时，

spring-cloud-netfilix-eureka-client/spring.factory--&gt;EurekaDiscoveryClientConfiguration--&gt;EurekaAutoServiceRegistration--&gt;EurekaServiceRegistry\#registry\(\)

### 问题二：微服务异常关闭

很多时候，运维人员或者系统使用kill -9关闭微服务，而不是使用正常的方式进行关闭，此时被关闭的微服务的Eureka Client无法向Eureka Server发送canel请求，如果异常关闭多个微服务，会引起Eureka Server的自我保护。此时会导致已经下线的服务被保留在Eureka Server中，从而导致客户端调用到已下线的服务。

