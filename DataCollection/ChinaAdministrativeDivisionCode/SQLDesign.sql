#lemp-馬雪東
#https://lempstacker.com
#2016.03.13 12:30 Tue

#explain https://mariadb.com/kb/en/mariadb/explain/

#Database chinaCode
#table
#   proxy
#   province
#   city
#   country
#   town
#   urbanruralCode
#   village

#數據庫名 chinaCode
drop database if exists chinaCode;

create database if not exists chinaCode character set=utf8 collate=utf8_general_ci;

use chinaCode

#Proxy代理
#drop table if exists proxy;
create table if not exists proxy (
    id int(10) unsigned not null auto_increment primary key comment '代理IP列表自增id',
    ipaddr char(18) not null comment '代理IP地址',
    port smallint(5) not null comment '代理IP端口',
    protocol char(10) comment 'HTTP類型',
    anonymity varchar(20) comment '匿名等級',
    country varchar(20) comment '代理IP所屬國家',
    province varchar(20) comment '代理IP所屬省份地區',
    city varchar(20) comment '代理IP所屬城市',
    uptime varchar(10) comment '代理IP正常運行時間',
    createTime timestamp default current_timestamp comment '數據入庫時間 YYYY-MM-DD HH:MM:SS',
    updateTime timestamp null on update current_timestamp comment '數據更新時間 YYYY-MM-DD HH:MM:SS',
    key indProxy_id_ipaddr (id,ipaddr,port),
    unique key indProxy_ipaddr_port (ipaddr,port)
)engine=innodb default charset=utf8 collate=utf8_general_ci comment='代理IP列表';

#alter table proxy add index index_id_ipaddr (id,ipaddr,port);
#alter table proxy add unique index index_ipaddr_port (ipaddr,port);
#drop index index_id_ipaddr on proxy;
#drop index index_ipaddr_port on proxy;


#province省、直轄市、自治區
#drop table if exists province;
create table if not exists province (
    id int(10) unsigned not null auto_increment primary key comment '省級列表自增id',
    name char(24) not null comment '省份名稱',
    name_roc char(24) comment '省份名稱(正體)',
    code bigint(12) unsigned not null comment '行政區劃代碼，共12位，由前2位指定',
    region enum('華北','東北','華東','中南','西南','西北') not null comment '省所屬區域:1華北、2東北、3華東、4中南(華中,華南)、5西南、6西北',
    abbr char(30) comment '省份簡稱或別稱',
    abbr_roc char(30) comment '省份簡稱(正體)',
    createTime timestamp default current_timestamp comment '數據入庫時間 YYYY-MM-DD HH:MM:SS',
    updateTime timestamp null on update current_timestamp comment '數據更新時間 YYYY-MM-DD HH:MM:SS',
    key indProvince_name_abbr (id,name,abbr),
    key indProvince_roc_name_abbr (id,name_roc,abbr_roc),
    unique key ind_code (code)
)engine=innodb default charset=utf8 collate=utf8_general_ci comment='中國大陸省份列表';

#alter table province add index index_name_abbr (name,abbr);
#alter table province add index index_roc_name_abbr (name_roc,abbr_roc);
#alter table province add index index_id_code (id,code);


# city地市級
#drop table if exists city;
create table if not exists city (
    id int(10) unsigned not null auto_increment primary key comment '地級市列表自增id',
    provinceId int(10) unsigned not null comment '省級id，對應表province，外鍵約束',
    name char(60) not null comment '地級市名稱',
    name_roc char(60) comment '地級市名稱(正體)',
    code bigint(12) unsigned not null comment '行政區劃代碼，共12位，由前4位指定',
    abbr char(30) comment '地級市簡稱或別稱',
    abbr_roc char(30) comment '地級市簡稱(正體)',
    createTime timestamp default current_timestamp comment '數據入庫時間 YYYY-MM-DD HH:MM:SS',
    updateTime timestamp null on update current_timestamp comment '數據更新時間 YYYY-MM-DD HH:MM:SS',
    key indCity_name_abbr (id,name(12),abbr),
    key indCity_roc_name_abbr (id,name_roc(12),abbr_roc),
    key incCity_fkey_province (provinceId),
    unique key indCity_code (code),
    constraint fkey_province_city foreign key (provinceId) references province(id) on update cascade
)engine=innodb default charset=utf8 collate=utf8_general_ci comment='中國大陸地級市列表';

#alter table city add constraint fkey_province_city foreign key(provinceId) references province(id) on update cascade;


