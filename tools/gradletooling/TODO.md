VODML Tooling TODO
==================

# vodml

* used twice in composition schematron rule should not necessarily matter
* clear up array intentions in multiplicity

# gradle plugin

* get binding files from dependent jars...
* write some documentation
* publish in gradle repository
* can remove all the ant stuff - including the libs and schematron dirs

# Java Production

* deal with arrays (present array api, but store as arraylist for JAXB/JPA)
* compositions are not always Lists if @?
* nice pluralizations? https://github.com/atteo/evo-inflector
* make source prettifier work.
* builders
  * add convenience builders for the lists.
  * try to make it difficult to keep creating references...
  *~~nothing is currently forcing the subsetting~~
* JAXB
  * ~~idrefs referred to objects are not being output - http://stackoverflow.com/questions/12914382/marshalling-unmarshalling-fields-to-tag-with-attributes-using-jaxb~~
  * make the subsets create substitution group xml (i.e. have elements rather than xsi:type)
* JPA 
  * 