
# VODSL

## VODSL support in the gradle tools

There is a `vodslToVodml` task that will convert models authored in [vodsl](https://www.ivoa.net/documents/Notes/VODSL/) into standard VO-DML.

the configurable properties within the vodml extension are;

* vodslDir - the default is `src/main/vodsl`
* vodslFiles - this is set by default to be all the `*.vodsl` files in the vodslDir, but can be individually set.

the task will write the VO-DML files into the `vodmlDir`

Any dependencies that have VO-DML models within them will have their VO-DML automatically converted to VODSL
and placed in the `build/tmp` directory. Any target VODSL files will have to explicitly include the dependencies with a relative path into that directory.

If you want to have the VO-DML generated automatically from the VODSL rather than running this task manually, then

```kotlin
tasks.named("vodmlJavaGenerate") {
        dependsOn("vodslToVodml")
}
```
in the `build.gradle.kts` file would run the task before the Java generation for instance.

### Creating VODSL from existing VO-DML

If it is desired to create VODSL from some existing VO-DML then there is a special task that can be run from the
commandline with arguments (i.e. does not have to be configured in the `build.gradle` file as it would not be a repeated part of the workflow)
The task has the `--dml` parameter to indicate the input VO-DML file and the `--dsl` parameter to indicate the output VODSL file.

```shell
gradle vodmlToVodsl --dml=models/sample/sample/vo-dml/Sample.vo-dml.xml --dsl=test.vodsl 
```
The transformation attempts to be faithful, but the generated VODSL is likely to need some manual editing to clean it up. As stated above, this transformation is expected to be a "one-time" operation as although the generation of VO-DML from VODSL is well defined, the reverse has some areas of possible ambiguity especially with VO-DML that has been created not using this toolkit.

## VODSL language

The VODSL language use the same underlying meta-model as VO-DML but uses a mapping to a syntax that
makes it easier for humans to write by hand. It uses a general
C/Java-like syntax with the following characteristics;

- pairs of curly braces representing grouping

- attribute declarations ending with semi-colons `;`

- line comments introduced by `// comment`

- block comments `/* comment */`

- keywords

        model,author,include,package,abstract,primitive,dtype,
        otype,as,ordered,composition,enum,references,semantic,
        subset,title,iskey,ofRank

- attibute names precede their types

- `"documentation strings"` are enforced for all types

- multiplicities are introduced by `@`

The syntax of various parts of the language are described in the
following sections. For a fuller description of the semantics of the
language, the VO-DML standard itself should be consulted.

### Model Declaration

The model declaration includes the name of the model its version
followed by a description and then a number of authors.

``` vodsl
model example (0.1) "description here" 
   author "Paul Harrison"
   author "An Other"
   
   include "IVOA-v1.0.vodsl"
```

It will almost always be the case that there should be an include
statement that includes the standard IVOA VO-DML base model which
defines a number of fundamental primitive types. There can be additonal
includes to re-use parts of other models.

### Packages

Packages may be used to partition the namespace in a model. Is is not
required that all definitions live in a package as there is an assumed
“unnamed” which exists at the top-level of the model. Packages may be
nested.

``` vodsl
package p "package" {
    package n "nested package" {
   
    }
}
```

Note that the above fragment is not actually legal without the inner
package containing a type definition.

### Types

Types are defined by starting with the particular type keyword. Where
appropriate this might be preceded by `abstract` and if the type is a
sub-type of another type then after the type name the supertype is
indicated with `->`.

    abstract otype ad1 -> base "an abstract subtype "{  
    }

#### Primitives

``` vodsl
primitive angle "another primitive"
```

note the lack of a semi-colon at the end of this declaration.

#### Enumerations

``` vodsl
enum options "an enum" {
    val1 "first option",
    val2 "second option"
}   
```

#### DataTypes

DataTypes are defined with the “dtype” keyword. This definition also
introduces the syntax for attribute definitions, which are defined
between the curly braces of the main DataType definition.

``` vodsl
dtype myQuant -> ivoa:RealQuantity "a flagged quantity" {
            flag : ivoa:boolean "the flag" ;
}
```

#### ObjectTypes

ObjectTypes are defined with the “otype” keyword.

``` vodsl
otype o1 {
         /* the following attribute is a 'natural key' for the otype */
           name : ivoa:string iskey "the identifier";
               bv : ivoa:anyURI  "Description";
            /* note use of ^ to be able to 
                    re-use reserved word.*/ 
            ^author: ivoa:string "author"; 
}
```

This definition also introduces the `iskey` attribute modifier to hint
to any code generation systems that this attribute should be regarded as
a “natural key” for the ObjectType and used rather than generating a
surrogate key.

### Multiplicities

``` vodsl
otype multiplicities "the @ sign introduces a multiplicity"
{
    m1 : ivoa:integer @? "0 or 1";
    m2 : ivoa:integer @* "0 or many";
    m3 : ivoa:integer @+ "1 or many";
    m4 : ivoa:integer @[2] "twice (as an array?)";
}
```

### References and Compositions

This example shows the syntax for references and compositions and the
difference in their semantics.

``` vodsl


 /*  this referred to otype is not affected by the lifecycle
   of other instances in the model */
 otype ReferedTo { 
    test1: ivoa:integer "";
 }

/* instances of this contained class will only live
   as long as the containing instance.  */
otype Contained  {
    test2: ivoa:string "";
 }
 
otype RCTest { 
    ref references ReferedTo "";
    contained : Contained @+ as composition "";
}
```

### Subsetting

Subsetting is an advanced VO-DML feature, where an attribute of a
subtype can be declared to be a particular sub-type of the supertype’s
attribute type.

``` vodsl

otype subs -> base {
    /* note that the requirement to refer to the q attribute of base */
   subset base.q as myQuant; //the type of base.q is a supertype of myQuant
}
```

### Scoping

Type names need to be brought into scope by including the model where
they are defined, and thereafter they can be referred to by prefixing
the type name with the model name followed by a colon. Types defined in
the same model as where they are referred to do not need this model
prefix.

If the type is futher namepspaced by packages, then to refer to a type
in a package the enclosing package names should be separated by periods.
The use of a period to separate name parts is also necessary when
referring to an attribute of a type - e.g. when subsetting.[^2]




## Full example of VO-DSL

The following is the full model from which the sections above took
snippets.

``` vodsl
/*
 *  created on 25 Feb 2022 
 */
 
 model example (0.1) "description here" 
   author "Paul Harrison"
   author "An Other"
   
   include "IVOA-v1.0.vodsl"
   
package p "top level package" {
    package n "nested package" {
     primitive angle "another primitive"     
    }
}
   
enum options "an enum" {
    val1 "first option",
    val2 "second option"
}   

dtype aQuant -> ivoa:Quantity "an angle quantity" {
            value : p.n.angle  "angle";
}

abstract otype base {
            q : ivoa:Quantity "a quantity";   
}

abstract otype ad1 -> base "an abstract subtype "{  
}

otype o1 {
         /* the following attribute is a 'natural key' for the otype */
           name : ivoa:string iskey "the identifier";
               bv : ivoa:anyURI  "Description";
            /* note use of ^ to be able to 
                    re-use reserved word.*/ 
            ^author: ivoa:string "author"; 
}

dtype myQuant -> ivoa:RealQuantity "a flagged quantity" {
            flag : ivoa:boolean "the flag" ;
}

/* it should be noted in this example that
 * @* and @+ are not "recommended" for attributes - it 
   might be better to use composition of otypes - but this is 
   not always the case */
otype multiplicities "the @ sign introduces a multiplicity"
{
    m1 : ivoa:integer @? "0 or 1";
    m2 : ivoa:integer @* "0 or many";
    m3 : ivoa:integer @+ "1 or many";
    m4 : ivoa:integer @[2] "twice (as an array?)";
}

 /*  this referred to otype is not affected by the lifecycle
   of other instances in the model */
 otype ReferedTo { 
    test1: ivoa:integer "";
 }

/* instances of this contained class will only live
   as long as the containing instance.  */
otype Contained  {
    test2: ivoa:string "";
 }
 
/* this example references and contains the above types */
otype RCTest { 
    ref references ReferedTo "";
    contained : Contained @+ as composition "";
}

/* an example of subsetting */
otype subs -> base {
    /* note that the requirement to refer to the q attribute of base */
   subset base.q as myQuant; //the type of base.q is a supertype of myQuant
}

/* an example of the syntax for a constraint */
otype constrained {
            val : ivoa:integer "just using a natural language constraint" 
              < "greater than 5" as Natural> ;
        }

```
## Rationale for VODSL

VO-DML is the IVOA standard language for creating data models and the
standard document details the reasons behind its creation and the
advantages of using such a language over other more general languages
such as UML. The standard representation of VO-DML is XML and as such it
is difficult to edit model instances directly, especially as the XML is
a direct representation of the VO-DML meta model. The most common
practice envisaged by the standard is that data models are generally
created by visual UML tools and then the UML converted to VO-DML via the
XMI interchange format. This approach does work, but it has several
disadvantages.

1.  UML tools tend to have poor interoperability despite the standard
    XMI interchange format

    - There needs to be a specialized XMI $\Rightarrow$ VO-DML
      conversion written for each UML tool (and sometimes for each
      version of a particular tool).

    - It is difficult to “import” an existing VO-DML definition into a
      particular UML tool.

2.  Because of this poor interoperability between UML tools it is
    difficult for authors to collaborate on the creation of a data model

    - even if they are using the same tool and use XMI in a version
      control system, there is

    - if they are using different UML tools, comprehending what might be
      small incremental changes in the source becomes impossible.

3.  Commercial UML tools tend to be expensive, and the free ones less
    feature rich.

These difficulties were the inspiration for creating VODSL as a new
route to producing VO-DML with the following characteristics;

- Text based for easy management by version control systems.

- Concise, so that it is easy for direct comprehension by humans.

The VODSL language and its associated tools are version controlled in
[GitHub](https://github.com/pahjbo/vodsl) as well as some
[examples](https://github.com/ivoa/vodsl-models) of models expressed in
VODSL.

### Relationship to VO-DML

The [diagram in the introduction](modellingIntro.md) shows the role that VODSL plays in
the VO-DML creation ecosystem - The yellow arrows indicate
transformations that can be made programmatically between the different
formats, and the green arrows indicate ways in which the source can be
edited and the tools that can be used to create or edit that particular
representation. It shows that VODSL has a similar role to XMI/UML in the
creation of VO-DML, although with one significant advantage in that
there is an exact transformation VO-DML$\Rightarrow$VODSL.



| VODSL                                                    |     | UML                                                   |
|:---------------------------------------------------------|:----|:------------------------------------------------------|
| Easier to perform global refactoring                     | vs  | Easier to visualise the whole model                   |
| Instant validation[^1]                                   | vs  | Full validation only after XSLT transformation of XMI |
| Easier to merge contributions from two authors textually | vs  | Rely on UML tool to have model merging facility       |




[^1]: when using the Eclipse plug-in

