VODML Tooling TODO
==================

# vodml

* schematron rules
  * used twice in composition schematron rule should not necessarily matter
  * should not even be warning (just a note!) for references multiplicity...aggregation OK when you know what you are doing ;)
  * should check that attribute name does not override supertype attribute.
  * attribute multiplicity OK if type primitive (should result in , separated list in DB)
* clear up array intentions in multiplicity
* multiple attribute can be OK (small fixed numbers) - happens for DTypes in coordinates for example...
* unique constraint in composition...- would result in Set as the container - are compositions assumed to contain unique members anyway - that is effectively what is happening in the JPA interpretation where a surrogate 
 key is used. In this case it might be a lifecycle issue. This is also the distinction between a datatype and an objectType.
* the rdb ~~and xml schemas~~ produced by the xslt are do not match the java generated ones exactly - they need to be updated.
* vodml to specify attribute defaults?
* semantic
  * need to overhaul the main meaning - need exact mapping to current vocabularies - more than just for lists for enums...
  * to generate tapschema - would be nice for vodml to have UCDs as part of the model - could be added in semantic part?
  * more general linking to RDF? - via CURIEs... special imports of ontologies....
    * possibly very small subset of OWL...
      * allow the idea of mix-ins/traits - small fragments that could be multiply-inherited to model things like hasParent
* ~~is subsetting references allowed? yes!~~
* idea of a oneOf/Choice
* idea of an Any type...
* idea of how unique the natural key is - see provenance model (for whole model or just the type)
  * ~~could make xmlid depend on type....~~
* constraints
  * add more simple ones - min, max, regexp..
* VODML Metamodel
  * different serializations of VO-DML itself (json top of list)
  * allow attributes to be 
  * perhaps standardize on the binding of the ivoa std primitives so that they do not need to be specified in the files
  * specialized "hand written" IVOA base schema
  * allow "schema fragments" in binding to cope with specialist overriding of primitives and some base dataTypes...
* consider what abstract means - perhaps use should be restricted. 
* Anything that might help in mapping to OPENAPI
  * idea of a "view" - eg. jobsummary in uws
  * OpenApi descriminators
* THE <IDENTIFIER> element is supposed to register specify an identifier by which it is registered - any IVOA std should be 
  in the standard namespace anyway - only use might be for arbitrary names - however this might be better done with "namespacing" of the model names...
* abstract Dtypes - any real meaning?...should be a warning...
 
* STC
  * epoch - not really defined as something that is used properly
  * equinox in spaceframe (only used for a few..)
  * names a bit confusing...
  * concrete types - the choice for a library?
  * polarization enum - not comprehensive - no L circular
  * AstroCoordSystem - is a CoordSys and has a CoordSys
  * no point on celestial sphere
  * RefLocation should not be a DataType

# gradle plugin

* ~~get binding files from dependent jars~~
* ~~write a usage note~~
* ~~publish in gradle repository~~
* ~~can remove all the ant stuff - including the libs and schematron dirs~~
* generate python
* integrate with the model mapping in VOT.
* ~~autogenerate the dependent vosdl files.~~
* ~~improve generated documentation~~
  * ~~add description of "is a ref", has subtypes etc....~~
* improve generation of vodsl from xsd
  * add better heuristics for dealing with restriction patterns
* Perhaps add a more general transformation of the VO-DML step prior to generation
  * could allow some more meta-modelling....

# Java Production

* deal with arrays (present array api, but store as arraylist for JAXB/JPA)
* compositions are not always Lists if @?
* nice pluralizations? https://github.com/atteo/evo-inflector
  * ~~for multiplicity > 1 rename method addToX~~ (also have list as argument)
* make source prettifier work.
* builders
  * add convenience builders for the lists.
  * try to make it difficult to keep creating references...
  *~~nothing is currently forcing the subsetting~~
  * ~~subsets not forced in some SRC coords~~ 
  * add constructor that misses out the optional attributes.
  * think again about the subsetting strategy and type safety
