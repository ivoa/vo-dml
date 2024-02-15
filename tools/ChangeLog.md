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