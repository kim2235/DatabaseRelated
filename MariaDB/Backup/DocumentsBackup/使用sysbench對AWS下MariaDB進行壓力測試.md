#使用sysbench對AWS下MariaDB進行壓力測試

撰寫人：馬雪東
撰寫時間：2015.11.05~2015.11.06

####Tables Of Contents
1. [主機信息](#主機信息)
2. [測試準備及測試](#測試準備及測試)
2.1 [數據準備](#數據準備)
2.2 [寫入測試](#寫入測試)
2.3 [更新測試](#更新測試)
2.4 [讀取測試](#讀取測試)
3. [清空命令](#清空命令)
3.1 [清空內存](#清空內存)
3.2 [flush-hosts](#flush-hosts)
4. [併發測試報錯及解決](#併發測試報錯及解決)
5. [測試過程](#測試過程)
6. [MairaDB配置文件](#mariadb-cnf)
7. [Related Blog](#related-blog)

---

####主機信息
>被測試主機IP(Server 1)：`54.223.87.233` ，內網`20.0.0.22`
sysbench主機IP(Server 2)：`54.223.43.142`，內網`20.0.0.177`

>Server 1: 8GB RAM
 Server 2: 4GB RAM

>Server 1 MariaDB帳號
帳號：`'viscovery'@'%'`
密碼：`viscovery1qaz2wsx`

>Server 2 帳號
帳號：`root`
密碼：`1qaz2wsx`

---
####測試準備及測試
1. Server 1已經安裝`MariaDB`、創建遠程連接用戶帳號、創建測試數據庫`sbtest`；
2. Server 2已經安裝`MariaDB`、`sysbench`，切換到sysbench的`db`目錄；


**註**：測試使用內網IP測試

#####數據準備
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

####清空命令
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


###測試過程
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

<span id="mariadb-cnf"></span>
####MairaDB配置文件

*(8G RAM，Server同時運行ElasticSearch)*
`/etc/my.cnf`
```
#
# This group is read both both by the client and the server
# use it for options that affect everything
#
[client-server]

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d

# The MySQL server
[mysqld]
#port= 3306
#socket = /var/lib/mysql/mysql.sock
character_set_server=utf8
datadir = /mnt/mariadb_data

back-log = 5000
max_connections = 2048
max_connect_errors = 10000000
skip-name-resolve   #[Warning] IP address 'xxx.xxx.xxx.xxx' could not be resolved: Name or service not known

#log-bin=mysql-bin
#binlog_format=mixed
table_open_cache = 2048  #2048
binlog_cache_size = 4M #1M


#全局緩存Global Caches 
innodb_buffer_pool_size = 4G  #50%~80% * RAM
innodb_buffer_pool_instances = 4
#innodb_additional_mem_pool_size = 32M   #16M
query_cache_size = 512M   #64M
innodb_log_buffer_size = 16M  #8M
max_heap_table_size = 64M

read_buffer_size = 8M #2M per connection
read_rnd_buffer_size = 12M #16M  per connection
sort_buffer_size = 8M #8M  per connection
join_buffer_size = 8M #8M  per connection
max_allowed_packet = 16M  #16M
thread_stack = 240K

#thread_pool_size = 64 #range 1 to 64
thread_cache_size = 128 #8 for reuse Threads_cached + Threads_connected < thread_cache_size是理想的状态
#thread_concurrency = 16 #8 only for solaris
tmp_table_size = 64M

default-storage-engine = INNODB
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_write_io_threads = 16
innodb_read_io_threads = 16
innodb_thread_concurrency = 64   #32
innodb_log_file_size = 1024M  #innodb_buffer_pool_size*25%
innodb_max_dirty_pages_pct = 90
innodb-log-files-in-group = 2

[myisamchk]
key_buffer_size = 32M #32M
sort_buffer_size = 8M
read_buffer = 8M
write_buffer = 8M

[mysqlhotcopy]
interactive-timeout

[mysqld_safe]
open-files-limit = 8192
```

---


####Related Blog
[MariaDB的线程及连接](http://www.zabbix.cc/technic/1873/)
[MySQL优化入门](http://www.zabbix.cc/technic/2580/)


