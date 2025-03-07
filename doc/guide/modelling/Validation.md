Model Validation
================

A model can be validated with the 

```shell
gradle vodmlValidate
```

command, and clearly if there are no errors then the model is unquestionably valid. However, if there are validation messages it does not necessarily mean that the model is definitely bad - The meaning of messages is discussed in more detail below. When publishing a model that has messages then it is necessary in the accompanying documentation to make clear what actions and choices have been made in mitigation of each of the messages (sometimes a complete "override" might be justified by the use of a custom type mapping in [binding](../Binding.md)).

## Validation Messages

Validation is done using schematron, which although quite powerful in its ability to detect patterns in the VO-DML, is rather limited in the way that messages can be displayed. This can cause some issues with interpretation of the messages, which this guide aims to clarify.

The validation messages can be divided into two categories

* fatal - must be corrected
* non-fatal - need some mitigation
### Fatal
TBC
### Non-Fatal
TBC