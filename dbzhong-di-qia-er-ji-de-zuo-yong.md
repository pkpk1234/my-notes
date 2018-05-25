# DB中笛卡尔积的作用

学习过数据库和SQL知识的程序员都应该知道笛卡尔积是什么，就是将两张表中数据进行组合然后返回。我一直觉得笛卡尔积没啥鸟用，只是学术上的东西，直到通宵加班时，遇到一个祖传系统的需求。

祖传系统中包含了一个表，里面是群组信息。需求中需要新增一个表，保存群组和角色key以及角色是否启用的标识。

简化后的表结构如下：

```SQL
mysql> describe t_group;
+-------+-------------+------+-----+---------+----------------+
| Field | Type        | Null | Key | Default | Extra          |
+-------+-------------+------+-----+---------+----------------+
| id    | int(11)     | NO   | PRI | NULL    | auto_increment |
| name  | varchar(45) | NO   |     | NULL    |                |
+-------+-------------+------+-----+---------+----------------+

mysql> describe t_group_roles;
+----------+-------------+------+-----+---------+-------+
| Field    | Type        | Null | Key | Default | Extra |
+----------+-------------+------+-----+---------+-------+
| group_id | int(11)     | NO   | PRI | NULL    |       |
| role_key | varchar(45) | NO   | PRI | NULL    |       |
| is_open  | tinyint(4)  | NO   |     | NULL    |       |
+----------+-------------+------+-----+---------+-------+
```

t\_group\_roles中包含了群组id，角色key和是否启用的标识，群组id和角色key构成联合主键。

测试人员插入了一条测试数据，根据业务规则每个群组对应的角色启用标识默认都是相同的，developer、cie、admin和sl都为1，表示启用，其他角色默认不启用。如下：

```SQL
mysql> select * from t_group_roles;
+----------+-----------+---------+
| group_id | role_key  | is_open |
+----------+-----------+---------+
|        1 | admin     |       1 |
|        1 | ba        |       0 |
|        1 | cie       |       1 |
|        1 | cmo       |       0 |
|        1 | developer |       1 |
|        1 | mde       |       0 |
|        1 | member    |       0 |
|        1 | pd        |       0 |
|        1 | QA        |       0 |
|        1 | sl        |       1 |
+----------+-----------+---------+
```

现在需要开发人员做的时，根据这个规则，将所有的group对应的数据都插入t\_group\_roles 表中。

实现这个需求有多种方法，最容易想到的就是写Java代码或者存储过程，获取所有群组信息，然后根据角色启用规则构造SQL语句，insert到t\_group\_roles中。

但是这个场景如果使用笛卡尔积，一个SQL就能实现。

首先构造查询语句，select from t\_group,t\_group\_roles 即可使笛卡尔积构造出每个群组及其对应的默认启用规则，由于存在联合主键，排除掉t\_group\_roles的群组即可，SQL语句如下：

```SQL

SELECT
  a.id,
  c.role_key,
  c.is_open
FROM t_group a,
  (SELECT
     b.role_key,
     b.is_open
   FROM t_group_roles b
   WHERE b.group_id = 1) c -- 获取角色启用规则
WHERE NOT exists(SELECT 1
                 FROM t_group_roles d
                 WHERE d.group_id = a.id); -- 不进行重复插入
```

查询出的部分数据如下：可以看到，id为1的群组不会参与构建，因为这个群组已经包含在t\_group\_roles中了。

![](/assets/select-g-r-is.png)

此时只需要再构建一个insert语句即可：



