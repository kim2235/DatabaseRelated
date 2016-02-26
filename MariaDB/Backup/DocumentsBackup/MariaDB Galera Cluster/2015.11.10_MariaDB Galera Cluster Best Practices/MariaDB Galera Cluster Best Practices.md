#MariaDB Galera Cluster Best Practices


**Nirbhay Choubey**
work for MariaDB Corporation
Twitter: @nirbhay_c
Blog: <http://nirbhay.in>

---
##Table Of Contents
1. [A quick introduction to MariaDB Galera Cluster](#quick-introduce-to-mariadb-galera-cluster)
2. [Setting up the cluster](#setting-up-the-cluster)
2.1 [Mandatory settings](#mandatory-settings)
2.2 [Number of nodes?](#number-of-nodes)
2.3 [Bootstrapping the cluster](#bootstrapping-the-cluster)
3. [State transfer](#state-transfer)
3.1 [Kinds](#kinds)
3.2 [Snapshot state transfer (SST)](#snapshot-state-transfer)
3.3 [Incremental state transfer (IST)](#incremental-state-transfer)
4. [Schema upgrades](#schema-upgrades)
4.1 [Methods (wsrep_OSU_method)](#methods-wsrep-osu-method)
4.2 [Total order isolation](#total-order-isolation)
4.3 [Rolling schema upgrade](#rolling-schema-upgrade)
5. [Securing Galera traffic](#securing-galera-traffic)
5.1 [Encrypted replication traffic using SSL](#encrypted-replication-traffic-using-ssl)
5.2 [SST scripts can enable encrypt](#sst-scripts-can-enable-encrypt)
6. [Parallel replication](#parallel-replication)
6.1 [What is applier thread?](#what-is-applier-thread)
7. [What about MyISAM table updates?](#what-about-myisam-table-updates)
7.1 [yes, replication of MyISAM updates work, but](#replication-myisam)
8. [Load balancing](#load-balancing)
8.1 [Multiple options available](#multiple-options-available)
8.2 [Load balancing policies](#load-balancing-policies)
9. [Bracing for disaster](#bracing-for-disaster)
9.1 [Using galera cluster as master](#using-galera-cluster-as-master)
10. [Understanding limitations](#understanding-limitations)
11. [Troubleshooting](#troubleshooting)
11.1 [Network partitioning/Split-brain](#network-partitioning)
11.2 [Multi-master conflicts](#multi-master-conflicts)
11.3 [Applier failures](#applier-failures)
11.4 [Detecting slow nodes](#detecting-slow-nodes)
12. [Pit falls](#pit-falls)
12.1 [Non-sequential auto-increment keys](#non-sequential-auto-increment-keys)
12.2 [Principle of least variation](#principle-of-least-variation)
13. [MariaDB project](#mariadb-project)




<span id="quick-introduce-to-mariadb-galera-cluster"></span>
##A quick introduction to MariaDB Galera Cluster

* Synchronous replication
*  Active-active multi-master topology
*  Read/write to any cluster node
*  Automatic membership control
*  True parallel replication
*  Direct client connection, native mysql look & feel
*  Incredibly easy to setup
*  Versions
*  Packages available for all major linux distributions
	*  apt-get install mariadb-galera-server
	*  yum install MariaDB-Galera-server
	*  zypper install MariaDB-Galera-server

---
<span id="setting-up-the-cluster"></span>
##Setting up the cluster

<span id="mandatory-settings">
####Mandatory settings
* `wsrep_provider`
	* libgalera_smm.so
	* none == vanilla MariaDB server
* `wsrep_cluster_address`
	* more on this later...
* `binlog_format` = ROW
* `default_storage_engine` = InnoDB

<span id="number-of-nodes">
####Number of nodes?
* **Odd isn't really ODD**
* galera arbitrator (stateless)


<span id="bootstrapping-the-cluster">
####Bootstrapping the cluster
* service mysql bootstrap
* service mysql start -- wsrep-new-cluster
* wsrep_cluster_address=gcomm://


---
<span id="state-transfer"></span>
##State transfer
the donor-joiner thing

<span id="kinds"></span>
####Kinds
* Snapshot state transfer (SST)
* Incremental state transfer (IST)

<span id="snapshot-state-transfer"></span>
####Snapshot state transfer (SST)

* SSL methods
	* `wsrep_sst_rsync`
	* `wsrep_sst_xtrabackup`
	* `wsrep_sst_xtrabackup-v2`
	* `wsrep_sst_mysqldump`
* SST API (implement/propose one!)
* `wsrep_sst_donor`=&lt;donor-list&gt;

<span id="incremental-state-transfer"></span>
####Incremental state transfer (IST)

* gcahe buffer
* Always preferred


---
<span id="schema-upgrades"></span>
##Schema upgrades

Applications evolve over time, do does their schema

<span id="methods-wsrep-osu-method"></span>
####Methods (wsrep_OSU_method)
* Total order isolation (TOI)
* Rolling schema upgrade (RSU)

<span id="total-order-isolation"></span>
####Total order isolation
* Default method
* Master node detects and replicates DDL during parsing
* Processed at the same 'slot' on all the nodes (thus, total order)
* Uses STATEMENT binlog format

<span id="rolling-schema-upgrade"></span>
####Rolling schema upgrade
* Node is desynced
* Incoming writesets are buffered
* Nothing gets replicated out of the node
* Post-DDL, the node joins back
* Manually execute DDL on each node
* Changes should be backward compatible


---
<span id="securing-galera-traffic"></span>
##Securing Galera traffic

<span id="encrypted-replication-traffic-using-ssl"></span>
####Encrypted replication traffic using SSL
* Enable SSL using `wsrep_provider_options`
	* socket.ssl_cert
	* socket.ssl_key
* Same cert/key on all the nodes
* IST is encrypted too
* **`SST, by default, isn't`**

<span id="sst-scripts-can-enable-encrypt"></span>
####SST scripts can enable encrypt
* `wsrep_sst_xtrabackup(-v2)` support encryption
* `wsrep_sst_rsync` and `wsrep_sst_mysqldump` do not

---
<span id="parallel-replication"></span>
##Parallel replication
multiple applier threads

<span id="what-is-applier-thread">
####What is applier thread?
* `wsrep_slave_threads` = N

How many applier threads?
* `wsrep_cert_deps_distance`
* Maximum of ~4 x #CPUCores


---
<span id="what-about-myisam-table-updates"></span>
##What about MyISAM table updates?

<span id="replication-myisam">
####yes, replication of MyISAM updates work, but:
* `wsrep_replicate_myisam` = ON
* Its **experimental**
* Why?
	* cuz MyISAM is *non-transactional**


---
<span id="load-balancing"></span>
##Load balancing

<span id="multiple-options-available"></span>
####Multiple options available
* XAProxy
	* clustercheck script (returns "200 OK" or "503 Service unavailable")
	* MaxScale
	* GLB

<span id="load-balancing-policies"></span>
####Load balancing policies
* read/write splitting
* round robin
* least-connected

---
<span id="bracing-for-disaster"></span>
##Bracing for disaster

<span id="using-galera-cluster-as-master"></span>
####Using galera cluster as master
* `log-bin`
* `log-slave-updates`
* `server-id` (same across all nodes)
* `gtid-domain-id`
* `wsrep-gtid-mode` (introduced in 10.1)
* `wsrep_gtid_domain-id` (introduced in 10.1)

---
<span id="understanding-limitations"></span>
##Understanding limitations
* Tables should have a primary key
	* --`innodb-force-primary-key` (introduced in 10.1.0)
* Only InnoDB storage engine is supported
* Transaction size
	* `wsrep_max_ws_size` = 1G
	* ~~`wsrep_max_ws_rows`~~ = 128K

---
<span id="troubleshooting"></span>
##Troubleshooting

<span id="network-partitioning"></span>
####Network partitioning/Split-brain
* Even number od nodes
* garbd
* ... as was mentioned earlier

<span id="multi-master-conflicts"></span>
####Multi-master conflicts
* Optimistic concurrency control
* Victim trx is abortem with deadlock error
	* Application should have retry logic
	* `wsrep_retry_autocommit` = N (works only with autocommit transactions)
* Diagnosis
	* `wsrep_log_conflicts`, `wsrep_local_bf_aborts`, `wsrep_local_cert_failures`

<span id="applier-failures"></span>
####Applier failures
* GRA_X_X.log file
	* Headless binlog
* GRA_X_X_v2.log
	* Automatinally includes binlog header
	* Introduced in 10.1.4

>$ mysqlbinlog GRA_X_X.log

<span id="detecting-slow-nodes"></span>
####Detecting slow nodes
* `wsrep_flow_control_sent`
* `wsrep_local_recv_queue`

>Upper limit : gcs.fc_limit
>Lower limit : gcs.fc_limit * gcs.fc_factor


---
<span id="pit-falls"></span>
##Pit falls

<span id="non-sequential-auto-increment-keys"></span>
####Non-sequential auto-increment keys
* Application should be aware of this
* `wsrep_auto_increment_control` = 0`|`1

<span id="principle-of-least-variation"></span>
####Principle of least variation
* SST method
* SSL setting
* etc...

---
<span id="mariadb-project"></span>
##MariaDB project
* Source: <https://github.com/MariaDB/>
* Documentation: <https://mariadb.com/kb/>
* Report bugs/FRs: mariadb.org/jira
* Discussion mailing list: **maria-discuss@lists.launchpad.net**
* IRC: #maria (freenode)

---

#####Note Time 2015.11.10 18:33 Tuesday