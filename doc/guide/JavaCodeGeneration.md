Java Code Generation
====================

The tooling is capable of generating Java classes that can be used to store instances of the
models. The code is annotated to allow JAXB and JPA to operate, which mean that it is easy to 
read and write model instances to XML and standard relational databases. It should be noted that
the generated code uses java 1.8 constructs.

The generated Java code depends on the [VO-DML java runtime library](https://github.com/ivoa/vo-dml/tree/master/runtime/java), which the plugin will automatically add to the
dependencies along with the necessary JAXB and JPA libraries.

## Generating The Java code

The command
```shell
gradle vodmlJavaGenerate
```
will generate java code in `./build/generated/sources/vodml/java` which is on the build classpath and so 
```shell
gradle build
```
will compile and run tests on the generated code. In fact `gradle build` will 
automatically run `gradle vodmlJavaGenerate` if the code is out of date because the model has been updated.

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
In addition there is a copy constructor, and for subclasses there is a constructor with arguments
that consist of a superclass instance as well as the local members.

#### Fluent 

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


## Serializing Models

As well as all the individual Enum, ObjectType, and DataType classes, there is
an overall ${modelname}Model class generated, that is intended to act as 
a 'container' for the individual elements. This is especially useful in the case
where the model has references, as then there are some convenience methods for dealing with the
automatic setting of reference IDs if necessary.

### Functions for adding content
For each of the concrete objectTypes in the model there is
an overloaded `addContent()` method, which will add the content to the
overall instance and find any references.

Once all the content has been added, then there is a `processReferences()` method
which will go through the whole model and automatically assign IDs for any
references that do not already have them.

At this point the overall model object is suitable to be serialized.

On reading in a model instance, it is possible to extract any top level ObjectTypes
with the `public <T> List<T> getContent(Class<T> c)` method.

!!! note "contained references"

    There is some provisional support for "contained references" when cloning an object - the API for this 
    is subject to change, but an example is used in [copyTest](https://github.com/ivoa/vo-dml/blob/53cf97613b4201d9bb72863fa8f132ff5650c17b/tools/gradletooling/sample/src/test/java/org/ivoa/dm/lifecycle/LifeCycleDetailedTest.java#L100) using the `createContext()` and `updateClonedReferences()` methods either side of an object clone with a copy constructor.

Finally, there is a static `public static boolean hasReferences()` method which
can be used to check if the model has any references - if it does not then much of the
machinery above (apart from the JAXBContext) is necessary, and individual ObjectTypes may be
written.

The [unit tests](https://github.com/ivoa/vo-dml/tree/master/tools/gradletooling/sample/src/test/java/org/ivoa/dm/sample/catalog/SourceCatalogueTest.java) for this project show most of the various code features being used

### XML Serialization

A static function to create a suitable JAXBContext is present
```java
JAXBContext jc = MyModel.contextFactory();
```

### JSON Serialisation
The JSON serialization is implemented with the [Jackson](https://github.com/FasterXML/jackson) library

A suitable ObjectMapper is obtained with
```java
ObjectMapper mapper = MyModel.jsonMapper();
```


## Reading and Writing from RDBs

The generated code has JPA annotations to allow storing in RDBs with compliant systems.

Operations are not in general cascaded into references - so that the references need to be explicitly managed. In most cases this will be the "natural" way to do things 
for the model - however at creation time it might be inconvenient to do this so that there is a method
`persistRefs(jakarta.persistence.EntityManager _em)` on the model that will do a deep persist of any references in the child objects, which in turn then will allow an error free persist of the content. Note that in general it is only possible to run the persistRefs once all of the content has been added to the model, and only for the first time a reference is created - for subsequent updates of the model it will be necessary to manage the references manually. 

In general collections are marked for lazy loading, and as a convenience there is a `forceLoad()`
method generated that will do a deep walk of all the collections in a particular type, which will force the loading of the whole instance tree if that is desired.

This extra JPA functionality is described by the [JPAManipulations](https://github.com/ivoa/vo-dml/tree/master/runtime/java/src/main/java/org/ivoa/vodml/jpa/JPAManipulations.java) interface.

### Composition Helpers

Some convenience methods are created on the object that is the parent of compositions to make dealing with JPA updates easier.

```java
class X {
   public void replaceInY(final Y _p) {...}
}
```
Where Y is a composition type and the instance _p is not in the current JPA context (e.g has been deserialized from JSON), then
the assuming that the deserialized object contains a valid database key, the member of the composition will be updated in a way that is suitable for a JPA merge.

Internally this makes use of another convenience function 

```java
class Y {
   public void updateUsing ( final Y other){...}
}
```
that will update this with all the values from other.

### Embeddable dataTypes

The most natural way to represent dataTypes in JPA is as embeddable, this means that they do
not have a separate "identity" and are simply represented as columns within the parent entity table.
The problem with this is that JPA does not specifically allow inheritance of embeddables (though nor does it disallow the use). 
As a consequence the support for inherited embeddables is not uniform in JPA providers.

Hibernate seems to support the concept of embeddable hierarchies reasonably well by
naturally using the `@MappedSuperclass` annotation - although there is an irritation in that 
the full flexibility of having optional attributes that are dataTypes is not supported as all columns are 
made non-nullable - a bug has been submitted https://hibernate.atlassian.net/browse/HHH-14818

### TAP schema

The TAP schema is available as an XML serialization according to the [TAPSchemaDM](https://github.com/ivoa/TAPSchemaDM) using 
```java
Model.TAPSchema();
```

## Testing models

The java runtime has a number of [base classes](https://github.com/ivoa/vo-dml/tree/master/runtime/java/src/main/java/org/ivoa/vodml/testing) that aid the testing of model instances - there is an [example for the mock coords model](https://github.com/ivoa/vo-dml/tree/master/tools/gradletooling/sample/src/test/java/org/ivoa/dm/notstccoords/CoordsModelTest.java).
Although it is not obvious from the source code presented because most of the behaviour is inherited
from the base test class, this test will actually

* round trip the model instance to JSON
* round trip the model instance to XML
* validate the model instance

simply by running

```shell
gradle test
```

will generate the actual model code (if not already done) and run the tests as long as

```kotlin
tasks.test {
    useJUnitPlatform()
}
```
is set up in the `build.gradle.kts` file.

## General interfaces

Much of the functionality described above is defined in two interfaces
[ModelManagement](https://github.com/ivoa/vo-dml/blob/master/runtime/java/src/main/java/org/ivoa/vodml/ModelManagement.java) an 
instance of which can be obtained with the `management()` method on the model class and
[ModelDescription](https://github.com/ivoa/vo-dml/blob/master/runtime/java/src/main/java/org/ivoa/vodml/ModelDescription.java) an
instance of which can be obtained with the `description()` method on the model class.
These interfaces allow generic model handling code to be written.

