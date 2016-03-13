#!/bin/bash
#lemp-馬雪東
#https://lempstacker.com
#2016.03.13 23:30 Sun
#抓取數據入庫

dbname='chinaCode'
originUrl='http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2014/'

#curl參數 retry重試次數 retryDelay時間間隔
declare i retry=5
declare i retryDelay=5
# curl -s --retry $retry --retry-delay $retryDelay -x ipaddr:port

#獲取代理IP
function getProxyIP () {
    temp=`mysql -Bse "select ipaddr,port from $dbname.proxy order by rand() limit 1;"`
    arr=($temp)
    ipaddr=${arr[0]}
    port=${arr[1]}
    echo $ipaddr:$port
}
#調用自定義函數getProxyIP
curltool="curl -s --retry $retry --retry-delay $retryDelay -x "`getProxyIP`

# set foreign_key_checks=0



##抓取首頁省份列表
##查詢數據庫，表province中是否有數據，如果沒有則抓取網頁提取數據入庫

provinceCount=`mysql -Bse "select count(*) from $dbname.province;"`
if [[ $provinceCount -eq 0 ]]; then
    mainPage=$originUrl'index.html'     #拼接網頁
    tempfile=`mktemp -t tempXXXXX.txt`
    $curltool $mainPage | iconv -f GBK -t UTF-8 | tr -d "'" | grep "class=provincetr" | sed -n '/<tr class=provincetr>/,/<\/tr>/ p' | sed -r 's@<br/>@\n@g;s@</?(a|tr|td)>@@g;s@<tr class=provincetr>@@g;s@(<a |href=|.html)@@g;s@>@ @g;' | tr -s "\r\n" "\n" > $tempfile

    str=''  #定義變量str，用於拼接字符串入庫
    while read line; do
        arr=($line)
        pcode=${arr[0]}
        pregion=${pcode:0:1}
        pname=${arr[1]}
        # mysql -Bse "insert into $dbname.province set name='"$pname"',code=$pcode,region=$pregion;" &> /dev/null
        #將插入數據拼接成字符串，提高插入效率
        str=$str"('"$pname"',$pcode,$pregion),"
        unset arr
        unset pcode
        unset pregion
        unset pname
    done < $tempfile
    rm -f $tempfile
    str=${str%,*}   #刪除字符串尾部逗號，
    mysql -Bse "insert into $dbname.province (name,code,region) values $str;" &> /dev/null
    unset str
    unset mainPage
fi
unset provinceCount




##抓取各省地級市列表
##地級表city中查看字段provinceId是否含有表province中的數據，如果爲空開值抓取對應地級市數據

cityCount=`mysql -Bse "select count(a.id) from $dbname.city a join $dbname.province b on a.provinceId=b.id;"`
if [[ $cityCount -eq 0 ]]; then
    tempfile=`mktemp -t tempXXXXX.txt`
    mysql -Bse "select id,code,name from $dbname.province;" > $tempfile  #id用於外鍵查選和入庫，code用於拼接網頁URL
    while read line; do
        arr=($line)
        pid=${arr[0]}
        pcode=${arr[1]}
        pname=${arr[2]}
        num=`mysql -Bse "select count(id) from $dbname.city where provinceId=$pid"`
        if [[ $num -eq 0 ]]; then
            tempfilecity=`mktemp -t tempXXXXX.txt`
            provincePage=$originUrl$pcode'.html'
            $curltool $provincePage | iconv -f GBK -t UTF-8 | tr -d "'" | grep "class=citytr" | sed -r 's@ class=citytr@@g' |sed -n '/<tr>/,/<\/tr>/ p' | sed -r 's@<tr>@\n@g;s@>@> @g;s@<[^>]*>@@g;' | tr -s "\r\n" "\n" > $tempfilecity
            sed -i '/^$/d' $tempfilecity
            unset provincePage

            cstr=''
            while read cityline; do
                cityarr=($cityline)
                ccode=${cityarr[0]}
                cname=${cityarr[1]}
                if [[ $cname == '县' ]]; then
                    cname=$pname' 县'
                fi
                cstr=$cstr"('"$cname"',$ccode,$pid),"
                unset cityarr
                unset ccode
                unset cname
            done < $tempfilecity
            rm -f $tempfilecity

            cstr=${cstr%,*}   #刪除字符串尾部逗號，
            mysql -Bse "insert into $dbname.city (name,code,provinceId) values $cstr;" &> /dev/null
            unset cstr
        fi
        unset arr
        unset pid
        unset pcode
        unset pname

    done < $tempfile
    rm -f $tempfile
