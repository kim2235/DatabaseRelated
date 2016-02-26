#Galera Cluster GLOSSARY

---
##Table Of Contents
1. [Galera Arbitrator](#galera-arbitrator)
2. [Galera Replication Plugin](#galera-replication-plugin)
3. [GCache](#gcache)
4. [Global Transaction ID](#global-transaction-id)
5. [Incremental State Transfer](#incremental-state-transfer)
6. [IST](#ist)
7. [Logical State Transfer Method](#logical-state-transfer-method)
8. [Physical State Transfer Method](#physical-state-transfer-method)
9. [Primary Component](#primary-component)
10. [Rolling Schema Upgrade](#rolling-schema-upgrade)
11. [RSU](#rsu)
12. [seqno](#seqno)
13. [sequence number](#sequence-number)
14. [SST](#sst)
15. [State Snapshot Transfer](#state-snapshot-transfer)
16. [State UUID](#state-uuid)
17. [TOI](#toi)
18. [Total Order Isolation](#total-order-isolation)
19. [write-set](#write-set)
20. [Write-set Cache](#write-set-cache)
21. [wsrep API](#wsrep-api)

---

##Galera Arbitrator
External process that functions as an additional node in certain cluster operations, such as quorum calculations and generating consistent application state snapshots.

Consider a situation where you cluster becomes partitioned due to a loss of network connectivity that results in two components of equal size. Each component initiates quorum calculations to determine which should remain the [Primary Component](http://galeracluster.com/documentation-webpages/glossary.html#term-primary-component) and which should become a nonoperational component. If the components are of equal size, it risks a split-brain condition. Galera Arbitrator provides an addition vote in the quorum calculation, so that one component registers as larger than the other. The larger component then remains the Primary Component.

Unlike the main mysqld process, garbd does not generate replication events of its own and does not store replication data, but it does acknowledge all replication events. Furthermore, you can route replication through Galera Arbitrator, such as when generating a consistent application state snapshot for backups.

**Note** See Also: For more information, see [Galera Arbitrator](http://galeracluster.com/documentation-webpages/arbitrator.html) and [Backing Up Cluster Data](http://galeracluster.com/documentation-webpages/backingupthecluster.html).


##Galera Replication Plugin
Galera Replication Plugin is a general purpose replication plugin for any transactional system. It can be used to create a synchronous multi-master replication solution to achieve high availability and scale-out.

**Note** See Also: For more information, see [Galera Replication Plugin](http://galeracluster.com/documentation-webpages/architecture.html#id3) for more details.


##GCache
See [Write-set Cache](http://galeracluster.com/documentation-webpages/glossary.html#term-write-set-cache).


##Global Transaction ID
To keep the state identical on all nodes, the [wsrep API](http://galeracluster.com/documentation-webpages/glossary.html#term-wsrep-api) uses global transaction IDs (GTID), which are used to both:
* Identify the state change
* Identify the state itself by the ID of the last state change

The GTID consists of:
* A state UUID, which uniquely identifies the state and the sequence of changes it undergoes
 * An ordinal sequence number (seqno, a 64-bit signed integer) to denote the position of the change in the sequence

**Note** See Also: For more information on Global Transaction ID’s, see [wsrep API](http://galeracluster.com/documentation-webpages/architecture.html#id2).


##Incremental State Transfer
In an Incremental State Transfer (IST) a node only receives the missing write-sets and catch up with the group by replaying them. See also the definition for State Snapshot Transfer (SST).

**Note** See Also: For more information on IST’s, see [Incremental State Transfer (IST)](http://galeracluster.com/documentation-webpages/statetransfer.html#ist).


##IST
See [Incremental State Transfer](http://galeracluster.com/documentation-webpages/glossary.html#term-incremental-state-transfer).


##Logical State Transfer Method
Type of back-end state transfer method that operates through the database server. For example: `mysqldump`.

**Note** See Also: For more information see, [Logical State Snapshot](http://galeracluster.com/documentation-webpages/sst.html#sst-logical).


##Physical State Transfer Method
Type of back-end state transfer method that operates on the physical media in the datadir. For example: `rsync` and `xtrabackup`.

**Note** See Also: For more information see, [Physical State Snapshot](http://galeracluster.com/documentation-webpages/sst.html#sst-physical).


##Primary Component
In addition to single node failures, the cluster may be split into several components due to network failure. In such a situation, only one of the components can continue to modify the database state to avoid history divergence. This component is called the Primary Component (PC).

Note See Also: For more information on the Primary Component, see [Weighted Quorum](http://galeracluster.com/documentation-webpages/weightedquorum.html) for more details.


##Rolling Schema Upgrade
The rolling schema upgrade is a DDL processing method, where the DDL will only be processed locally at the node. The node is desynchronized from the cluster for the duration of the DDL processing in a way that it does not block the rest of the nodes. When the DDL processing is complete, the node applies the delayed replication events and synchronizes back with the cluster.

Note See Also: For more information, see [Rolling Schema Upgrade](http://galeracluster.com/documentation-webpages/schemaupgrades.html#rsu).


##RSU
See [Rolling Schema Upgrade](http://galeracluster.com/documentation-webpages/glossary.html#term-rolling-schema-upgrade).


##seqno
See [Sequence Number](http://galeracluster.com/documentation-webpages/glossary.html#term-sequence-number).


##sequence number
64-bit signed integer that the node uses to denote the position of a given transaction in the sequence. The seqno is second component to the [Global Transaction ID](http://galeracluster.com/documentation-webpages/glossary.html#term-global-transaction-id).


##SST
See [State Snapshot Transfer](http://galeracluster.com/documentation-webpages/glossary.html#term-state-snapshot-transfer).

##State Snapshot Transfer
State Snapshot Transfer refers to a full data copy from one cluster node (donor) to the joining node (joiner). See also the definition for Incremental State Transfer (IST).

**Note** See Also: For more information, see [State Snapshot Transfer (SST)](http://galeracluster.com/documentation-webpages/statetransfer.html#sst).


##State UUID
Unique identifier for the state of a node and the sequence of changes it undergoes. It is the first component of the [Global Transaction ID](http://galeracluster.com/documentation-webpages/glossary.html#term-global-transaction-id).


##TOI
See [Total Order Isolation](http://galeracluster.com/documentation-webpages/glossary.html#term-total-order-isolation).

##Total Order Isolation
By default, DDL statements are processed by using the Total Order Isolation (TOI) method. In TOI, the query is replicated to the nodes in a statement form before executing on master. The query waits for all preceding transactions to commit and then gets executed in isolation on all nodes simultaneously.

**Note** See Also: For more information, see [Total Order Isolation](http://galeracluster.com/documentation-webpages/schemaupgrades.html#toi).


##write-set
Transaction commits the node sends to and receives from the cluster.


##Write-set Cache
Galera stores write-sets in a special cache called Write-set Cache (GCache). In short, GCache is a memory allocator for write-sets and its primary purpose is to minimize the write set footprint on the RAM.

**Note** See Also: For more information, see [Write-set Cache (GCache)](http://galeracluster.com/documentation-webpages/statetransfer.html#gcache).


##wsrep API
The wsrep API is a generic replication plugin interface for databases. The API defines a set of application callbacks and replication plugin calls.

Note See Also: For more information, see [wsrep API](http://galeracluster.com/documentation-webpages/architecture.html#id2).

---

Come From：<http://galeracluster.com/documentation-webpages/glossary.html>

Note Time: 2015.11.11 12:27 Wensday