<?php
header("Content-Type:text/html;charset=UTF-8");
// ini_set("display_errors", "On");
// error_reporting(E_ALL | E_STRICT);

	// error_reporting(1);


	$dbuser = 'flying';
	$dbpass = '12345';
	try {
		$pdo = new PDO('mysql:host=127.0.0.1;port=3306;dbname=lagou',$dbuser,$dbpass);
		$pdo->exec('set names utf8');//如果不設置，中文是亂碼

	} catch (Exception $e) {
		echo '數據庫連接失敗，報錯信息： '.$e->getMessage();
	}


	$data_api = 'http://www.lagou.com/jobs/positionAjax.json';

	#定义查詢变量
	$order='default'; //px 排序 'default','new'
	$city='北京';//city 查选城市
	$salary_range='10k-15k';//yx月薪范围
	$job_nature='全职';//gx 工作性质
	$industry_field='移动互联网';//hy 行业领域
	$finance_stage='成长型';//jd 公司阶段
	$work_experience='1-3年';//gj 工作经验
	$educational_background='本科';//xl学历要求
	$keywords='运维工程师';//kd 搜索关键词
	$first='true';//first
	// $now_page_num=1;//pn 当前页面数

	#curl 参数设置
	$user_agent = "Mozilla/4.0";

	$search_paras = "?px=$order&city=$city&gx=$job_nature&kd=$keywords&pn=";
	// $curl_url=$data_api.$search_paras.$now_page_num;
	$curl_url=$data_api.$search_paras;


