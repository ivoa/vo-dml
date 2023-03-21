Java Code Generation
====================

The tooling is capable of generating Java classes that can be used to store instances of the
models. The code is annotated to allow JAXB and JPA to operate, which mean that it is easy to 
read and write model instances to XML and standard relational databases. It should be noted that
the generated code uses java 1.8 constructs.

The generated Java code depends on the [VO-DML java runtime library](../runtime/java), which the plugin will automatically add to the
dependencies along with the necessary JAXB and JPA libraries.

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
A a = new A(x,y);
```

#### Fluent with

Each property has a withX(X x) function

```java
A a = new A().withX(x).withY(y);
```

#### Fluent functional builder

A static builder that takes a functional argument.

```java
A a = A.createA( b -> {
         b.x = x;
         b.y = y;
         }
      );
```
It should be noted that this style becomes most desirable when there are attributes 
which themselves are of a non-primitive type.


### Serializing Models

As well as all the individual Enum, ObjectType, and DataType classes, there is
an overall ${modelname}Model class generated, that is intended to act as 
a 'container' for the individual elements. This is especially useful in the case
where the model has references, as then there are some convenience methods.
#### Functions for adding content
For each of the concrete objectTypes in the model there is
an overloaded `addContent()` method, which will add the content to the
overall instance and find any references.

Once all the content has been added, then there is a `makeRefIDsUnique()` method
which will go through the whole model and automatically assign IDs for any
references that do not already have them.

At this point the overall model object is suitable to be serialized.

On reading in a model instance, it is possible to extract any top level ObjectTypes
with the `public <T> List<T> getContent(Class<T> c)` method.

Finally, there is a static `public static boolean hasReferences()` method which
can be used to check if the model has any references - if it does not then much of the
machinery above (apart from the JAXBContext) is necessary, and individual ObjectTypes may be
written.

The [unit tests](./gradletooling/sample/src/test/java/org/ivoa/dm/sample/catalog/SourceCatalogueTest.java) for this project show most of the various code features being used

#### XML Serialization

A static function to create a suitable JAXBContext is present
```java
JAXBContext jc = MyModel.contextFactory();
```

#### JSON Serialisation
The JSON serialization is implemented with the [Jackson](https://github.com/FasterXML/jackson) library

A suitable ObjectMapper is obtained with
```java
ObjectMapper mapper = MyModel.jsonMapper();
```


### Reading and Writing from RDBs

The generated code has JPA annotations to allow storing in RDBs with compliant systems.

In general collections are marked for lazy loading, and as a convenience there is a `forceLoad()`
method generated that will do a deep walk of all the collections in a particular type, which will force the loading of the whole instance tree if that is desired.

A second convenience method that is created to make it easy to clone an entity is show below
```java
 MyEntity to_clone = entityManager.find(MyEntity.class, ID);
 to_clone.jpaClone(entityManager);
 entityManager.merge(to_clone);
```
which will create a new entity along with any contained compositions, but will maintain the original references.

#### Embeddable dataTypes

The most natural way to represent dataTypes in JPA is as embeddable, this means that they do
not have a separate "identity" and are simply represented as columns within the parent entity table.
The problem with this is that JPA does not specifically allow inheritance of embeddables (though nor does it disallow the use). 
As a consequence the support for inherited embeddables is not uniform in JPA providers.

Hibernate seems to support the concept of embeddable hierarchies reasonably well by
naturally using the `@MappedSuperclass` annotation - although there is an irritation in that 
the full flexibility of having optional attributes that are dataTypes is not supported as all columns are 
made non-nullable - a bug has been submitted https://hibernate.atlassian.net/browse/HHH-14818

There are also eclipselink bugs that mean that the suggested way of doing inherited embeddables does not seem to work.

#### General interfaces

Much of the functionality described above is defined in two interfaces
[ModelManagement](../runtime/java/src/main/java/org/ivoa/vodml/ModelManagement.java) an 
instance of which can be obtained with the `managmenent()` method on the model class and
[ModelDescription](../runtime/java/src/main/java/org/ivoa/vodml/ModelDescription.java) an
instance of which can be obtained with the `description()` method on the model class.
These interfaces allow generic model handling code to be written.

