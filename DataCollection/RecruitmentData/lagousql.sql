-- MySQL dump 10.16  Distrib 10.1.12-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: lagou
-- ------------------------------------------------------
-- Server version	10.1.12-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `city`
--

DROP TABLE IF EXISTS `city`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `city` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '城市自增id',
  `name` char(20) NOT NULL COMMENT '城市名稱',
  `create_time` datetime NOT NULL COMMENT '入庫時間',
  PRIMARY KEY (`id`),
  KEY `index_city_id` (`id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='城市表';
/*!40101 SET character_set_client = @saved_cs_client */;

insert into city (name,create_time) values('北京',now()),('上海',now()),('廣州',now()),('深圳',now()),('杭州',now());

--
-- Table structure for table `company`
--

DROP TABLE IF EXISTS `company`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `company` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '公司自增id',
  `city_id` int(10) unsigned NOT NULL COMMENT '所在城市id，對應表city',
  `companyId` int(10) unsigned DEFAULT NULL COMMENT 'lagou公司id',
  `companyShortName` varchar(80) DEFAULT NULL COMMENT '公司简称',
  `companyName` varchar(200) DEFAULT NULL COMMENT '公司全称',
  `companyLogo` varchar(200) DEFAULT NULL COMMENT '公司logo，前綴http://www.lagou.com/',
  `industryField` varchar(60) DEFAULT NULL COMMENT '行業類型',
  `financeStage` varchar(60) DEFAULT NULL COMMENT '公司階段',
  `companySize` varchar(60) DEFAULT NULL COMMENT '公司人數規模',
  `leaderName` varchar(30) DEFAULT NULL COMMENT '公司老闆',
  `address` varchar(200) DEFAULT NULL COMMENT '公司地址',
  `create_time` datetime NOT NULL COMMENT '入数据库时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `companyId` (`companyId`),
  KEY `index_company_cityid_companyid` (`id`,`city_id`,`companyId`),
  KEY `fkey_city_companty` (`city_id`),
  CONSTRAINT `fkey_city_companty` FOREIGN KEY (`city_id`) REFERENCES `city` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='公司列表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jobs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '職位列表自增id',
  `company_id` int(10) unsigned DEFAULT NULL COMMENT '公司id,對應表company',
  `positionName` varchar(60) NOT NULL COMMENT '職位名稱',
  `positionType` varchar(60) NOT NULL COMMENT '職位類型',
  `positionId` int(10) unsigned DEFAULT NULL COMMENT 'lagou職位id，http://www.lagou.com/jobs/ID.html',
  `work_city` varchar(20) NOT NULL COMMENT '工作城市',
  `jobNature` varchar(20) NOT NULL COMMENT '工作性質',
  `education` varchar(20) NOT NULL COMMENT '學歷要求',
  `salary_low` tinyint(3) unsigned NOT NULL COMMENT '薪資最低值',
  `salary_top` tinyint(3) unsigned NOT NULL COMMENT '薪資最高值',
  `postionAdvantage` varchar(200) DEFAULT NULL COMMENT '職位優勢',
  `publish_time` datetime NOT NULL COMMENT '公佈時間',
  `create_time` datetime NOT NULL COMMENT '入庫時間',
  `update_times` tinyint(3) unsigned DEFAULT '0' COMMENT '職位刷新次數',
  `duty_and_request` text COMMENT '職位描述，崗位職責和任職資格',
  `address` varchar(255) DEFAULT NULL COMMENT '公司地址',
  PRIMARY KEY (`id`),
  UNIQUE KEY `positionId` (`positionId`),
  KEY `index_jobs_companyid_postionid` (`id`,`company_id`,`positionId`),
  KEY `fkey_company_jobs` (`company_id`),
  KEY `index_addr` (`address`(18)),
  CONSTRAINT `fkey_company_jobs` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='職位表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `proxy`
--

DROP TABLE IF EXISTS `proxy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proxy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '代理列表自增id',
  `ipaddr` char(20) NOT NULL COMMENT '代理IP地址',
  `port` smallint(5) NOT NULL COMMENT '代理IP地址端口',
  `protocol` char(20) DEFAULT NULL COMMENT 'http類型',
  `anonymity` varchar(20) DEFAULT NULL COMMENT '匿名等級',
  `country` varchar(20) DEFAULT NULL COMMENT 'IP所屬國家',
  `region` varchar(20) DEFAULT NULL COMMENT 'IP所屬省份地區',
  `city` varchar(20) DEFAULT NULL COMMENT 'IP所屬城市',
  `uptime` varchar(10) DEFAULT NULL COMMENT '正常運行時間',
  `create_time` datetime NOT NULL COMMENT '入数据库时间',
  PRIMARY KEY (`id`),
  KEY `index_id_ipaddr` (`id`,`ipaddr`,`port`),
  KEY `index_ipaddr_city` (`ipaddr`,`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='代理IP列表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-03-09 15:41:20
