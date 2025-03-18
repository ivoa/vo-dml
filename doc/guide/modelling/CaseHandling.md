Character Case Conventions
==========================

## VO-DML

In general the style guide for VO-DML is that CamelCase is used.

* attributes (and other type members)  should start with lowercase letter.
* ObjectTypes and DataTypes are expected to start with an uppercase letter.

## VO-DML tools

In general the VO-DML tools try to manipulate case as little as possible, but the there are some cases where it is more natural to make changes. These cases are detailed below.


### XML serialization

* when there is an enclosing element for a composition
    - The enclosing element takes its name from the composition name
    - each element in the composition takes its name from the type of the composition - however, this would lead to a mixture of case styles, so the initial letter of the type is transformed to lowercase.