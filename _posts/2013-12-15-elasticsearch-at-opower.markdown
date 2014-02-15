---
layout: post
title: Elasticsearch at Opower
author: ben.siemon
---

We use [Elasticsearch](http://www.elasticsearch.org/) to provide real time
analysis and segmentation of customer data. In the old world, we used handcrafted
SQL scripts to massage and gain insight into customer data. By using the
lightning fast query DSL of Elasticsearch, we are able to craft targeted queries
at a far higher level of abstraction than using raw SQL.

As we traveled the path of adopting Elasticsearch, we found a few places that
needed additional code to fit in with our technology stack at Opower. In this
post I will go over a few of these spots and how we chose to solve them.

### Spring

Spring has long since spread tendrils through the Opower code base. See
[Upgrading Spring](http://opower.github.io/2012/09/06/upgrading-from-spring-3-0-x-to-spring-3-1-x).
We needed a way to expose both indexing and search operations through services,
DAOs and other Spring idioms. We created a small set of Spring context files
that wire together a given
[Client](http://www.elasticsearch.org/guide/en/elasticsearch/client/java-api/current/client.html)
with services that provide thin wrappers around indexing and searching.

An abstraction built over the bulk index capabilities of the `Client` object could
be exposed via Spring like:

{% highlight java %}
public class ClientBackedBulkIndexer implements BulkIndexer {

    private Client client;

    public void index(Iterable<Map<String,Object>> documents) {
        //use the provided client to bulk index this stream of documents.
    }

    @Required
    public void setClient(Client client) {
        this.client = client;
    }
}
{% endhighlight %}

{% highlight xml %}
<bean id="client"
      class="com.opower.elasticsearch.ElasticSearchNodeClientFactoryBean"
      p:clusterName="${elasticsearch.clustername:elasticsearch}"
      p:hosts="${elasticsearch.hosts:localhost}">
     <description>Elasticsearch node</description>
</bean>

<bean id="bulkIndexer" class="com.opower.elasticsearch.utils.BulkIndexerImpl">
     <property name="client" ref="client"/>
</bean>
{% endhighlight %}

Using the dependency injection capabilities of Spring, we are able to
significantly DRY up usage of common Elasticsearch tasks. Without Spring, we end
up with methods that take a `Client`, index name and alias name sprinkled
everywhere. This is a fairly basic example but should provide an idea of what to
expect when using the out of the box Java `Client`.

### Index Creation and Maintenance

Immutability is one of the driving forces behind the speed and correctness of
Elasticsearch. However, embracing immutability comes with a price. When an index
is created, it is assigned an immutable number of shards. This is OK up to the
point that the size of your data in a given index grows beyond the capacity of
the configured shard count. At this point you are faced with a choice: scale up
or out. We developed a framework that allows us to easily scale indices out.

First we need a way to transparently add capacity to an index (or something)
without deleting it and recreating it with more shards assigned. Fortunately
Elasticsearch provides a built in primitive to solve this problem:
[aliases](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-aliases.html).
Each alias may be assigned a number of indices. Users then query the alias and
receives results from each underlying index. So using an alias, we are able to
transparently add more shards by adding new indices to the alias.

Now that we have a way to add new indices, and ultimately shards, we need a way
to create new indices that have identical mappings and settings. A simple way to
solve this problem would be to store the JSON definition that creates the index
in the jar or in some external datastore. We could then use this JSON document
to create new indices. This approach is simple but has a significant defect in
that it allows the model objects that represent our indexed documents to fall
out of sync. To solve this problem we created a set of annotations. These
annotations allow us to describe the mapping directly on the relevant Java
objects.

{% highlight java %}
/**
 * This is a simple test type.
 */
@ElasticSearchType(type = "simpleType", isRoot = true)
public class SimpleType extends ElasticSearchEntity {
     private DateTime dateTime;
     private byte aByte;
     private short aShort;
     private int anInt;
     private long aLong;
     private float aFloat;
     private double aDouble;
     public SimpleType(DateTime date, byte b, short s,
                         int i, long l, float f, double d) {
         super(null);
         this.dateTime = date;
         this.aByte = b;
         this.aShort = s;
         this.anInt = i;
         this.aLong = l;
         this.aFloat = f;
         this.aDouble = d;
     }

     @Field
     @JsonProperty("birth_day")
     public DateTime getDateTime() {
         return dateTime;
     }

     @Field
     public boolean isTrue() {
         return true;
     }

     @Field
     @JsonProperty("this_is_some_byte")
     @NullValue("10")
     public byte getaByte() {
         return aByte;
     }

     @Field
     @JsonProperty("this_is_a_short")
     public short getaShort() {
         return aShort;
     }

     @Field
     @JsonProperty("count")
     public int getAnInt() {
         return anInt;
     }

     @Field
     @JsonProperty("bigger_count")
     public long getaLong() {
         return aLong;
     }

     @Field
     @JsonProperty("floating_point_number")
     public float getaFloat() {
         return aFloat;
     }

     @Field
     @JsonProperty("ratio")
     public double getaDouble() {
         return aDouble;
     }

     public double getShouldNotAppear() {
         return 0;
     }

     public double getShouldNotAppearAlso() {
         return 0;
     }
}
{% endhighlight %}

Using these two components we can create a system that automatically provisions
new indices based on some user defined strategy. These strategies fall into two
rough categories.

#### Time Series Data

Time series data grows in proportion to the passage of time. Any initial shard
count will eventually run out of capacity since the data size is constantly
growing. Some examples of this are: log messages (See
[Logstash](http://logstash.net/)) and data import metadata.

{% highlight xml %}
<bean id="strategy"
      class="com.opower.elasticsearch.provisioning.TimeSeriesProvisionStrategy">
    <property name="client" ref="client"/>
</bean>

<bean id="indexProvisioningService"
      class="com.opower.elasticsearch.schema.SimpleIndexProvisioningService">
    <property name="client" ref="client"/>
    <property name="strategy" ref="strategy"/>
</bean>
{% endhighlight %}

In this case, the `TimeSeriesProvisionStrategy` checks the document count in the
active index then creates new indices if warranted. Consuming client code is only
required to call `indexProvisioningService.provisionIndex(...)`.

#### User data

User data grows in proportion to your user base. Initial shard counts could end
up fitting your needs, but that likely means your company is not growing. Let's
consider the more interesting case of growth. Ideally it is a simple matter of
setting a few configuration parameters to expand the capacity of your existing
index by automatically creating new shards.

{% highlight xml %}
<bean id="strategy" class="com.opower.elasticsearch.provisioning.UserDataProvisionStrategy">
    <property name="client" ref="client"/>
</bean>

<bean id="indexProvisioningService"
      class="com.opower.elasticsearch.schema.SimpleIndexProvisioningService">
    <property name="client" ref="client"/>
    <property name="strategy" ref="strategy" />
</bean>
{% endhighlight %}

In this case the `UserDataProvisionStrategy` checks the document count in the
index configured for the active client and chooses if more capacity should be
added.

### Optimizations and Best Practices

#### When returning all IDs from a query

By default, queries created by
[SearchRequestBuilder](https://github.com/elasticsearch/elasticsearch/blob/c7f6c5266d15fefa1a5ce9ae7ffc519c5ff8abbe/src/main/java/org/elasticsearch/action/search/SearchRequestBuilder.java)
will return all stored fields in the `getHits()`. If you are returning say 100k
documents from a query it can take up to a full minute to read all these
results. However, if you only need to access the document IDs you should call
`searchRequestBuilder.setNoFields()`. This informs Elasticsearch that you only
need the document IDs and knocks the query time down to as little as 2 seconds,
which is acceptable for our batch processing jobs.

#### Use static mappings

Out of the box, Elasticsearch is incredibly dynamic and malleable. These are
amazing features for POC work and getting to know Elasticsearch. Once you move
to a production system the lack of constraints becomes a liability. Using static
mapping forces indexing applications to only index data that conforms to the
original mapping. This prevents any bugs that result from out of sync indexing
code and existing indices.

#### Avoid repeated updates to existing documents

Say you have a document with 5 fields. You get each of these fields from 5
different places. The simplest solution would be:

1. read the first field
2. index a new document at some id
3. read the second field
4. read the original document from Elasticsearch
5. append second field to document
6. re-index
7. and so on

This approach creates 4 pieces of soft deleted junk in the underlying datastore
that ultimately must be cleaned up. It is better to avoid repeated indexing if
possible by reading each field, joining them together, then performing one index
operation.

### Here be dragons

Ultimately, our experience with Elasticsearch has been incredibly positive.
Development by the Elasticsearch core team and the community at large continues
at a breakneck pace. That being said, Elasticsearch is a relatively new
datastore and is not for the faint of heart. A ready appetite for reading the
core Elasticsearch code is your best friend in times of trouble.
