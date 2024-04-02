IVOA Standard Doc
-----------------

This directory contains the source of the VO-DML standard - for 1.0 this was in MS-Word docx format. Going forward
the standard will be in a text editable format.

Pandoc has been used to create the markdown [VO-DML.md](./VO-DML.md) which should considered as the starting point
to the next version of the document, as it already contains some minor corrections (restricted in the XML examples).

Pandoc will probably be used to create the latex version from this markdown for standard ivoatex processing - however,
it should be noted that it is easier to create richer HTML from the markdown. For instance

```shell
pandoc VO-DML.md -s --css=https://www.ivoa.net/misc/ivoa_rec.css --toc -N  -o test.html
```

Pandoc TODO
------------

* number appendices separately https://gist.github.com/rauschma/458303094cd87cab077c00c061cce8da