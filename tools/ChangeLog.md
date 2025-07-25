# Version history

* 0.2 java generation changed to cope with STC coords.
* 0.2.1 minor updates so that proposalDM generation works
* 0.2.2 make sure that the jpa override will work for mapped primitives - added extra attribute on the mapping
* 0.3.1 add the vodslToVodml task (0.3.0 would not publish because of SNAPSHOT dependency)
* 0.3.2 add the XmiTask type
* 0.3.3 bugfix for html document generation
* 0.3.4 the plugin now saves VO-DML and binding files to the created jar and then uses them if they are in dependency tree.
* 0.3.5 better working in the inherited data-model case.
* 0.3.6 JPA EntityGraphs
* 0.3.7 To VODSL task added
* 0.3.8 Add schema generation via the generated Java code.
* 0.3.9 Add JSON serialization.
* 0.3.10 Add possibility to do use "SingleTable" inheritance strategy for RDB schema
* 0.3.11 Add XSD to VODSL task.
* 0.3.12 allow references to be contained...
* 0.3.13 some bug fixes and different vodml metadata handling
* 0.3.14 proper JPA handling for generated primitives - added validation test for properly formed VODML-IDs
* 0.3.15 added JPA cloning, Java Copy Constructors, JSON improvements
* 0.3.16 Add microservices OpenAPI annotations, auto vodsl generation from model dependencies.
* 0.3.17 Stop JPA cascading to references + add convenience persistRefs() to help deal with that...
* 0.3.18 Restore the old xml schema generation for legacy applications.
* 0.3.19 Better model validation/testing support. Note also that makeRefIDsUnique() has been renamed to processReferences() to reflect the expanded functionality of the method.
* 0.3.20 updates to model documentation generation
* 0.3.21 General improvements/bug fixes as a result of processing a wider variety of models
* 0.3.22 add site documentation including mermaid diagrams
* 0.3.23 improved navigation in the generated site.
* 0.3.24 improved python generation - removed join tables.
* 0.4.0 move to jakarta namespace
* 0.4.1 Improved list API
* 0.4.2 Update the vodsl support to 0.4.6
* 0.4.3 Make work with windows
* 0.4.4 initial contained references support
* 0.4.5 
  * New binding customizations - length and isAttribute
  * new XML Schema generation
    * xml id handling includes vodmlid
    * take into account packages.
* 0.5.0 Json Schema Generation (+ new style XSD schema generation)
* 0.5.1 Fix validation regression
* 0.5.2 
    * update vodsl version 0.4.8
        * *vodsl breaking change* - model can have a title - title is now a keyword and needs to be escaped with caret if you want to use "title" as an attribute name for instance
        * ability to specify the ucd
        * *java breaking change* generated java code will have constructor arguments in vodsl order - this is a good thing ultimately!
* 0.5.3 
  * support aggregation of references - by a join table  
  * improve mkdocs site generation
  * fix Java bug where dtype hierarchies not having all members saved as embeddable in database.
* 0.5.4
  * add imported models to the generated site documentation
  * add link hover tips to the site docs
  * add multiplicities to site diagrams (but not working in Safari on MacOS - see https://github.com/ivoa/vo-dml/issues/52)
* 0.5.5
  *  allow binding to specify eager fetching for JPA
* 0.5.6
  * correct some file URIs for windows
* 0.5.7
  * Added support for validation against IVOA vocabularies
  * Added support for rdb serialization of primitive attributes with unbounded multiplicity as colon separated string
* 0.5.8 - a release mainly cleaning up some internals
* 0.5.9 - redo how references are managed.
* 0.5.10 
  * further reference management refinement
* 0.5.11
  * further reference management tweaks & fixed support for abstract base class cloning.
* 0.5.12
  * initial support for automatic RDB entity deletion taking into account need to delete the referrers to the contained references first.
* 0.5.13
  * update vodsl to 0.4.9 (inserts name and version into imports)
  * schematron checks the name and version in the imports
  * correct embedded reference overrides.
  * vocabularies downloaded at compile time for inclusion in jar.
    * default behaviour now is to only consult the compile-time version
  * add in wrapped XML serialization for compositions with multiplicity > 1
  * actually do JSON schema validation in the JSON round trip tests
    * there still needs to be some work in "tightening" the JSON schema.
* 0.5.14
  * make site diagrams from plantuml
  * add naturalJoin style to the ID column naming options
  * add ability to override table names to the binding.
  * preliminary tap schema support
    * initial tap schema produced as part of the vodmlSchema task - the schema is actually the XML serialization of the tap schema as defined in VO-DML https://github.com/ivoa/TAPSchemaDM
* 0.5.15
  * fix regression in DataType to column mapping
* 0.5.16
  * composition of multiplicity 1 treated as dataType option
  * make sure that the VO-DML is XML validated
  * TAP schema generation improved.
* 0.5.17
  * add support for setting elementFormDefault in XML schema - default is unqualified
  * add support for setting attributeFormDefault in XML schema - default is unqualified
* 0.5.18
  * add a small tweak to case handling in the XML serialization of compositions
  * only make naturalkeys  XMLIDs if actually necessary (i.e. referred to)
* 0.5.19
  * Add support for local vocabularies
  * Add XML schema support for wrapped attributes with multiplicity > 1
* 0.5.20
  * add binding option to ignore packages in XML serialization
* 0.5.21
  * some internal XSLT reorganisation to be compatible with python tooling
  * be able to specify the rdb schema for model in binding - the new default is to use the model name as the schema name
* 0.5.22
  * fix up mistake in tap schema naming
  * add some preliminary composite natural key handing - works for the tapschemaDM case, but needs to be further generalised.
  * add ability to customize join column name in binding.
  * make sure that Object/DataType members do appear in VO-DML declaration order
  * for list concatenation, add ability to specify delimiting character in binding.
  * remove the element level persistRefs - must be done at the top level - model.management().persistRefs(em)
* 0.5.23
  * fixed some TAPSchema generation errors
  * added the ability to run tests without persistence.xml - switch off generation of persistence.xml
  * move the TAPSchema to DDL XSLT into the TAPSchemaDM project
* 0.5.24
  * make the tap table name not include the schema in tapschema generation
    * supports composite natural keys from the composition hierarchy 
* 0.5.25
  * bug fix with tap schema generation.
* 0.5.26
  * Fix the key type in tap schema for sub-types
  * Add composedBy and referredTo links in the site diagrams
* 0.6.0
  * support hibernate 6.6 embeddable inheritance hierarchies https://docs.jboss.org/hibernate/orm/6.6/userguide/html_single/Hibernate_User_Guide.html#embeddable-inheritance - this is the first time that true dataType polymorphism is supported in RDB serialization.