fi
unset cityCount



##抓取各地級市縣列表
##地級表city中查看字段cityId是否含有表city中的數據，如果爲空開值抓取對應縣級數據

countyCount=`mysql -Bse "select count(a.id) from $dbname.country a join $dbname.city b on a.cityId=b.id;"`
if [[ $countyCount -eq 0 ]]; then
    tempfile=`mktemp -t tempXXXXX.txt`
    mysql -Bse "select id,left(code,2),left(code,4),name from $dbname.city;" > $tempfile  #id用於外鍵查選和入庫，code用於拼接網頁URL 截取前4爲 省2位、地級2位
    while read line; do
        arr=($line)
        cityid=${arr[0]}
        provinceCode=${arr[1]}
        cityCode=${arr[2]}
        cityName=${arr[3]}
        num=`mysql -Bse "select count(id) from $dbname.country where cityId=$cityid"`
        if [[ $num -eq 0 ]]; then
            tempfilecountry=`mktemp -t tempXXXXX.txt`
            cityPage=$originUrl$provinceCode'/'$cityCode'.html'
            $curltool $cityPage | iconv -f GBK -t UTF-8 | tr -d "'" | grep "class=countytr" | sed -r 's@ class=countytr@@g' |sed -n '/<tr>/,/<\/tr>/ p' | sed -r 's@<tr>@\n@g;s@>@> @g;s@<[^>]*>@@g;' > $tempfilecountry

            sed -i '/^$/d' $tempfilecountry
            unset cityPage
            countryStr=''
            while read countryline; do
                countryarr=($countryline)
                countryCode=${countryarr[0]}
                countryName=${countryarr[1]}
                if [[ $countryName == '市辖区' ]]; then
                    countryName=$cityName' 市辖区'
                fi
                # echo 'countryName is '$countryName
                countryStr=$countryStr"('"$countryName"',$countryCode,$cityid),"
                unset countryarr
                unset countryCode
                unset countryName
            done < $tempfilecountry
            rm -f $tempfilecountry

            countryStr=${countryStr%,*}   #刪除字符串尾部逗號，
            mysql -Bse "insert into $dbname.country (name,code,cityId) values $countryStr;" &> /dev/null
            unset countryStr
        fi
        unset arr
        unset cityid
        unset provinceCode
        unset cityCode
        unset cityName
    done < $tempfile
    rm -f $tempfile

fi
unset countyCount



##抓取各地縣的鄉鎮列表
##鄉級表country中查看字段countryId是否含有表Country中的數據， 如果爲空開值抓取對應縣級數據

