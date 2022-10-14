VODML Tooling TODO
==================

# vodml

* used twice in composition schematron rule should not necessarily matter
* clear up array intentions in multiplicity
* should only be a note for references multiplicity...aggregation
* unique constraint in composition...- would result in Set as the container.
* the rdb and xml schemas produced by the xslt are unlikely to match the java generated ones exactly - they need to be updated.
* vodml to specify attribute defaults?

* STC
  * epoch - not really defined as something that is used properly
  * equinox in spaceframe (only used for a few..)
  * names a bit confusing...
  * concrete types - the choice for a library?
  * polarization enum - not comprehensive - no L circular
  * AstroCoordSystem - is a CoordSys and has a CoordSys
  * no point on celestial sphere

# gradle plugin

* ~~get binding files from dependent jars~~
* write a usage note
* ~~publish in gradle repository~~
* ~~can remove all the ant stuff - including the libs and schematron dirs~~
* generate python
* integrate with the model mapping in VOT.


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
  * make the subsets create substitution group xml (i.e. have elements rather than xsi:type) http://blog.bdoughan.com/2010/11/jaxb-and-inheritance-using-substitution.html
  * don't allow to add to content something that is a reference? 
  * should dtypes be root elements? better to add to the modelElement....
  * not dealing with something that is a composition and also a reference 
    * should this be explicitly dis-allowed?
    * should back-references be put in automatically?
  * might want to be more explicit about namespaces in the <refs> and <content> areas....
  
* JPA 
  * embedded are not nullable - means that datatype with optional multiplicity is not handled well (i.e cannot be null!) https://hibernate.atlassian.net/browse/HHH-14818
    * see https://stackoverflow.com/questions/40979957/how-can-i-prevent-jpa-from-setting-an-embeddable-object-to-null-just-because-all?noredirect=1&lq=1 for the description of opposite
    * the way that this was worked around in proposalDM is to make the RealQuanity have nullable content - not ideal, but not too bad as unlikely to want to create a RealQuantity without both val and unit.
  * https://docs.jboss.org/hibernate/orm/5.4/userguide/html_single/Hibernate_User_Guide.html#fetching-strategies-dynamic-fetching-entity-graph - 
    https://thorben-janssen.com/fix-multiplebagfetchexception-hibernate/
    https://blog.jooq.org/no-more-multiplebagfetchexception-thanks-to-multiset-nested-collections/ - perhaps


#Python production

* using dataclasses - need python 3.10 for the kw_only field specifier - might do better just generating multiple  `__init__()` rather than relying on the dataclass generation.