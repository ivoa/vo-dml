vodmltools
===========

This is a python package for manipulating VO-DML products.



## Developer Notes

build with

```shell
python -m build
```

Note that the xslt source which lives in a sibling directory ```../xslt``` to this is included by creating a symbolic link - it 
would be better if the setuptools allowed a way of including such directories, but it does not seem possible.