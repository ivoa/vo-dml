Designing Models
================

Creating "good" data model designs is an art rather than a science. Within the context of the IVOA reusing existing recommended models is a prerequisite for a model be considered good.

The initial test as to whether a model is good is to run [validation](Validation.md) which will point out areas of the design that need to be carefully considered as well as outright errors.

## Purpose of the Model

The intended purpose of the model will affect the overall design 

* Data Discovery
* Data Labelling
* Data Modelling.

## Testing serialization.

The java runtime has some functionality for [roundtrip testing](../JavaCodeGeneration.md#testing-models) the various serializations 
which can be a good first level test as to whether your model is a "good design".