#!/bin/bash
#lemp-馬雪東
#https://lempstacker.com
#2016.03.08 22:50 Tue
#通過職位頁面獲取工作描述和工作地址


# 從數組表中找取duty_and_request和address爲空的數據，拿id，positionId，通過positionId拼接URL爲http://www.lagou.com/jobs/positionId.html
# 通過代理使用curl抓取頁面存儲到/tmp目錄下，使用  `mktemp -t tmpXXXXXX.txt`
#通過管道命令 提取职位描述和工作地址
    # 岗位职责cat jobpage.html | grep -E -A 1 -i '职位描述' | tail -1 | tr -d '<br>/p[[:space:]]'
    # 工作地址cat jobpage.html | grep -E -A 1 -i '工作地址' | tail -1 | tr -d '</div>[[:space:]]'
#update數據庫，where條件是id

dbname='lagou'
limit=20

# 獲取代理 管道會fork一個shell子進程，變量不會保存
tempfile=`mktemp -t tempXXXXX.txt`
mysql -Bse "select ipaddr,port from $dbname.proxy order by rand() limit 1" > $tempfile
while read i; do
    arr=($i)
    ipaddr=${arr[0]}
    port=${arr[1]}
done < $tempfile
rm -f $tempfile

# mysql -Bse "select ipaddr,port from $dbname.proxy order by rand() limit 1" | while read i; do
#     arr=($i)
#     export ipaddr=${arr[0]}
#     export port=${arr[1]}
# done

url='http://www.lagou.com/jobs/'

mysql -Bse "select id,positionId from $dbname.jobs where address is null limit $limit;" | while read line; do
    arr=($line)
    id=${arr[0]}
    positionId=${arr[1]}
    # echo "id is $id, and pid is $positionId"
    # echo $ipaddr' dfsdfs '$port

    #使用代理curl抓取頁面
    tempfile=`mktemp -t tempXXXXX.txt`
    # -s quiet靜默模式 --retry 重試次數 --retry-delay 間隔時間 -x 代理 -o保存路徑
    curl -s --retry 5 --retry-delay 5 -x $ipaddr:$port -o $tempfile $url$positionId'.html'
    #使用gzip，gunzip仍無法解決某些數據入庫亂碼問題
    # curl -H "Accept-Encoding: gzip" -s --retry 5 --retry-delay 5 -x $ipaddr:$port $url$positionId'.html' | gunzip > $tempfile


    #使用sed地址定界獲取指定標籤內容
    duty_and_request=`sed -n '/<dd class="job_bt">/,/<\/dd>/ p' $tempfile | grep -Evi "job_bt|</dd>|职位描述" | grep -v '^$' | sed  -r 's@</?(p|strong|br|span|class|ul|li)[[:space:]]{0,}/?>@@g;s@(<br class="">|<span class="">|<p class="">|<ul class="">|&nbsp;)@@g;' | sed -r "s@'@@g"`

    address=`grep -E -A 1 -i '工作地址' $tempfile | tail -1 | tr -d '</div>[[:space:]]'`


    #將數據更新入數據庫
    mysql -e "update $dbname.jobs set duty_and_request='$duty_and_request',address='$address' where id=$id;"
    rm -f $tempfile
done

# echo $RANDOM

# while read a b;do
#     echo "${a}..${b}"
#
# done << `echo "select id,positionId from $dbname.jobs where address is null limit 1;" | mysql`