townCount=`mysql -Bse "select count(a.id) from $dbname.town a join $dbname.country b on a.countryId=b.id;"`
if [[ $townCount -eq 0 ]]; then
    tempfile=`mktemp -t tempXXXXX.txt`
    mysql -Bse "select id,left(code,2),substring(code,3,2),left(code,6),name from $dbname.country;" > $tempfile  #id用於外鍵查選和入庫，code用於拼接網頁URL 截取前4爲 省2位、地級2位
    while read line; do
        arr=($line)
        countryid=${arr[0]}
        provinceCode=${arr[1]}
        cityCode=${arr[2]}
        countryCode=${arr[3]}
        countryName=${arr[4]}
        num=`mysql -Bse "select count(id) from $dbname.town where countryId=$countryid"`
        if [[ $num -eq 0 ]]; then
            tempfileTown=`mktemp -t tempXXXXX.txt`
            countryPage=$originUrl$provinceCode'/'$cityCode'/'$countryCode'.html'
            $curltool $countryPage | iconv -f GBK -t UTF-8 | tr -d "'" | grep "class=towntr" | sed -r 's@ class=towntr@@g' |sed -n '/<tr>/,/<\/tr>/ p' | sed -r 's@<tr>@\n@g;s@>@> @g;s@<[^>]*>@@g;' > $tempfileTown

            sed -i '/^$/d' $tempfileTown
            unset countryPage
            townStr=''
            while read townline; do
                townarr=($townline)
                townCode=${townarr[0]}
                townName=${townarr[1]}
                townStr=$townStr"('"$townName"',$townCode,$countryid),"
                unset townarr
                unset townCode
                unset townName
            done < $tempfileTown
            rm -f $tempfileTown

            townStr=${townStr%,*}   #刪除字符串尾部逗號，
            # echo $townStr
            mysql -Bse "insert into $dbname.town (name,code,countryId) values $townStr;" &> /dev/null
            unset townStr
        fi
        unset arr
        unset countryid
        unset provinceCode
        unset cityCode
        unset countryCode
        unset countryName
    done < $tempfile
    rm -f $tempfile

fi
unset townCount



##抓取各鄉鎮下的村列表
##村級表village中查看字段townId是否含有表town中的數據， 如果爲空開值抓取對應鄉級數據

villageCount=`mysql -Bse "select count(a.id) from $dbname.village a join $dbname.town b on a.townId=b.id;"`
if [[ $villageCount -eq 0 ]]; then
    tempfile=`mktemp -t tempXXXXX.txt`
    mysql -Bse "select id,left(code,2),substring(code,3,2),substring(code,5,2),left(code,9),name from $dbname.town;" > $tempfile  #id用於外鍵查選和入庫，code用於拼接網頁URL 截取前6位 省2位、地級2位 縣級2位
    while read line; do
        arr=($line)
        townid=${arr[0]}
        provinceCode=${arr[1]}
        cityCode=${arr[2]}
        countryCode=${arr[3]}
        townCode=${arr[4]}
        townName=${arr[5]}
        num=`mysql -Bse "select count(id) from $dbname.village where townId=$townid"`
        if [[ $num -eq 0 ]]; then
            tempfileVillage=`mktemp -t tempXXXXXX.txt`
            townPage=$originUrl$provinceCode'/'$cityCode'/'$countryCode'/'$townCode'.html'

            $curltool $townPage | iconv -f GBK -t UTF-8 | tr -d "'" | grep "class=villagetr" | sed -r 's@ class=villagetr@@g' |sed -n '/<tr>/,/<\/tr>/ p' | sed -r 's@<tr>@\n@g;s@>@> @g;s@<[^>]*>@@g;' > $tempfileVillage

            sed -i '/^$/d' $tempfileVillage
            unset townPage
            villageStr=''
            while read villageline; do
                villagearr=($villageline)
                villageCode=${villagearr[0]}
                urbanruralCode=${villagearr[1]}
                villageName=${villagearr[2]}
                villageStr=$villageStr"('"$villageName"',$villageCode,$urbanruralCode,$townid),"
                unset villagearr
                unset villageCode
                unset villageName
            done < $tempfileVillage
            rm -f $tempfileVillage

            villageStr=${villageStr%,*}   #刪除字符串尾部逗號，
            #
            # echo "insert into $dbname.village (name,code,urbanruralCode,townId) values $villageStr;"
            mysql -Bse "insert into $dbname.village (name,code,urbanruralCode,townId) values $villageStr;" &> /dev/null
            unset villageStr
        fi
        unset arr
        unset townid
        unset provinceCode
        unset cityCode
        unset countryCode
        unset townCode
        unset townName
    done < $tempfile
    rm -f $tempfile

fi
unset villageCount







#### set foreign_key_checks=0
