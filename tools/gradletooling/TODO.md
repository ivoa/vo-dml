VODML Tooling TODO
==================

# vodml

* used twice in composition schematron rule should not necessarily matter
* clear up array intentions in multiplicity
* should only be a note for references multiplicity...aggregation


# gradle plugin

* get binding files from dependent jars...
* write some documentation
* ~~publish in gradle repository~~
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
  * ~~subsets not forced in some SRC coords~~ 
  * add constructor that misses out the optional attributes.
* JAXB
  * ~~idrefs referred to objects are not being output - http://stackoverflow.com/questions/12914382/marshalling-unmarshalling-fields-to-tag-with-attributes-using-jaxb~~
  * make the subsets create substitution group xml (i.e. have elements rather than xsi:type)
  * don't allow to add to content something that is a reference? 
  * not dealing with something that is a composition and also a reference 
    * should this be explicitly dis-allowed?
    * should back-references be put in automatically?
* JPA 
  * embedded are not nullable - means that datatype with optional multiplicity is not handled well (i.e cannot be null!) https://hibernate.atlassian.net/browse/HHH-14818
    * see https://stackoverflow.com/questions/40979957/how-can-i-prevent-jpa-from-setting-an-embeddable-object-to-null-just-because-all?noredirect=1&lq=1 for the description of opposite
    * the way that this was worked around in proposalDM is to make the RealQuanity have nullable content - not ideal, but not too bad as unlikely to want to create a RealQuantity without both val and unit.
* STC
  * epoch - not really defined as something that is used properly
  * equinox in spaceframe (only used for a few..)
  * names a bit confusing...
  * concrete types - for a library?
  * polarization enum - not comprehensive - no L circular