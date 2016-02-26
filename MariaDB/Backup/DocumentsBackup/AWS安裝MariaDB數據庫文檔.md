#AWS安裝MariaDB數據庫文檔


撰寫人：馬雪東
撰寫時間：2015.11.04 Wensday

---


###Table Of Contents
1. [Server Info](#server-info)
2. [Create MariaDB Repository](#create-mariadb-repository)
3. [Install MariaDB](#install-mariadb)
4. [Initialize MariaDB](#initialize-mariadb)
5. [Change Database Data Path](#change-database-data-path)
6. [Create User Account](#create-user-account)
7. [Configure MariaDB](#configure-mariadb)


###Server Info
>**Host IP**:  `54.223.87.233`
**Username**: `root`
**Password**:  `1qaz2wsx`

數據庫文件路徑更改到`/mnt`下
```
[root@ip-20-0-0-22 ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1       15G  2.1G   13G  15% /
devtmpfs        2.0G   60K  2.0G   1% /dev
tmpfs           2.0G     0  2.0G   0% /dev/shm
/dev/xvdf        94G   60M   89G   1% /mnt
[root@ip-20-0-0-22 ~]#
```

---

###Create MariaDB Repository
AWS使用的CentOS內核是6不是7，故repo需選擇`CentOS6 (64bit)`。安裝[MariaDB](https://mariadb.org/ 'MariaDB')使用`yum`命令。

創建`MariaDB Repository`。點擊[repo鏈接](https://downloads.mariadb.org/mariadb/repositories/ 'Setting up MariaDB Repositories')，依次選擇`CentOS`->`CentOS 6 (64-bit)`->`10.0`，生成如下信息
```
# MariaDB 10.0 CentOS repository list - created 2015-11-04 03:52 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos6-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

**註**：`MariaDB Galera Cluster`當前GA版本是`10.0.21`，Release date: 18 Aug 2015，故需選擇`10.0`倉庫。


在Server路徑`/etc/yum.repos.d/ `下創建MariaDB.repo
```
[root@ip-20-0-0-22 ~]# cd /etc/yum.repos.d/ && ls -lh
total 24K
-rw-r--r-- 1 root root  668 Feb 12  2015 amzn-main.repo
-rw-r--r-- 1 root root  324 Feb 12  2015 amzn-nosrc.repo
-rw-r--r-- 1 root root  686 Feb 12  2015 amzn-preview.repo
-rw-r--r-- 1 root root  686 Feb 12  2015 amzn-updates.repo
-rw-r--r-- 1 root root  957 Mar  1  2013 epel.repo
-rw-r--r-- 1 root root 1.1K Mar  1  2013 epel-testing.repo
[root@ip-20-0-0-22 yum.repos.d]# 
```
可使用`vi`或'vim'創建，保存、退出。
```                                                               
[root@ip-20-0-0-22 yum.repos.d]# cat MariaDB.repo 
# MariaDB 10.1 CentOS repository list - created 2015-11-04 03:39 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos6-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
[root@ip-20-0-0-22 yum.repos.d]# 
```

然後順序執行命令
```
  yum clean all
  yum makecache
```
生成yum緩存，即可`yum`進行安裝。

---

###Install MariaDB
**註**：MariaDB官方文檔[Installing MariaDB with yum](https://mariadb.com/kb/en/mariadb/yum/#installing-mariadb-with-yum)

```
yum install MariaDB-server MariaDB-client MariaDB-devel
```

安裝完成後，可使用`whereis`命令查看
```
[root@ip-20-0-0-22 yum.repos.d]# whereis mysql
mysql: /usr/bin/mysql /usr/lib64/mysql /usr/include/mysql /usr/share/mysql /usr/share/man/man1/mysql.1.gz
```

---

###Initialize MariaDB
啓動`mysql服務`並設置爲開機啓動
```
service mysql start 或 /etc/init.d/mysql start
chkconfig mysql on
```

操作過程：
```
[root@ip-20-0-0-22 yum.repos.d]# service mysql start
Starting MySQL. SUCCESS! 
[root@ip-20-0-0-22 yum.repos.d]# chkconfig mysql on
[root@ip-20-0-0-22 yum.repos.d]# service mysql status
 SUCCESS! MySQL running (30564)
[root@ip-20-0-0-22 yum.repos.d]# 
```

---

**提高MariaDB安全**
```
mysql_secure_installation
```
MariaDB官方文檔[mysql_secure_installation](https://mariadb.com/kb/en/mariadb/mysql_secure_installation/)

>禁止root遠程登錄,設置密碼爲`1qaz2wsx`;
移除匿名用戶賬戶
移除test數據庫

---

###Change Database Data Path

參考Blog[Change data directory – MariaDB 10.0.x](http://it.tuxie.eu/?p=527)

MariaDB默認數據庫資料存放路徑是`/var/lib/mysql`,現需將數據存放路徑放置在`/mnt`下。

```
[root@ip-20-0-0-22 ~]# cd /var/lib/mysql/
[root@ip-20-0-0-22 mysql]# pwd
/var/lib/mysql
[root@ip-20-0-0-22 mysql]# ls -lh
total 109M
-rw-rw---- 1 mysql mysql  16K Nov  4 12:04 aria_log.00000001
-rw-rw---- 1 mysql mysql   52 Nov  4 12:04 aria_log_control
-rw-rw---- 1 mysql mysql  12M Nov  4 12:07 ibdata1
-rw-rw---- 1 mysql mysql  48M Nov  4 12:07 ib_logfile0
-rw-rw---- 1 mysql mysql  48M Nov  4 12:04 ib_logfile1
-rw-r----- 1 mysql root  1.4K Nov  4 12:07 ip-20-0-0-22.err
-rw-rw---- 1 mysql mysql    6 Nov  4 12:07 ip-20-0-0-22.pid
-rw-rw---- 1 mysql mysql    0 Nov  4 12:07 multi-master.info
drwx--x--x 2 mysql mysql 4.0K Nov  4 12:04 mysql
srwxrwxrwx 1 mysql mysql    0 Nov  4 12:07 mysql.sock
drwx------ 2 mysql mysql 4.0K Nov  4 12:04 performance_schema
[root@ip-20-0-0-22 mysql]#
```

`/var/lib/mysql`目錄rwx權限及屬主、屬組。
```
[root@ip-20-0-0-22 mysql]# cd ..
[root@ip-20-0-0-22 lib]# ls -lh |grep mysql
drwxr-xr-x 4 mysql         mysql         4.0K Nov  4 13:14 mysql
[root@ip-20-0-0-22 lib]# 
```

1. 創建目錄`/mnt/mariadb_data`並更改rwx權限爲755
```
mkdir /mnt/mariadb_data
chmod 755 /mnt/mariadb_data/
```

操作過程
```
[root@ip-20-0-0-22 ~]# ls -lh /mnt
total 20K
drwxr-xr-x 4 root root 4.0K Nov  4 13:43 elasticsearch
drwx------ 2 root root  16K Nov  4 10:52 lost+found
[root@ip-20-0-0-22 ~]# mkdir /mnt/mariadb_data
[root@ip-20-0-0-22 ~]# chmod 755 /mnt/mariadb_data/
[root@ip-20-0-0-22 ~]# ls -lh /mnt                 
total 24K
drwxr-xr-x 4 root root 4.0K Nov  4 13:43 elasticsearch
drwx------ 2 root root  16K Nov  4 10:52 lost+found
drwxr-xr-x 2 root root 4.0K Nov  4 13:49 mariadb_data
[root@ip-20-0-0-22 ~]# 
```

2. 停止mysql服務
```
[root@ip-20-0-0-22 lib]# service mysql stop
Shutting down MySQL... SUCCESS! 
[root@ip-20-0-0-22 lib]# service mysql status
 ERROR! MySQL is not running
[root@ip-20-0-0-22 lib]# 
```

3. 將目錄`/var/lib/mysql`下所有文件複製到目錄`/mnt/mariadb_data`下

```
cp -a /var/lib/mysql/* /mnt/mariadb_data/
#-a 將文件屬性一併拷貝
```

操作過程
```
[root@ip-20-0-0-22 ~]# cp -a /var/lib/mysql/* /mnt/mariadb_data/
[root@ip-20-0-0-22 ~]# ls -lh /mnt/mariadb_data/
total 109M
-rw-rw---- 1 mysql mysql  16K Nov  4 13:39 aria_log.00000001
-rw-rw---- 1 mysql mysql   52 Nov  4 13:39 aria_log_control
-rw-rw---- 1 mysql mysql  12M Nov  4 13:39 ibdata1
-rw-rw---- 1 mysql mysql  48M Nov  4 13:39 ib_logfile0
-rw-rw---- 1 mysql mysql  48M Nov  4 12:04 ib_logfile1
-rw-r----- 1 mysql root  1.8K Nov  4 13:39 ip-20-0-0-22.err
-rw-rw---- 1 mysql mysql    0 Nov  4 12:07 multi-master.info
drwx--x--x 2 mysql mysql 4.0K Nov  4 12:04 mysql
drwx------ 2 mysql mysql 4.0K Nov  4 12:04 performance_schema
[root@ip-20-0-0-22 ~]# ls -lh /var/lib/mysql/
total 109M
-rw-rw---- 1 mysql mysql  16K Nov  4 13:39 aria_log.00000001
-rw-rw---- 1 mysql mysql   52 Nov  4 13:39 aria_log_control
-rw-rw---- 1 mysql mysql  12M Nov  4 13:39 ibdata1
-rw-rw---- 1 mysql mysql  48M Nov  4 13:39 ib_logfile0
-rw-rw---- 1 mysql mysql  48M Nov  4 12:04 ib_logfile1
-rw-r----- 1 mysql root  1.8K Nov  4 13:39 ip-20-0-0-22.err
-rw-rw---- 1 mysql mysql    0 Nov  4 12:07 multi-master.info
drwx--x--x 2 mysql mysql 4.0K Nov  4 12:04 mysql
drwx------ 2 mysql mysql 4.0K Nov  4 12:04 performance_schema
[root@ip-20-0-0-22 ~]# 
```

4. 備份MariaDB配置文件`/etc/my.cnf`
```
cp -a /etc/my.cnf /etc/my.cnf_bak
```

操作過程
```
[root@ip-20-0-0-22 ~]# cp -a /etc/my.cnf /etc/my.cnf_bak
[root@ip-20-0-0-22 ~]# ls -lh /etc | grep my.cnf*
-rw-r--r--  1 root root   202 Oct 28 20:35 my.cnf
-rw-r--r--  1 root root   202 Oct 28 20:35 my.cnf_bak
drwxr-xr-x  2 root root  4.0K Nov  4 12:04 my.cnf.d
[root@ip-20-0-0-22 ~]# 
```

5. 編輯MariaDB配置文件`/etc/my.cnf`
添加如下信息
```
# The MySQL server
[mysqld]
#port= 3306
#socket = /var/lib/mysql/mysql.sock
character_set_server=utf8
datadir = /mnt/mariadb_data
```

6. 更改目錄`/mnt/mariadb_data`的屬主、屬組
```
chown -R mysql:mysql /mnt/mariadb_data/
#-R 遞歸
```

操作過程
```
[root@ip-20-0-0-22 ~]# ls -lh /mnt | grep mariadb_data
drwxr-xr-x 4 root root 4.0K Nov  4 13:51 mariadb_data
[root@ip-20-0-0-22 ~]# chown -R mysql:mysql /mnt/mariadb_data/
[root@ip-20-0-0-22 ~]# ls -lh /mnt | grep mariadb_data        
drwxr-xr-x 4 mysql mysql 4.0K Nov  4 13:51 mariadb_data
[root@ip-20-0-0-22 ~]# ls -lh /mnt/mariadb_data/              
total 109M
-rw-rw---- 1 mysql mysql  16K Nov  4 13:39 aria_log.00000001
-rw-rw---- 1 mysql mysql   52 Nov  4 13:39 aria_log_control
-rw-rw---- 1 mysql mysql  12M Nov  4 13:39 ibdata1
-rw-rw---- 1 mysql mysql  48M Nov  4 13:39 ib_logfile0
-rw-rw---- 1 mysql mysql  48M Nov  4 12:04 ib_logfile1
-rw-r----- 1 mysql mysql 1.8K Nov  4 13:39 ip-20-0-0-22.err
-rw-rw---- 1 mysql mysql    0 Nov  4 12:07 multi-master.info
drwx--x--x 2 mysql mysql 4.0K Nov  4 12:04 mysql
drwx------ 2 mysql mysql 4.0K Nov  4 12:04 performance_schema
[root@ip-20-0-0-22 ~]# 
```

7. 重新啓動mysql服務
```
service mysql start
```

操作過程
```
[root@ip-20-0-0-22 ~]# service mysql status
 ERROR! MySQL is not running
[root@ip-20-0-0-22 ~]# service mysql start
Starting MySQL. SUCCESS! 
[root@ip-20-0-0-22 ~]# 
```
---

#####測試成功
```
[root@ip-20-0-0-22 mariadb_data]# pwd
/mnt/mariadb_data
[root@ip-20-0-0-22 mariadb_data]# ls
aria_log.00000001  ibdata1      ib_logfile1       multi-master.info  mysql.sock
aria_log_control   ib_logfile0  ip-20-0-0-22.err  mysql              performance_schema
[root@ip-20-0-0-22 mariadb_data]# mysql -uroot -p -e 'create database if not exists database_test;'
Enter password: 
[root@ip-20-0-0-22 mariadb_data]# ls
aria_log.00000001  database_test  ib_logfile0  ip-20-0-0-22.err   mysql       performance_schema
aria_log_control   ibdata1        ib_logfile1  multi-master.info  mysql.sock
[root@ip-20-0-0-22 mariadb_data]# mysql -uroot -p -e 'drop database if exists database_test;'          
Enter password: 
[root@ip-20-0-0-22 mariadb_data]# ls
aria_log.00000001  ibdata1      ib_logfile1       multi-master.info  mysql.sock
aria_log_control   ib_logfile0  ip-20-0-0-22.err  mysql              performance_schema
[root@ip-20-0-0-22 mariadb_data]# 
```

---

###Create User Account
**註**：此爲示例。生產環境不建議授予`all privileges`權限，也不建議主機項設置爲`%`(任意主機)。

>用戶賬戶：`'viscovery'@'%'`
用戶密碼：`viscovery1qaz2wsx`

```
MariaDB [(none)]> select User,Host from mysql.user;
+------+-----------+
| User | Host      |
+------+-----------+
| root | 127.0.0.1 |
| root | ::1       |
| root | localhost |
+------+-----------+
3 rows in set (0.00 sec)

MariaDB [(none)]> grant all on *.* to 'viscovery'@'%' identified by 'viscovery1qaz2wsx';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> show grants for 'viscovery'@'%'\G
*************************** 1. row ***************************
Grants for viscovery@%: GRANT ALL PRIVILEGES ON *.* TO 'viscovery'@'%' IDENTIFIED BY PASSWORD '*0E5F297108F9EB91DD13E50683ED4F36F8379F69'
1 row in set (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> select User,Host from mysql.user;                                     
+-----------+-----------+
| User      | Host      |
+-----------+-----------+
| viscovery | %         |
| root      | 127.0.0.1 |
| root      | ::1       |
| root      | localhost |
+-----------+-----------+
4 rows in set (0.00 sec)

MariaDB [(none)]> 
```


---

###Configure MariaDB
編輯文件`/etc/my.cnf`，進行MariaDB參數配置。
根據Server的CPU和RAM具體調製。


