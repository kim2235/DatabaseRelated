#!/bin/bash
#lemp-馬雪東
#https://lempstacker.com
#2016.03.08 22:50 Tue
#獲取代理IP列表並寫入數據庫

# http://www.freeproxylists.net/
dbname='lagou'
file='./proxyList.txt';

# awk '{print $1,$2,$3,$4,$5,$8,$9,$10}' $file

awk '{print $1,$2,$3,$4,$5,$8,$9,$10}' $file | while read line;do
    now=`date +'%Y-%m-%d %H:%M:%S'`
    arr=(${line})
    ipaddr=${arr[0]}
    port=${arr[1]}
    protocol=${arr[2]}
    anonymity=${arr[3]}
    country=${arr[4]}
    region=${arr[5]}
    city=${arr[6]}
    uptime=${arr[7]}
    mysql -e "insert into $dbname.proxy set ipaddr='$ipaddr',port='$port',protocol='$protocol',anonymity='$anonymity',country='$country',region='$region',city='$city',uptime='$uptime',create_time='$now';"

done

mysql -e "select count(*) from $dbname.proxy;"
