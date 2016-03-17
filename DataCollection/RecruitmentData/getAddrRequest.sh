#!/bin/bash
#lemp-馬雪東
#https://lempstacker.com
#2016.03.17 19:16 Thu
#通過職位頁面獲取工作描述和工作地址


# 從數組表中找取duty_and_request和address爲空的數據，拿id，positionId，通過positionId拼接URL爲http://www.lagou.com/jobs/positionId.html
# 通過代理使用curl抓取頁面存儲到/tmp目錄下，使用  `mktemp -t tmpXXXXXX.txt`
#通過管道命令 提取职位描述和工作地址
    # 岗位职责cat jobpage.html | grep -E -A 1 -i '职位描述' | tail -1 | tr -d '<br>/p[[:space:]]'
    # 工作地址cat jobpage.html | grep -E -A 1 -i '工作地址' | tail -1 | tr -d '</div>[[:space:]]'
#update數據庫，where條件是id

dbname='lagou'
limit=100

#curl參數 retry重試次數 retryDelay時間間隔
declare i retry=5
declare i retryDelay=5
# curl -s --retry $retry --retry-delay $retryDelay -x ipaddr:port

#獲取代理IP
function getProxyIP () {
    arr=(`mysql -Bse "select ipaddr,port from $dbname.proxy order by rand() limit 1;"`)
    ipaddr=${arr[0]}
    port=${arr[1]}
    echo $ipaddr:$port
}

#調用自定義函數getProxyIP
curltool="curl -s --retry $retry --retry-delay $retryDelay -x "`getProxyIP`

url='http://www.lagou.com/jobs/'

mysql -Bse "select id,positionId from $dbname.jobs where address is null limit $limit;" | while read line; do
    arr=($line)
    id=${arr[0]}
    positionId=${arr[1]}

    #使用代理curl抓取頁面
    tempfile=`mktemp -t tempXXXXX.txt`
    # -s quiet靜默模式 --retry 重試次數 --retry-delay 間隔時間 -x 代理 -o保存路徑
    $curltool -o $tempfile $url$positionId'.html'

    #使用sed地址定界獲取指定標籤內容
    duty_and_request=`sed -n '/<dd class="job_bt">/,/<\/dd>/ p' $tempfile | grep -Evi "job_bt|</dd>|职位描述" | grep -v '^$' | sed  -r 's@</?(p|strong|br|span|class|ul|li)[[:space:]]{0,}/?>@@g;s@(<br class="">|<span class="">|<p class="">|<ul class="">|&nbsp;)@@g;' | sed -r "s@'@@g"`

    address=`grep -E -A 1 -i '工作地址' $tempfile | tail -1 | tr -d '</div>[[:space:]]'`


    #將數據更新入數據庫
    mysql -e "update $dbname.jobs set duty_and_request='$duty_and_request',address='$address' where id=$id;"
    rm -f $tempfile
done
