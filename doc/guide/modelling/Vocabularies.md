Vocabularies
============

VO-DML supports vocabularies via the `<semanticconcept>` construct which can reference a vocabulary with its `<vocabularyURI>` element.

The tooling will add support for vocabularies in the generated Java code in that it generates code that checks if the values of attribute with an attached vocabulary does actually only contain terms from the vocabulary. There is support for the IVOA vocabularies that are published at [https://www.ivoa.net/rdf/](https://www.ivoa.net/rdf/), but the tooling currently only supports the IVOA specific [desise format](https://www.ivoa.net/documents/Vocabularies/20230206/REC-Vocabularies-2.1.html#tth_sEc3.2.1).

## Local Vocabularies

It might be the case that the vocabulary that is desired is not yet sufficiently mature to be published to the IVOA web site, or that it is desired that the vocabulary only ever be applicable to the current VO-DML model. In this circumstance the tooling is able to support local vocabularies (which still must be written in desise)

In order to reference a local vocabulary a special URN is used of the form

```
urn:vo-dml:MyModel!vocab:myvocab
```
where `MyModel` is the model name and `myvocab` is the vocabulary name.

This will instruct the tooling to look for a `myvocab.json` file in the `vocabularyDir` (which is by default the same directory as where the VO-DML files are found) of the MyModel model.

The vocabulary will then be added to the jar that is built.
