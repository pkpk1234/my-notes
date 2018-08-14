# dubbo-spring-boot微服务迁移sofa框架和蚂蚁金融云简要步骤

## 修改服务提供者

### 修改POM

将parent由dubbo-spring-boot-parent修改为sofaboot-enterprise-dependencies，注意artifact中的enterprise，这个依赖才能上蚂蚁金融云，开源的不行。

```xml
     <parent>
-        <groupId>com.alibaba.boot</groupId>
-        <artifactId>dubbo-spring-boot-parent</artifactId>
-        <version>0.2.1-SNAPSHOT</version>
+        <groupId>com.alipay.sofa</groupId>
+        <artifactId>sofaboot-enterprise-dependencies</artifactId>
+        <version>2.3.2</version>
     </parent>
```

替换dependencies中对dubbo-spring-boot-starter的依赖为rpc-enterprise-sofa-boot-starter，再根据需要引入spring-boot相关的starter依赖

```xml
-        <!-- Spring Boot dependencies -->
+        <!-- sofa rpc dependency -->
         <dependency>
-            <groupId>org.springframework.boot</groupId>
-            <artifactId>spring-boot-starter</artifactId>
+            <groupId>com.alipay.sofa</groupId>
+            <artifactId>rpc-enterprise-sofa-boot-starter</artifactId>
         </dependency>

         <dependency>
-            <groupId>${project.groupId}</groupId>
-            <artifactId>dubbo-spring-boot-starter</artifactId>
-            <version>${project.version}</version>
+            <groupId>org.springframework</groupId>
+            <artifactId>spring-core</artifactId>
+        </dependency>

+        <dependency>
+            <groupId>org.springframework</groupId>
+            <artifactId>spring-context</artifactId>
+        </dependency>

+        <dependency>
+            <groupId>org.springframework.boot</groupId>
+            <artifactId>spring-boot-starter-logging</artifactId>
         </dependency>

         <dependency>
-            <groupId>com.alibaba.boot</groupId>
-            <artifactId>dubbo-spring-boot-actuator</artifactId>
-            <version>${project.version}</version>
+            <groupId>org.springframework.boot</groupId>
+            <artifactId>spring-boot-starter-actuator</artifactId>
         </dependency>
```

### 修改服务实现，去掉dubbo-spring-boot注解

```java
-import com.alibaba.boot.dubbo.demo.consumer.model.User;
-import com.alibaba.dubbo.config.annotation.Service;

-@Service(
-    version = "${demo.service.version}",
-    application = "${dubbo.application.id}",
-    protocol = "${dubbo.protocol.id}",
-    registry = "${dubbo.registry.id}")
+
 public class UserRoleServiceImpl implements UserRoleService {...
```

### 新建META-INF.&lt;service-name&gt;目录和service-name.xml文件

![](/assets/sofa-service.xml.png)

在role-service.xml中配置服务发布:

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:sofa="http://schema.alipay.com/sofa/schema/slite"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
        http://schema.alipay.com/sofa/schema/slite http://schema.alipay.com/sofa/slite.xsd http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">

    <bean id="roleService" class="com.alibaba.boot.dubbo.demo.provider.service.UserRoleServiceImpl"/>

    <!-- Publish bolt service -->
    <sofa:service interface="com.alibaba.boot.dubbo.demo.consumer.UserRoleService" ref="roleService">
        <sofa:binding.bolt/>
    </sofa:service>
</beans>
```

### 修改spring-boot启动类，import上一步编写的xml

```xml
+@ImportResource({"classpath*:META-INF/role-service/*.xml"})
+@SpringBootApplication
public class UserRoleServiceApp { ...
```

### 修改application.properties

将dubbo相关配置全部删除，修改为sofa对应的配置，注意最后蚂蚁中间件的配置，必须配置这几个参数微服务才能正常运行在蚂蚁金融云上。

```xml
# Spring boot application
spring.application.name=dubbo-user-role-service

-dubbo.application.id=dubbo-user-role-service
-dubbo.application.name=dubbo-user-role-service
-dubbo.application.qos.port=22223
-dubbo.application.qos.enable=true
-
-dubbo.protocol.id=zookeeper
-dubbo.protocol.name=dubbo
-dubbo.protocol.port=20082
-dubbo.protocol.status=server
-
-dubbo.registry.id=my-registry
-dubbo.registry.address=localhost:2181
-dubbo.registry.protocol=zookeeper
-dubbo.registry.timeout=30000
-dubbo.protocol.threads=10
-
-management.endpoint.dubbo.enabled=true
-management.endpoint.dubbo-shutdown.enabled=true
-management.endpoint.dubbo-configs.enabled=true
-management.endpoint.dubbo-services.enabled=true
-management.endpoint.dubbo-references.enabled=true
-management.endpoint.dubbo-properties.enabled=true
-management.health.dubbo.status.defaults=memory
-management.health.dubbo.status.extras=load,threadpool
-
+
+logging.level.xxx.xxx.xxx=INFO
+
+logging.path=./logs
+
+run.mode=NORMAL
+com.alipay.env=shared
+com.alipay.instanceid=xxxxxx
+com.antcloud.antvip.endpoint=xxx.xxx.xxx.xxx
+com.antcloud.mw.access=xxxxxxxx
+com.antcloud.mw.secret=xxxxxxxx
```

## 修改服务消费者

服务消费者首先按照上面的步骤进行修改，然后再修改服务引用方式。

```xml
    <sofa:reference interface="com.alibaba.boot.dubbo.demo.consumer.UserRoleService" id="userRoleService">
        <sofa:binding.bolt>
            <sofa:global-attrs timeout="15000"/>
        </sofa:binding.bolt>
    </sofa:reference>
```

```java
-@Service(
-    version = "${demo.service.version}",
-    application = "${dubbo.application.id}",
-    protocol = "${dubbo.protocol.id}",
-    registry = "${dubbo.registry.id}")
 public class UserServiceImpl implements UserService {
   @Autowired private UserDAO userDAO;

-  @Reference(
-          version = "${demo.service.version}",
-          application = "${dubbo.application.id}",
-          registry = "${dubbo.registry.id}")
-  private UserRoleService userRoleService;
-
+  @Autowired private UserRoleService userRoleService;
```

到此为止，dubbo-spring-boot即迁移到sofa下，并且可以部署到蚂蚁金融云上。

