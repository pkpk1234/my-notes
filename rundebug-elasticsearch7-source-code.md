# Idea启动或者debug elasticsearch7 源码 {#idea%E5%90%AF%E5%8A%A8%E6%88%96%E8%80%85debug-elasticsearch7-%E6%BA%90%E7%A0%81}

## 构建zip包 {#%E6%9E%84%E5%BB%BAzip%E5%8C%85}

首先构建出zip包，如下：

```
./gradlew assemble    

```

> 注意：es7需要本地安装docker、vagrant，并且JDK版本为11.

完成之后进入distribution/archives/zip/build/distributions/目录，我本地为/Users/jiamingli/scm/elasticsearch/distribution/archives/zip/build/distributions/，解压zip包。

## 修改elasticsearch.yml {#%E4%BF%AE%E6%94%B9elasticsearch.yml}

修改Users/jiamingli/scm/elasticsearch/distribution/archives/zip/build/distributions/elasticsearch-7.0.0-SNAPSHOT/config/elasticsearch.yml，添加node.name: node-1

## 修改server/build.gradle {#%E4%BF%AE%E6%94%B9server%2Fbuild.gradle}

修改server/build.gradle，修改compileOnly project\(':libs:plugin-classloader'\)  
为compile project\(':libs:plugin-classloader'\)

## 创建es.policy {#%E5%88%9B%E5%BB%BAes.policy}

在/Users/jiamingli/scm/elasticsearch/distribution/archives/zip/build/distributions/elasticsearch-7.0.0-SNAPSHOT/config目录下创建es.policy，输入如下内容：

```
grant {
  permission javax.management.MBeanTruxtPermission 
"register"
;
  permission javax.management.MBeanServerPermission 
"createMBeanServer"
;
  permission java.lang.RuntimePermission 
"createClassLoader"
;
};

```

## 创建idea运行配置 {#%E5%88%9B%E5%BB%BAidea%E8%BF%90%E8%A1%8C%E9%85%8D%E7%BD%AE}

如图  
![](/assets/es7-idea-new-app-run-config.png)

Main Class为org.elasticsearch.bootstrap.Elasticsearch，

VM参数为：

```
-Xms256m -Xmx256m -Des.path.home=/Users/jiamingli/scm/elasticsearch/distribution/archives/zip/build/distributions/elasticsearch-7.0.0-SNAPSHOT -Des.path.conf=/Users/jiamingli/scm/elasticsearch/distribution/archives/zip/build/distributions/elasticsearch-7.0.0-SNAPSHOT/config  -Dlog4j2.disable.jmx=true -Djava.security.policy=/Users/jiamingli/scm/elasticsearch/distribution/archives/zip/build/distributions/elasticsearch-7.0.0-SNAPSHOT/config/es.policy 

```

Use classpaht of module 为org.elasticsearch.bootstrap.Elasticsearch所在的module，此处为elasticsearch.server.main

## run或者debug {#run%E6%88%96%E8%80%85debug}

输出如下：  
![](/assets/local-es-run-sysout.png)