# country縣級
#drop table if exists country;
create table if not exists country (
    id int(10) unsigned not null auto_increment primary key comment '縣級列表自增id',
    cityId int(10) unsigned not null comment '地級市id，對應表city，外鍵約束',
    name char(60) not null comment '縣級市名稱',
    name_roc char(60) comment '縣級市名稱(正體)',
    code bigint(12) unsigned not null comment '行政區劃代碼，共12位，由前6位指定',
    abbr char(30) comment '縣級市簡稱或別稱',
    abbr_roc char(30) comment '縣級市簡稱(正體)',
    createTime timestamp default current_timestamp comment '數據入庫時間 YYYY-MM-DD HH:MM:SS',
    updateTime timestamp null on update current_timestamp comment '數據更新時間 YYYY-MM-DD HH:MM:SS',
    key indCoun_name_abbr (id,name(12),abbr),
    key indCoun_roc_name_abbr (id,name_roc(12),abbr_roc),
    key indCoun_fkey_city (cityId),
    unique key indCoun_code (code),
    constraint fkey_city_coun foreign key (cityId) references city(id) on update cascade
)engine=innodb default charset=utf8 collate=utf8_general_ci comment='中國大陸縣級列表';


# town鄉級
#drop table if exists town;
create table if not exists town (
    id int(10) unsigned not null auto_increment primary key comment '鄉鎮列表自增id',
    countryId int(10) unsigned not null comment '縣級市id，對應表country，外鍵約束',
    name char(60) not null comment '鄉鎮名稱',
    name_roc char(60) comment '鄉鎮名稱(正體)',
    code bigint(12) unsigned not null comment '行政區劃代碼，共12位，由前9位指定',
    abbr char(30) comment '鄉鎮簡稱或別稱',
    abbr_roc char(30) comment '鄉鎮簡稱(正體)',
    createTime timestamp default current_timestamp comment '數據入庫時間 YYYY-MM-DD HH:MM:SS',
    updateTime timestamp null on update current_timestamp comment '數據更新時間 YYYY-MM-DD HH:MM:SS',
    key indTown_name_abbr (id,name(12),abbr),
    key indTown_roc_name_abbr (id,name_roc(12),abbr_roc),
    key indTown_fkey_coun (countryId),
    unique key indTown_code (code),
    constraint fkey_coun_town foreign key (countryId) references country(id) on update cascade
)engine=innodb default charset=utf8 collate=utf8_general_ci comment='中國大陸鄉鎮列表';


# Urban and rural classification code 城鄉分類代碼
#drop table if exists urbanruralCode;
create table if not exists urbanruralCode (
    id int(10) unsigned not null auto_increment primary key comment '城鄉分類代碼自增id',
    code tinyint(3) unsigned not null comment '城鄉分類代碼，共3位',
    name char(60) not null comment '城鄉分類代碼名稱',
    name_roc char(60) not null comment '城鄉分類代碼名稱(正體)',
    createTime timestamp default current_timestamp comment '數據入庫時間 YYYY-MM-DD HH:MM:SS',
    updateTime timestamp null on update current_timestamp comment '數據更新時間 YYYY-MM-DD HH:MM:SS',
    key indurc_name_abbr (id,code,name),
    unique key indurc_code (code)
)engine=innodb default charset=utf8 collate=utf8_general_ci comment='中國大陸城鄉分類代碼表';

insert into urbanruralCode (code,name,name_roc) values (111,'主城区','主城區'),(112,'城乡结合区','城鄉結合區'),(121,'镇中心区','鎮中心區域'),(122,'镇乡结合区','鎮鄉結合區'),(123,'特殊区域','特殊區域'),(210,'乡中心区','鄉中心區'),(220,'村庄','村莊');


# village村級
#drop table if exists village村級;
create table if not exists village (
    id int(10) unsigned not null auto_increment primary key comment '村級列表自增id',
    townId int(10) unsigned not null comment '鄉鎮id，對應表town，外鍵約束',
    name char(60) not null comment '村莊名稱',
    name_roc char(60) comment '村莊名稱(正體)',
    urbanruralCode tinyint(3) unsigned not null comment '城鄉分類代碼，對應表urbanruralCode中code，不設外鍵約束',
    code bigint(12) unsigned not null comment '行政區劃代碼，共12位，後3位是村莊代碼',
    abbr char(30) comment '村莊簡稱或別稱',
    abbr_roc char(30) comment '村莊簡稱(正體)',
    createTime timestamp default current_timestamp comment '數據入庫時間 YYYY-MM-DD HH:MM:SS',
    updateTime timestamp null on update current_timestamp comment '數據更新時間 YYYY-MM-DD HH:MM:SS',
    key indVillage_name_abbr (id,name(12),abbr),
    key indVillage_roc_name_abbr (id,name_roc(12),abbr_roc),
    key indVillage_urcode (urbanruralCode),
    key indVillage_fkey_town (townId),
    unique key indVillage_code (code),
    constraint fkey_town_village foreign key (townId) references town(id) on update cascade
)engine=innodb default charset=utf8 collate=utf8_general_ci comment='中國大陸村级列表';




-- set foreign_key_checks=0