# 從數據庫中獲取city列表，名稱爲key，id值爲value
	$sql = 'select id,name from city';
	$stmt = $pdo->prepare($sql);
	$stmt->execute();
	$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
	foreach ($rows as $key => $val) {
		$city_arr[$val['name']] = $val['id'];
	}
	unset($sql);
	unset($stmt);
	unset($rows);

	# 從數據庫獲取proxy列表，1～100

	$sql = 'select ipaddr,port from proxy where id='.rand(1,100);
	$stmt = $pdo->prepare($sql);
	$stmt->execute();
	$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
	if (empty($rows)){
		$proxy = "117.135.251.133";
		$proxyPort = "82";
	}else {
		$proxy=$rows[0]['ipaddr'];
		$proxyPort=$rows[0]['port'];
	}
	unset($sql);
	unset($stmt);
	unset($rows);


	$totalPageCount = max_page_count($curl_url,$now_page_num=1,$user_agent,$proxy,$proxyPort);//最大页面数

	// echo $totalPageCount;exit;

	for ($i=1; $i <= $totalPageCount; $i++) {
		$sql = 'select ipaddr,port from proxy where id='.rand(1,100);
		$stmt = $pdo->prepare($sql);
		$stmt->execute();
		$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
		if (empty($rows)){
			$proxy = "117.135.251.133";
			$proxyPort = "82";
		}else {
			$proxy=$rows[0]['ipaddr'];
			$proxyPort=$rows[0]['port'];
		}
		unset($sql);
		unset($stmt);
		unset($rows);

		$result_arr = curl_data($curl_url.$i,$user_agent,$proxy,$proxyPort);//返回content中信息
		$job_list_arr=$result_arr["result"];//職位列表詳細信息
		// echo '<pre>';print_r($result_arr);exit;

		foreach ($job_list_arr as $key => $val) {
			$now = date('Y-m-d H:i:s');

			#判斷positionId是否存在表jobs中
			$sql = 'select id,publish_time from jobs where positionId='.$val['positionId'];
			// $sql = 'select id,publish_time from jobs where positionId=1428460';
			$stmt = $pdo->prepare($sql);
			$stmt->execute();
			$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
			unset($sql);
			unset($stmt);

			//如果不爲空，即表示在數據表jobs中存在，判斷發佈時間是否一致，若不一致，update_times加1
			if (!empty($rows) && $rows[0]['id']>0){
				$job_id=$rows[0]['id'];
				$job_publish_time=$rows[0]['publish_time'];
				if ($val['createTime'] != $job_publish_time){
					$sql = "update jobs set update_times=update_times+1 where id=$job_id";
				 	$res = $pdo->exec($sql);
				 	// if ($resl){
				 	// 	echo '更新成功';
				 	// }
					unset($sql);
					unset($res);
				}
			}
			unset($rows);

			//如果爲空，即表示在數據表jobs中不存在，須進行入庫操作

			//先判斷companyId是否存在表company中,不存在則先入庫
			$sql = 'select id from company where companyId='.$val['companyId'];
			// $sql = 'select id from company where companyId=16799';
			$stmt = $pdo->prepare($sql);
			$stmt->execute();
			$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
			unset($sql);
			unset($stmt);
			if (!empty($rows)){
				$company_id=$rows[0]['id'];
			}else {
				//如果爲空，即不存在表company中,先入庫
				$city_id = $city_arr[$val['city']];

				$sql = "insert into company set
					city_id=$city_id,
					companyId='".$val['companyId']."',
					companyShortName='".$val['companyShortName']."',
					companyName='".$val['companyName']."',
					companyLogo='".$val['companyLogo']."', industryField='".$val['industryField']."',
					financeStage='".$val['financeStage']."',
					companySize='".$val['companySize']."',
					leaderName='".$val['leaderName']."',
					create_time='$now'";

				unset($city_id);
				if ($pdo->exec($sql)){
					$company_id = $pdo->lastInsertId();
				}
				unset($sql);
			}
			unset($rows);

			//將職位寫入數據庫
			list($salary_low,$salary_high) = explode('-',str_replace('k','',$val['salary']));


			$sql = "insert into jobs set
				company_id=$company_id,
				positionName='".$val['positionName']."',
				positionType='".$val['positionType']."',
				positionId='".$val['positionId']."',
				work_city='".$val['city']."',
				jobNature='".$val['jobNature']."',
				education='".$val['education']."',
				salary_low=$salary_low,
				salary_top=$salary_high,
				postionAdvantage='".$val['positionAdvantage']."', publish_time='".$val['createTime']."',
				create_time='$now'";

			// echo $sql;
			if ($pdo->exec($sql)){
				$new_job_id = $pdo->lastInsertId();
			}
			unset($sql);


			// echo '<pre>';print_r($rows);
			// break;


		} //end foreach

	}//end for




	#抓取数据，返回json格式数据
	function curl_data ($url,$user_agent,$proxy,$proxyPort){
	    $ch = curl_init();
	    curl_setopt($ch,CURLOPT_PROXY,$proxy); //代理地址
	    curl_setopt($ch,CURLOPT_PROXYPORT,$proxyPort); //代理地址端口
		curl_setopt($ch, CURLOPT_PROXYAUTH, CURLAUTH_BASIC); //代理认证模式
	    curl_setopt ($ch, CURLOPT_URL, $url); //目標地址
	    curl_setopt ($ch, CURLOPT_USERAGENT, $user_agent); //瀏覽器類型
	    curl_setopt ($ch, CURLOPT_HEADER, 0);//是否取得返回头信息
	    curl_setopt ($ch, CURLOPT_RETURNTRANSFER, 1);
	    curl_setopt ($ch, CURLOPT_FOLLOWLOCATION, 1);
	    curl_setopt ($ch, CURLOPT_TIMEOUT, 120);
	    $temp = curl_exec ($ch);
	    curl_close($ch);
	    // return $result;
		$result = json_decode($temp,true);
		return $result['content'];
	}


	//獲取最大頁面數
	function max_page_count ($curl_url,$now_page_num=1,$user_agent,$proxy,$proxyPort){
		$curl_url.=$now_page_num;
		$result_arr = curl_data($curl_url,$user_agent,$proxy,$proxyPort);//返回content中信息
		$result=$result_arr["totalPageCount"]; //最大页面数
		return $result;
	}






// 使用pdo操作数据库
// http://www.111cn.net/phper/php-database/65293.htm
// try {
// 	$pdo = new PDO('mysql:host=127.0.0.1;port=3306;dbname=test','flying','12345');
// $pdo->exec('set names utf8');//如果不設置，中文是亂碼
//
// } catch (Exception $e) {
// 	echo '数据库连接失败，报错信息： '.$e->getMessage();
// }

#增
// // $sql = "insert into city(name,c_id) values('hangzhou',5)";
// // $res = $pdo->exec($sql);
// // echo '影响行数: '.$res;
// $last_insert_id = $pdo->lastInsertId();

#改
// $sql = "update city set name='HangZhou' where id=6";
// $res = $pdo->exec($sql);
// echo '影响行数: '.$res;

#删除
// $sql = "delete from city where id=6";
// $res = $pdo->exec($sql);
// echo '影响行数: '.$res;

// #查
// $sql = "select user,host from mysql.user";
// $stmt = $pdo->prepare($sql);
// $stmt->execute();
// $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
// foreach ($rows as $key => $val) {
// 	echo 'User is: '. $val['user']. ', Host is: '. $val['host'].'<br/>';
// }


 ?>
