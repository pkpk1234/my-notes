# dubbo-spring-boot迁移Sofa步骤

## 修改POM

将parent由dubbo-spring-boot-parent修改为sofaboot-enterprise-dependencies

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







