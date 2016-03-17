#!/bin/bash
#lemp-馬雪東
#https://lempstacker.com
#2016.03.17 10:40 Thu
#腳本抓取拉勾數據，jq解析json數據

# 判斷jq是否安裝，須以root權限執行腳本
type jq &> /dev/null || sudo yum -q -y install jq


dbname='lagou'
lagouapi='http://www.lagou.com/jobs/positionAjax.json'

#curl參數 retry重試次數 retryDelay時間間隔
declare i retry=5
declare i retryDelay=5
# curl -s --retry $retry --retry-delay $retryDelay -x ipaddr:port

#獲取代理IP
function getProxyIP () {
    # temp=`mysql -Bse "select ipaddr,port from $dbname.proxy order by rand() limit 1;"`
    # arr=($temp)
    arr=(`mysql -Bse "select ipaddr,port from $dbname.proxy order by rand() limit 1;"`)
    ipaddr=${arr[0]}
    port=${arr[1]}
    echo $ipaddr:$port
}

#調用自定義函數getProxyIP
curltool="curl -s --retry $retry --retry-delay $retryDelay -x "`getProxyIP`

#定义查詢变量
order='new'   #px 排序 'default','new'
# city='北京'   #city 查选城市
city_arr=('北京' '上海' '杭州');
rand=`echo "$RANDOM%${#city_arr[*]}" | bc`
city=${city_arr[${rand}]}

salary_range='10k-15k'  #yx月薪范围
job_nature='全职'  #gx 工作性质
industry_field='移动互联网' #hy 行业领域
finance_stage='成长型'  #jd 公司阶段
work_experience='1-3年'  #gj 工作经验
educational_background='本科' #xl学历要求
keywords='运维工程师'  #kd 搜索关键词
first='true'  #first
now_page_num=1  #pn 当前页面数

#拼接查詢參數
search_paras="$lagouapi?px=$order&city=$city&gx=$job_nature&kd=$keywords&pn="


#獲取城市列表
tempfile=`mktemp -t tempXXXXXX.txt`
mysql -Bse "select name,id from $dbname.city;" > $tempfile

declare -A cityarr
while read line; do
    temp=($line)
    tempname=${temp[0]}
    tempid=${temp[1]}
    cityarr[$tempname]=$tempid
    unset temp
    unset tempname
    unset tempid
done < $tempfile
rm -f $tempfile



#獲取最大頁面數
totalPageCount=`$curltool $search_paras'1' | jq '.content.totalPageCount'`

for (( i=1; i<=$totalPageCount; i++ )); do
    tempfile=`mktemp -t tempXXXXXX.txt`
    $curltool $search_paras$i > $tempfile
    pageSize=`cat $tempfile | jq '.content.pageSize'`

    for (( j=0; j<$pageSize; j++ )); do
        createTime=`cat $tempfile | jq -r ".content.result | .[${j}].createTime"`
        city=`cat $tempfile | jq -r ".content.result | .[${j}].city"`
        companyId=`cat $tempfile | jq -r ".content.result | .[${j}].companyId"`
        companyName=`cat $tempfile | jq -r ".content.result | .[${j}].companyName"`
        companyShortName=`cat $tempfile | jq -r ".content.result | .[${j}].companyShortName"`
        companyLogo=`cat $tempfile | jq -r ".content.result | .[${j}].companyLogo"`
        industryField=`cat $tempfile | jq -r ".content.result | .[${j}].industryField"`
        financeStage=`cat $tempfile | jq -r ".content.result | .[${j}].financeStage"`
        companySize=`cat $tempfile | jq -r ".content.result | .[${j}].companySize"`
        leaderName=`cat $tempfile | jq -r ".content.result | .[${j}].leaderName"`

        positionId=`cat $tempfile | jq -r ".content.result | .[${j}].positionId"`
        positionName=`cat $tempfile | jq -r ".content.result | .[${j}].positionName"`
        positionType=`cat $tempfile | jq -r ".content.result | .[${j}].positionType"`
        positionFirstType=`cat $tempfile | jq -r ".content.result | .[${j}].positionFirstType"`
        jobNature=`cat $tempfile | jq -r ".content.result | .[${j}].jobNature"`
        education=`cat $tempfile | jq -r ".content.result | .[${j}].education"`
        positionAdvantage=`cat $tempfile | jq -r ".content.result | .[${j}].positionAdvantage"`
        # workYear=`cat $tempfile | jq -r ".content.result | .[${j}].workYear"`
        salary=`cat $tempfile | jq -r ".content.result | .[${j}].salary" | tr -d k`
        salaryhigh=${salary#*-}
        salarylow=${salary%-*}

        #1判斷positionId是否存在表jobs中

        #1.1通過判斷數組長度，判斷是否已經存在
        jobarr=(`mysql -Bse "select id,publish_time from $dbname.jobs where positionId=$positionId;"`)
        #1.1.1存在
        if [[ ${#jobarr[*]} -gt 0 ]]; then
            jobid=${jobarr[0]}
            jobpubtime=${jobarr[1]}' '${jobarr[2]}
            #比對publish_time，不一致則更新字段update_times，last_update_time
            if [[ "$jobpubtime" != "$createTime" ]]; then
                mysql -Bse "update $dbname.jobs set update_times=update_times+1,last_update_time='$createTime' where id=$jobid;" &> /dev/null

            fi
            unset jobid
            unset jobpubtime
        else
            #1.1.2 不存在，入庫
            #1.1.2.1 companyId是否存在表company中,不存在則先入庫,获取表company id
            comparr=(`mysql -Bse "select id from $dbname.company where companyId=$companyId;"`)
            if [[ ${#comparr[*]} -eq 0 ]]; then
                cityid=${cityarr[$city]}
                mysql -Bse "insert into $dbname.company set city_id=$cityid, companyId='$companyId', companyShortName='$companyShortName', companyName='$companyName', companyLogo='$companyLogo', industryField='$industryField', financeStage='$financeStage', companySize='$companySize', leaderName='$leaderName';" &> /dev/null && compid=`mysql -Bse "select id from $dbname.company where companyId=$companyId;"`

            else
                compid=${comparr[0]}
            fi
            unset comparr

            if [[ $positionId -ne 0 ]]; then
                mysql -Bse "insert into $dbname.jobs set company_id=$compid, positionName='$positionName', positionType='$positionType', positionFirstType='$positionFirstType', positionId='$positionId', work_city='$city', jobNature='$jobNature', education='$education', salary_low='$salarylow', salary_top='$salaryhigh',positionAdvantage='$positionAdvantage',publish_time='$createTime';"

            fi
        fi
        unset jobarr


    done

    rm -f $tempfile
done
