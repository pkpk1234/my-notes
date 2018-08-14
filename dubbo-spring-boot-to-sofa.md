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

替换dependencies中的依赖

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