* ~~make semantic constraints work - i.e. look up the RDF....~~
* before and after serialization, the references need to be processed - it would be nice to do this automatically.... e.g. https://github.com/FasterXML/jackson-databind/issues/279 for jackson.
* references
  * would be nice if the tooling warned when contained references are created bare.... - e.g. the filters in the original sample.
* Vocabularies
  * would be good to add in off-line capability - store the desise at generation time and read that if the on-line not accessible
  * only does run-time checking - perhaps compile-time would be good?
* JAXB
  * ~~idrefs referred to objects are not being output - http://stackoverflow.com/questions/12914382/marshalling-unmarshalling-fields-to-tag-with-attributes-using-jaxb~~
  * make the subsets create substitution group xml (i.e. have elements rather than xsi:type) http://blog.bdoughan.com/2010/11/jaxb-and-inheritance-using-substitution.html
  * ~~don't allow to add to content something that is a reference?~~ 
  * ~~should dtypes be root elements? NO! better to add to the modelElement....~~
  * not dealing well with something that is a composition and also a reference in full model
    * at the moment the logic is conservative in that all references listed - leads to repetition in full model output - e.g. telescopes in proposaldm
    * has been improved from around 0.3.15
  * might want to be more explicit about namespaces in the <refs> and <content> areas....
  * can do better with subsets in subtypes - if supertype is abstract then it is possible to define in a subtype and get better type safety.
  * https://stackoverflow.com/questions/60402092/jackson-custom-deserializer-for-polymorphic-objects-and-string-literals-as-defau and https://stackoverflow.com/questions/18313323/how-do-i-call-the-default-deserializer-from-a-custom-deserializer-in-jackson
  * problem with the "lifecycle" example that is not present in json serialization - the contained and referenced example is output twice 
  * check whether optional elements are output as Null when not specified or just absent - have consistent policy for this accross all areas...


* JPA 
  * embedded are not nullable - means that datatype with optional multiplicity is not handled well (i.e cannot be null!) https://hibernate.atlassian.net/browse/HHH-14818
    * see https://stackoverflow.com/questions/40979957/how-can-i-prevent-jpa-from-setting-an-embeddable-object-to-null-just-because-all?noredirect=1&lq=1 for the description of opposite
    * the way that this was worked around in proposalDM is to make the RealQuantity have nullable content - not ideal, but not too bad as unlikely to want to create a RealQuantity without both val and unit.
    * the whole question is all rather subtle - the above workaround is not really very good - if single table inheritance strategy is used then
  * https://docs.jboss.org/hibernate/orm/5.4/userguide/html_single/Hibernate_User_Guide.html#fetching-strategies-dynamic-fetching-entity-graph - 
    https://thorben-janssen.com/fix-multiplebagfetchexception-hibernate/
    https://blog.jooq.org/no-more-multiplebagfetchexception-thanks-to-multiset-nested-collections/ - perhaps
  * arrays https://thorben-janssen.com/mapping-arrays-with-hibernate/
  * add more of the general JPA choices to mapping
    * discriminator column name for instance...
    * whether a type hierarchy should actually use @mappedSuperclass....
    * whether a type should be included at all.


* JSON
  * allow refs to be serialized/deserialized as ids always.... - for use in APIs.... https://stackoverflow.com/questions/51172496/how-to-dynamically-ignore-a-property-on-jackson-serialization
  * perhaps have custom written ivoa base schema.... express some better rules... e.g. non neg integer...
  * modern usage https://blogs.oracle.com/javamagazine/post/java-json-serialization-jackson


# Python production

* using dataclasses - need python 3.10 for the kw_only field specifier - might do better just generating multiple  `__init__()` rather than relying on the dataclass generation.

# Distribution
  * need better directory structure on IVOA site....


cannot upgrade to hibernate 6.6
https://hibernate.atlassian.net/browse/HHH-18899




