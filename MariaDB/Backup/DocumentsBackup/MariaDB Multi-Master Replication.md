#MariaDB Multi-Master Replication

#####NoteTime: 2015.11.03 09:59 Tuesday


###Table Of Contents

1. [Operating System](#operating-system)
2. [Create MariaDB Repository](#create-mariadb-repository)
3. [Install MariaDB](#install-mariadb)
4. [Configuring MariaDB](#configuring-mariadb)
5. [Errors Occurred](#errors-occurred)
2. [Related Blog](#related-blog)

---

###Operating System
使用操作系統是 `Centos 7`，安裝命令是`yum`，服務管理命令是`systemctl`。

```
Last login: Tue Nov  3 10:31:41 2015
[root@localhost ~]# uname -r
3.10.0-229.14.1.el7.x86_64
[root@localhost ~]# cat /proc/version
Linux version 3.10.0-229.14.1.el7.x86_64 (builder@kbuilder.dev.centos.org) (gcc version 4.8.3 20140911 (Red Hat 4.8.3-9) (GCC) ) #1 SMP Tue Sep 15 15:05:51 UTC 2015
[root@localhost ~]# cat /etc/redhat-release
CentOS Linux release 7.1.1503 (Core) 
[root@localhost ~]# 
```

---

###Create MariaDB Repository
安裝[MariaDB](https://mariadb.org/ 'MariaDB')使用`yum`命令，創建`MariaDB Repository`。點擊[repo鏈接](https://downloads.mariadb.org/mariadb/repositories/ 'Setting up MariaDB Repositories')，依次選擇`CentOS`->`CentOS 7 (64-bit)`->`10.1`，repo格式如下
```
# MariaDB 10.1 CentOS repository list - created 2015-11-03 02:47 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```
在Server路徑`/etc/yum.repos.d/ `下創建MariaDB.repo，可使用`vi`或'vim'創建，將上面信息粘貼、保存。然後順序執行命令
```
  yum clean all
  yum makecache
```
生成yum緩存，即可`yum`進行安裝。

---

###Install MariaDB
&nbsp;&nbsp;MariaDB官網操作文檔[Installing MariaDB with yum](https://mariadb.com/kb/en/mariadb/yum/)

執行
```
yum install MariaDB-server MariaDB-client
```
安裝[Sysbench](https://github.com/akopytov/sysbench 'Sysbench GitHub')時會報如下錯
```
checking for mysql_config... no
configure: error: mysql_config executable not found
********************************************************************************
ERROR: cannot find MySQL libraries. If you want to compile with MySQL support,
       you must either specify file locations explicitly using
       --with-mysql-includes and --with-mysql-libs options, or make sure path to
       mysql_config is listed in your PATH environment variable. If you want to
       disable MySQL support, use --without-mysql option.
********************************************************************************
```
需再安裝
```
yum install MariaDB-devel
```

安裝完成後，啓動mysql服務，設置爲開機啓動
```
systemctl start mysql
systemctl enable mysql
```
\*注：有些MariaDB版本的服務名可能不是`mysql`，而是`mariadb.service`

提高MariaDB安全
```
mysql_secure_installation
```
&nbsp;&nbsp;MariaDB官方文檔說明[mysql_secure_installation](https://mariadb.com/kb/en/mariadb/mysql_secure_installation/)

---

###Configuring MariaDB
*註：以下操作分別在兩臺Server上操作*

修改MariaDB配置文件`/etc/my.cnf`
```
[mysqld]
server-id=數值    #server-id唯一，不能相同
log-bin=mysql-bin
binlog_format=row
log-slave-updates
sync_binlog=1
auto_increment_increment=1
auto_increment_offset=數值  #第一台設置爲1，第二台設置爲2
slave_skip_errors=1007,1008
```
登入MariaDB
```
mysql -u <username> -p #username是用戶名，如用戶名爲root
```
創建用戶並授權
*以用戶帳號：'repl'@'%' 密碼：repl12345爲例*
```
MariaDB [(none)]> grant replication slave,replication client on *.* to 'repl'@'%' identified by 'repl12345';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> select User,Host from mysql.user;
+------+-----------+
| User | Host      |
+------+-----------+
| repl | %         |
| root | 127.0.0.1 |
| root | ::1       |
| root | localhost |
+------+-----------+
4 rows in set (0.00 sec)

MariaDB [(none)]>
```

查看`Master Status`
```
MariaDB [(none)]> show master status\G
*************************** 1. row ***************************
            File: mysql-bin.000166
        Position: 497942023
    Binlog_Do_DB:
Binlog_Ignore_DB:
1 row in set (0.00 sec)

MariaDB [(none)]>
```

停止`slave`
```
MariaDB [(none)]> stop slave;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> 
```

執行`CHANGE MASTER TO`命令(以其中一臺Server爲例)
```
CHANGE MASTER TO MASTER_HOST='54.187.219.96',MASTER_USER='repl', MASTER_PASSWORD='repl12345', MASTER_LOG_FILE='mysql-bin.000166', MASTER_LOG_POS=497942023;
```
>註釋：
>MASTER_HOST：另一Server的主機地址
>MASTER_USER：另一Server的用戶帳號
>MASTER_PASSWORD：另一Server的用戶密碼
>MASTER_LOG_FILE：另一Server “show master status”中的File值
>MASTER_LOG_POS：另一Server “show master status”中的Position值

&nbsp;&nbsp;MariaDB官方文檔[CHANGE MASTER TO](https://mariadb.com/kb/en/mariadb/change-master-to/)

啓動`slave`
```
MariaDB [(none)]> stop slave;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> 
``` 

查看`slave status`
```
MariaDB [(none)]> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.30.1.60
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000166
          Read_Master_Log_Pos: 497942023
               Relay_Log_File: ip-172-30-1-58-relay-bin.000002
                Relay_Log_Pos: 681
        Relay_Master_Log_File: mysql-bin.000166
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 497942023
              Relay_Log_Space: 988
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 2
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
                   Using_Gtid: No
                  Gtid_IO_Pos: 
      Replicate_Do_Domain_Ids: 
  Replicate_Ignore_Domain_Ids: 
                Parallel_Mode: conservative
1 row in set (0.00 sec)

MariaDB [(none)]
```
如果創建成功，即可進行數據寫入測試，看是否會同步。

---

###Errors Occurred
*show slave status*
>Error1

```
Last_IO_Errno: 2003
Last_IO_Error: error connecting to master 'repl@52.89.216.33:3306' - retry-time: 60  retries: 86400  message: Can't connect to MySQL server on '52.89.216.33' (110 "Connection timed out")
```
連接master server失敗，查看網路是否通暢，Mysql3306端口是否允許，帳號密碼是否準確，是否允許遠程連接，設置是否準確...
>Error2

```
Last_SQL_Errno: 1008
Last_SQL_Error: Error 'Can't drop database 'apple'; database doesn't exist' on query. Default database: 'apple'. Query: 'drop database apple'
```
參考Blog[Problem Mysql in master/master replication](https://www.howtoforge.com/community/threads/problem-mysql-in-master-master-replication.64609/)

>Error3

```
Last_SQL_Errno: 1146
Last_SQL_Error: Error executing row event: 'Table 'sbtest.sbtest2' doesn't exist'
```

>Error4

```
Last_SQL_Errno: 1062
Last_SQL_Error: Error 'Duplicate entry '14' for key 'PRIMARY'' on query. Default database: 'sbtest'. Query: 'INSERT INTO sbtest18 (id, k, c, pad) VALUES (0, 593360, '87255848296-55692744523-54185831398-62879904771-04740888740-94686502050-32461868355-46389166893-44079937452-32331981230', '40296074541-11662672902-80614572470-88347339764-93776778804')'
```
---
出現此類報錯時(測試環境)，個人做法是重新進行如下操作
```
stop slave
change master to ...
start slave
```





###Related Blog
* [Setting Up Replication](https://mariadb.com/kb/en/mariadb/setting-up-replication/ 'Setting Up Replication')
* [MariaDB(MySQL) Master-Master Replication](http://msutic.blogspot.com/2015/02/mariadbmysql-master-master-replication.html 'MariaDB(MySQL) Master-Master Replication')
* [Multi-source Replication](https://mariadb.com/kb/en/mariadb/multi-source-replication/ 'Multi-source Replication')
* [Global Transaction ID](https://mariadb.com/kb/en/mariadb/global-transaction-id/ 'Global Transaction ID')



###[ToTop](#table-of-contents)

#####NoteTime: 2015.11.03 12:41 上海.慧谷