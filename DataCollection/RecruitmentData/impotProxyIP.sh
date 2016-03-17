#!/bin/bash
#lemp-馬雪東
#https://lempstacker.com
#2016.03.08 22:50 Tue
#獲取代理IP列表並寫入數據庫

# http://www.freeproxylists.net/
dbname='lagou'
file='./proxyList.txt';
sed -i '/^$/d;s@High Anonymous@HighAnonymous@g' $file
#createTime設置屬性timestamp default current_timestamp，無需手動指定入庫時間

mysql -e "truncate table $dbname.proxy;"

awk '{print $1,$2,$3,$4,$5,$8,$9,$10}' $file | while read line;do
    # now=`date +'%Y-%m-%d %H:%M:%S'`
    # now=`date +'%F %T'`
    #存入數組
    arr=(${line})
    ipaddr=${arr[0]}
    port=${arr[1]}
    protocol=${arr[2]}
    anonymity=${arr[3]}
    country=${arr[4]}
    region=${arr[5]}
    city=${arr[6]}
    uptime=${arr[7]}
    mysql -e "insert into $dbname.proxy set ipaddr='$ipaddr',port='$port',protocol='$protocol',anonymity='$anonymity',country='$country',region='$region',city='$city',uptime='$uptime';"

    # mysql -e "insert into $dbname.proxy set ipaddr='$ipaddr',port='$port',protocol='$protocol',anonymity='$anonymity',country='$country',province='$region',city='$city',uptime='$uptime',createTime='$now';"

done

mysql -e "select count(*) from $dbname.proxy;"
