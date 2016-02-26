#CentOS下安裝和使用SysBench

---
Table Of Contents
1. [Install MariaDB](#install-mariadb)
1.1 [Create MariaDB Repository](#create-mariadb-repository)
1.2 [Install MariaDB Server](#install-mariadb-server)
1.3 [Initialize&Configure MariaDB](#initialize-and-configure-mariadb)
2. [Install SysBench](#install-sysbench)
2.1 [Download SysBench](#download-sysbench)
2.2 [Install SysBench Package](#install-sysbench-package)
2.2.1 [way1: resource-install](#resource-install)
2.2.2 [way2: rpm-install](#rpm-install)
3. [Use SysBench](#use-sysbench)
3.1 [併發測試報錯及解決](#parallel-test-error-and-solve)
3.2 [測試過程](#test-process)

---

##Install MariaDB
<span id="create-mariadb-repository">
####Create MariaDB Repository
通過YUM安裝MariaDB，需先在目錄`/etc/yum.repos.d/`下創建MariaDB倉庫，名稱可以是MariaDB.repo 。根據Server系統信息和實際需求，在Setting up MariaDB Repositories中依次選擇 `Distro` ­> `Release` ­> `Version` ，將生成的倉庫信息填入 MariaDB.repo 。

執行如下命令，生成yum緩存
```
yum clean all
yum makecache
```

<span id="install-mariadb-server">
####Install MariaDB Server

yum安裝MariaDB

```
yum install MariaDB-server MariaDB-client MariaDB-devel
```
**`註`**：如果不安裝`MariaDB-devel`，之後在安裝Sysbench時可能會出現如下報錯

```
ERROR: cannot find MySQL libraries.
```

<span id="initialize-and-configure-mariadb">
####Initialize&Configure MariaDB

1. 啓動mysql服務
```
#通用
/etc/init.d/mysql start

#CentOS6
service mysql start

#CentOS7
systemctl start mysql
```

2. 設置mysql服務開機啓動
```
#CentOS6
chkconfig mysql on

#CentOS7
systemctl enable mysql
```

3. 執行 `mysql_secure_installation`

該操作用以提高MariaDB安全性。

MariaDB文檔 [mysql_secure_installation](https://mariadb.com/kb/en/mariadb/mysql_secure_installation/)

```
mysql_secure_installation
```
可在此操作爲root用戶創建密碼,並確定是否允許遠程登錄。

---
<span id="initialize-and-configure-mariadb">
##Install SysBench

<span id="download-sysbench">
####Download SysBench
建議通過官網下載，此處是GitHub地址

[SysBench](https://github.com/akopytov/sysbench/)
><https://github.com/akopytov/sysbench/>

[sysbench-mariadb](https://github.com/hgxl64/sysbench-mariadb)
><https://github.com/hgxl64/sysbench-mariadb>


<span id="install-sysbench-package">
####Install SysBench Package
安裝主要2中方式
>源碼包安裝
>rmp包安裝

推薦使用源碼包安裝，在源碼包安裝不成功時，再使用rpm包安裝，但測試時仍舊需要使用到源碼包。

<span id="resource-install">
#####way1: resource-install
**安裝步驟**
```
./autogen.sh
./configure
make
```

**`註`**：`./configure`需指定`--with-mysql-includes`和`--with-mysql-libs`

準備
```
yum install automake
yum install libtool
```
否則執行`./autogen.sh`時會有如下報錯
```
automake 1.10.x (aclocal) wasn't found, exiting
//解決方案：yum install automake -y

libtoolize 1.4+ wasn't found, exiting
//解決方案：yum install libtool -y
```

如果`MariaDB-devel`沒有安裝，會有如下報錯
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

可通過`whereis`命令獲取mysql的相關路徑
```
[root@ip-172-30-1-60 sysbench-mariadb-0.5]# whereis mysql
mysql: /usr/bin/mysql /usr/lib64/mysql /usr/include/mysql /usr/share/mysql /usr/share/man/man1/mysql.1.gz
```

如下是安裝範例
```
yum install automake libtool MariaDB-devel -y
./autogen.sh
./configure --with-mysql-includes=/usr/include/mysql --with-mysql-libs=/usr/lib64/mysql
make
```

<span id="rpm-install">
#####way2: rpm-install
下載地址：<http://www.lefred.be/files/sysbench-0.5-3.el6_.x86_64.rpm>

下載後，可使用`yum localinstall`命令安裝，自動解決包依賴關係。

---
<span id="use-sysbench">
##Use SysBench
使用SysBench時，參數`--test=`是需要指定具體的路徑。
通常路徑是
```
*/sysbench-0.5/sysbench/tests/db/
```
相關參數不贅述，可自行搜索網路。


#####數據準備
需先登入數據庫，建`sbtest`數據庫
```sql
create database if not exists sbtest
```

```text
sysbench --test=./parallel_prepare.lua --oltp-table-size=100000 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --oltp-tables-count=20 --num-threads=5000 prepare
```

#####寫入測試
```text
sysbench --test=./insert.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
```

#####更新測試
```text
sysbench --test=./update_index.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run

sysbench --test=./update_non_index.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
```

#####讀取測試
```text
sysbench --test=./select.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
```

#####讀寫測試

```text
sysbench --test=./oltp.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
```

---
#####清空內存
```
[root@ip-20-0-0-22 vm]# sync
[root@ip-20-0-0-22 vm]# echo 1 > /proc/sys/vm/drop_caches 
[root@ip-20-0-0-22 vm]# service mysql restart
```

```
service mysql restart && sync && echo 1 > /proc/sys/vm/drop_caches && mysqladmin -uroot -p flush-hosts
```

#####flush-hosts
```
mysqladmin -uroot -p flush-hosts
```

```
[root@ip-20-0-0-177 db]# mysqladmin -uroot -p flush-hosts
Enter password: 
[root@ip-20-0-0-177 db]# 
```
---

<span id="parallel-test-error-and-solve"></span>
####併發測試報錯及解決
```
[root@ip-20-0-0-177 db]# sysbench --test=./insert.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=1024 --oltp-read-only=off --rand-type=gaussian --report-interval=10 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
sysbench 0.5:  multi-threaded system evaluation benchmark

Running the test with following options:
Number of threads: 1024
Report intermediate results every 10 second(s)
Random number generator seed is 0 and will be ignored


Threads started!

FATAL: unable to connect to MySQL server, aborting...
FATAL: error 2004: Can't create TCP/IP socket (24)
PANIC: unprotected error in call to Lua API (Failed to connect to the database)
FATAL: unable to connect to MySQL server, aborting...
FATAL: error 2004: Can't create TCP/IP socket (24)
PANIC: unprotected error in call to Lua API (Failed to connect to the database)
[root@ip-20-0-0-177 db]# 
```
相關Blog[ sysbench Can't create TCP/IP socket](http://blog.chinaunix.net/uid-53720-id-2098571.html)

原因
```
[root@ip-20-0-0-177 db]# ulimit -a | grep 'open files'
open files                      (-n) 1024
[root@ip-20-0-0-177 db]# 
```
Server默認打開數是1024，需要更改文件`/etc/security/limits.conf`，添加
```
#星號*代表所有用戶
* soft nofile 60000
* hard nofile 60000
```
重啓後生效


<span id="test-process"></span>
####測試過程
1.純讀取測試
```
[root@ip-20-0-0-177 db]# sysbench --test=./select.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
sysbench 0.5:  multi-threaded system evaluation benchmark

Running the test with following options:
Number of threads: 256
Report intermediate results every 5 second(s)
Random number generator seed is 0 and will be ignored


Threads started!

[   5s] threads: 256, tps: 0.00, reads/s: 9750.53, writes/s: 0.00, response time: 99.50ms (99%)
[  10s] threads: 256, tps: 0.00, reads/s: 9918.40, writes/s: 0.00, response time: 155.00ms (99%)
[  15s] threads: 256, tps: 0.00, reads/s: 9859.00, writes/s: 0.00, response time: 100.97ms (99%)
[  20s] threads: 256, tps: 0.00, reads/s: 10066.80, writes/s: 0.00, response time: 180.79ms (99%)
[  25s] threads: 256, tps: 0.00, reads/s: 9772.00, writes/s: 0.00, response time: 104.28ms (99%)
[  30s] threads: 256, tps: 0.00, reads/s: 10040.60, writes/s: 0.00, response time: 176.93ms (99%)
[  35s] threads: 256, tps: 0.00, reads/s: 9912.00, writes/s: 0.00, response time: 100.45ms (99%)
[  40s] threads: 256, tps: 0.00, reads/s: 10084.80, writes/s: 0.00, response time: 112.42ms (99%)
[  45s] threads: 256, tps: 0.00, reads/s: 10170.46, writes/s: 0.00, response time: 140.63ms (99%)
[  50s] threads: 256, tps: 0.00, reads/s: 9917.12, writes/s: 0.00, response time: 100.18ms (99%)
[  55s] threads: 256, tps: 0.00, reads/s: 10125.41, writes/s: 0.00, response time: 215.06ms (99%)
[  60s] threads: 256, tps: 0.00, reads/s: 10193.60, writes/s: 0.00, response time: 212.63ms (99%)
OLTP test statistics:
    queries performed:
        read:                            599309
        write:                           0
        other:                           0
        total:                           599309
    transactions:                        0      (0.00 per sec.)
    deadlocks:                           0      (0.00 per sec.)
    read/write requests:                 599309 (9985.58 per sec.)
    other operations:                    0      (0.00 per sec.)

General statistics:
    total time:                          60.0174s
    total number of events:              599309
    total time taken by event execution: 15346.1665s
    response time:
         min:                                  0.25ms
         avg:                                 25.61ms
         max:                               1071.04ms
         approx.  99 percentile:             133.10ms

Threads fairness:
    events (avg/stddev):           2341.0508/72.60
    execution time (avg/stddev):   59.9460/0.05

[root@ip-20-0-0-177 db]#
```

2.純寫入測試
```
[root@ip-20-0-0-177 db]# sysbench --test=./insert.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
sysbench 0.5:  multi-threaded system evaluation benchmark

Running the test with following options:
Number of threads: 256
Report intermediate results every 5 second(s)
Random number generator seed is 0 and will be ignored


Threads started!

[   5s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 6607.82, response time: 413.02ms (99%)
[  10s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8345.18, response time: 315.19ms (99%)
[  15s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8288.62, response time: 335.04ms (99%)
[  20s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8373.20, response time: 340.80ms (99%)
[  25s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 7962.80, response time: 424.04ms (99%)
[  30s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8433.21, response time: 438.76ms (99%)
[  35s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8344.59, response time: 364.33ms (99%)
[  40s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8435.36, response time: 389.60ms (99%)
[  45s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8335.64, response time: 412.40ms (99%)
[  50s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8181.18, response time: 411.04ms (99%)
[  55s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8361.01, response time: 431.34ms (99%)
[  60s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 8320.81, response time: 439.42ms (99%)
OLTP test statistics:
    queries performed:
        read:                            0
        write:                           490204
        other:                           0
        total:                           490204
    transactions:                        0      (0.00 per sec.)
    deadlocks:                           0      (0.00 per sec.)
    read/write requests:                 490204 (8158.14 per sec.)
    other operations:                    0      (0.00 per sec.)

General statistics:
    total time:                          60.0877s
    total number of events:              490204
    total time taken by event execution: 15356.9113s
    response time:
         min:                                  0.31ms
         avg:                                 31.33ms
         max:                               1676.24ms
         approx.  99 percentile:             383.92ms

Threads fairness:
    events (avg/stddev):           1914.8594/57.62
    execution time (avg/stddev):   59.9879/0.03

[root@ip-20-0-0-177 db]#
```

3.純更新測試(index)
```
[root@ip-20-0-0-177 db]# sysbench --test=./update_index.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
sysbench 0.5:  multi-threaded system evaluation benchmark

Running the test with following options:
Number of threads: 256
Report intermediate results every 5 second(s)
Random number generator seed is 0 and will be ignored


Threads started!

[   5s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15091.17, response time: 52.54ms (99%)
[  10s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15389.17, response time: 28.06ms (99%)
[  15s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15453.85, response time: 27.20ms (99%)
[  20s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15249.01, response time: 34.49ms (99%)
[  25s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15386.99, response time: 27.04ms (99%)
[  30s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15338.16, response time: 34.85ms (99%)
[  35s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15390.20, response time: 69.70ms (99%)
[  40s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15503.65, response time: 111.18ms (99%)
[  45s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15421.15, response time: 45.39ms (99%)
[  50s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15355.04, response time: 56.27ms (99%)
[  55s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15450.73, response time: 27.76ms (99%)
[  60s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15230.09, response time: 31.44ms (99%)
OLTP test statistics:
    queries performed:
        read:                            0
        write:                           921552
        other:                           0
        total:                           921552
    transactions:                        0      (0.00 per sec.)
    deadlocks:                           0      (0.00 per sec.)
    read/write requests:                 921552 (15355.81 per sec.)
    other operations:                    0      (0.00 per sec.)

General statistics:
    total time:                          60.0133s
    total number of events:              921552
    total time taken by event execution: 15281.3026s
    response time:
         min:                                  0.29ms
         avg:                                 16.58ms
         max:                                663.04ms
         approx.  99 percentile:              40.59ms

Threads fairness:
    events (avg/stddev):           3599.8125/280.02
    execution time (avg/stddev):   59.6926/0.28

[root@ip-20-0-0-177 db]#
```

4.純更新測試(non_index)
```
[root@ip-20-0-0-177 db]# sysbench --test=./update_non_index.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
sysbench 0.5:  multi-threaded system evaluation benchmark

Running the test with following options:
Number of threads: 256
Report intermediate results every 5 second(s)
Random number generator seed is 0 and will be ignored


Threads started!

[   5s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15171.77, response time: 59.94ms (99%)
[  10s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15208.82, response time: 38.33ms (99%)
[  15s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15352.58, response time: 27.69ms (99%)
[  20s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15334.61, response time: 28.64ms (99%)
[  25s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15291.40, response time: 28.28ms (99%)
[  30s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15405.61, response time: 29.83ms (99%)
[  35s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15106.38, response time: 31.69ms (99%)
[  40s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15262.02, response time: 41.89ms (99%)
[  45s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15352.00, response time: 27.21ms (99%)
[  50s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15207.00, response time: 31.22ms (99%)
[  55s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15282.81, response time: 29.35ms (99%)
[  60s] threads: 256, tps: 0.00, reads/s: 0.00, writes/s: 15328.19, response time: 28.75ms (99%)
OLTP test statistics:
    queries performed:
        read:                            0
        write:                           916773
        other:                           0
        total:                           916773
    transactions:                        0      (0.00 per sec.)
    deadlocks:                           0      (0.00 per sec.)
    read/write requests:                 916773 (15275.96 per sec.)
    other operations:                    0      (0.00 per sec.)

General statistics:
    total time:                          60.0141s
    total number of events:              916773
    total time taken by event execution: 15313.8059s
    response time:
         min:                                  0.31ms
         avg:                                 16.70ms
         max:                                547.30ms
         approx.  99 percentile:              30.69ms

Threads fairness:
    events (avg/stddev):           3581.1445/418.76
    execution time (avg/stddev):   59.8196/0.21

[root@ip-20-0-0-177 db]#
```

5.讀寫測試
```
[root@ip-20-0-0-177 db]# sysbench --test=./oltp.lua --oltp-tables-count=20 --oltp-table-size=1000000 --num-threads=256 --oltp-read-only=off --rand-type=gaussian --report-interval=5 --mysql-db=sbtest --mysql-host=20.0.0.22 --mysql-table-engine=innodb --mysql-user=viscovery --mysql-password=viscovery1qaz2wsx --max-time=60 --max-requests=0 --percentile=99 run
sysbench 0.5:  multi-threaded system evaluation benchmark

Running the test with following options:
Number of threads: 256
Report intermediate results every 5 second(s)
Random number generator seed is 0 and will be ignored


Threads started!

[   5s] threads: 256, tps: 530.19, reads/s: 9668.93, writes/s: 2534.53, response time: 1562.51ms (99%)
[  10s] threads: 256, tps: 694.40, reads/s: 9858.40, writes/s: 2799.00, response time: 643.43ms (99%)
[  15s] threads: 256, tps: 706.00, reads/s: 9902.81, writes/s: 2831.20, response time: 455.49ms (99%)
[  20s] threads: 256, tps: 705.00, reads/s: 9885.19, writes/s: 2818.60, response time: 453.31ms (99%)
[  25s] threads: 256, tps: 709.60, reads/s: 9931.19, writes/s: 2836.40, response time: 784.20ms (99%)
[  30s] threads: 256, tps: 705.60, reads/s: 9880.42, writes/s: 2832.41, response time: 750.22ms (99%)
[  35s] threads: 256, tps: 701.20, reads/s: 9806.60, writes/s: 2800.80, response time: 453.58ms (99%)
[  40s] threads: 256, tps: 696.80, reads/s: 9792.80, writes/s: 2793.80, response time: 599.00ms (99%)
[  45s] threads: 256, tps: 697.60, reads/s: 9779.40, writes/s: 2796.40, response time: 714.92ms (99%)
[  50s] threads: 256, tps: 700.80, reads/s: 9820.20, writes/s: 2798.20, response time: 830.10ms (99%)
[  55s] threads: 256, tps: 707.00, reads/s: 9845.21, writes/s: 2819.40, response time: 746.64ms (99%)
[  60s] threads: 256, tps: 692.00, reads/s: 9738.19, writes/s: 2776.20, response time: 683.12ms (99%)
OLTP test statistics:
    queries performed:
        read:                            590758
        write:                           168078
        other:                           83684
        total:                           842520
    transactions:                        41487  (689.35 per sec.)
    deadlocks:                           710    (11.80 per sec.)
    read/write requests:                 758836 (12608.85 per sec.)
    other operations:                    83684  (1390.50 per sec.)

General statistics:
    total time:                          60.1828s
    total number of events:              41487
    total time taken by event execution: 15380.1942s
    response time:
         min:                                  8.63ms
         avg:                                370.72ms
         max:                               2627.06ms
         approx.  99 percentile:             772.55ms

Threads fairness:
    events (avg/stddev):           162.0586/4.15
    execution time (avg/stddev):   60.0789/0.06

[root@ip-20-0-0-177 db]#
```

---

Write Time：2015.11.17 12:24

Writer：馬雪東



