vodmltools
===========

This is a python package for manipulating VO-DML products.



## Developer Notes

build with

```shell
python -m build
```

editable dev env

```shell
python -m venv .venv
source .venv/bin/activate
pip install --editable .
```

Note that the xslt source which lives in a sibling directory ```../xslt``` to this is included by creating a symbolic link - it 
would be better if the setuptools allowed a way of including such directories, but it does not seem possible.

### Current Status

this version of the tooling is still very incomplete and some way from matching the ease of use of the gradle version (especially in terms of automatic inclusion of dependent models) however, a commandline that will run

```shell
 vodml schema --binding ../binding_notcoords_model.xml,../../models/ivoa/vo-dml/ivoa_base.vodml-binding.xml --deps ../../models/ivoa/vo-dml/IVOA-v1.0.vo-dml.xml  ../../models/sample/test/like_coords.vo-dml.xml 

```

note having to 


On Mac to get suitable dev env
```shell
docker run -it --delete -v /Users/pharriso/Work/ivoa/vodml-clean/:/vodml:rw --platform linux/amd64 python.:3.12-bookworm bash
```

* https://click.palletsprojects.com/en/stable/