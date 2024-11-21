Creating VO-DML from other Data Models
======================================

It is possible to start with an XML schema that can be transferred to VODSL with 

```shell
gradle vodmlXsdToVodsl --xsd `pwd`/mymodel.xsd --dsl mymodel.vodsl
```

Note that it is necessary to use the full path for the input file.


The transformation does not cope with all of the "styles" XML schema that are possible, so that it is likely that
the generated VODSL will need further hand editing.

