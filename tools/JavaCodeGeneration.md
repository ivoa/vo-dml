Java Code Generation
====================

The tooling is capable of generating Java classes that can be used to store instances of the
models. The code is annotated to allow JAXB and JPA to operate, which mean that it is easy to 
read and write model instances to XML and standard relational databases. It should be noted that
the generated code uses java 1.8 constructs.

## Characteristics of the Generated code

In general the code creates POJOs or data classes - i.e. the classes have very little functionality
apart from being stores of the data model. The functionality that they do have is described below.

### Instance Creation

To be JPA and JAXB compliant, the classes are Java beans with a no argument constructor, so they can be 
default constructed and then getX/setX can be used on the properties.

```java
A a = new A();
a.setX(x);
a.setY(y);
```

In addition, there are several other ways of creating objects

#### Full constructor

A constructor with all the possible properties included is

```java
A a = new A(x,y,z);
```

#### Fluent with

Each property has a withX(X x) function

```java
A a = new A().withX(x).withY(y);
```

#### Fluent functional builder

```java
A a = A.builder( b -> {
         b.x = x;
         b.y = y;
         }
      );
```
It should be noted that this style becomes most desirable when there are attributes 
which themselves are of a non-primitive type.


### Reading and Writing XML

As well as all the individual enum, ObjectType, and DataType classes, there is
an overall ${modelname}Model class generated, that is intended to act as 
a 'container' for the individual elements. This is especially useful in the case
where the model has references, as then there are some convenience methods.

The overall model object will produce xml like
```xml
<MyModel>
    <refs>
        <aref1 id="1000">...</aref1>
        <aref1 id="1001">...</aref1>
    </refs>
    <contentObjectType1> ...</contentObjectType1>
    ...
</MyModel>
```

#### JAXBContext

A static function to create a suitable JAXBContext 
```java
JAXBContext jc = MyModel.contextFactory();
```

#### Functions for adding content
For each of the concrete objectTypes in the model there is 
an overloaded `addContent()` method, which will add the content to the 
overall instance and find any references.

Once all the content has been added, then there is a `makeRefIDsUnique()` method
which will go through the whole model and automatically assign IDs for any 
references that do not already have them. 

At this point the overall model object is suitable to be written out as XML.

On reading in a model instance, it is possible to extract any top level ObjectTypes
with the `public <T> List<T> getContent(Class<T> c)` method.

Finally, there is a static `public static boolean hasReferences()` method which
can be used to check if the model has any references - if it does not then much of the 
machinery above (apart from the JAXBContext) is not necessary, and individual ObjectTypes may be 
written.

### Reading and Writing from RDBs

The generated code has JPA annotations to allow storing in RDBs with compliant systems.

#### Embeddable dataTypes

The most natural way to represent dataTypes in JPA is as embeddable, this means that they do
not have a separate "identity" and are simply represented as columns within the parent entity table.
The problem with this is that JPA does not specifically allow inheritance of embeddables (though nor does it disallow). 
As a consequence the support for inherited embeddables is not uniform in JPA providers.

Hibernate seems to support the concept of embeddable hierarchies reasonably well by
naturally using the @MappedSuperclass annotation - although there is an irritation in that 
the full flexibility of having optional attributes that are dataTypes is not supported as all columns re
made non-nullable - I have submitted a bug https://hibernate.atlassian.net/browse/HHH-14818

There are also eclipselink bugs that mean that the suggested way of doing inherited embeddables does not seem to work.


