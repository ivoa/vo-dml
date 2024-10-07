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