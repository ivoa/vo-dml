This project contains a definition of a VO Data Modelling Language, VO-DML.
The folder structure is as follows:

<root>

- ./build.xml
ant build file with targets used for generating a vo-dml representation of a particular type of model XMI file, 
as well as generating HTML and utype-s from the vo-dml representation.
See the file itself for explanation of its targets!

- ./build.properties
Simple properties file read by build.xml to decide which target model to generate from.
This file MUST define an 'input' property that should identify a folder with a data model inside of it.
It MAY define the 'graphviz.path' property that MUST point to a dot.exe application.
If this property is defined, an XSLT script will use GraphViz to generate a diagram from the model,
which is used by the generated HTML document.

-./doc/
Folder containing documents decribing VO-DML and its mapping to VOTable and use for UTYPE effort.

- ./models/
Folder containing specific IVOA models in VO-DML form together with generated HTML documentation.
Each model has its own folder.

Most (all) models are derived from an XMI file, contained in the model specific folder. 
All MUST contain a file called vo-dml.properties.
This file MUST contain a property named 'dm.filename.prefix'.
This prefix is assumed for all official data model documents.
First of all <dm.filename.prefix>.vo-dml.xml gives the name of the VO-DML representation of the model.
This is used as source for generation from the vo-dml rep to for example HTML.
It is used as target if one generates the vo-dml rep. from a UML/XMI representation.

All model subfolders in SVN SHOULD contain the vo-dml representation generated from the XMI. 
All SHOULD contain an HTML documentation file named <dm.filename.prefix>.html derived from the vo-dml file.
Most (all) contain a <dm.filename.prefix>.png file containing a diagram of the model derived from the vo-dml file using GraphViz.
This image is used inside the HTML file. 

IF one wants to generate the vo-dml rep from an XMI version of the model, the vo-dml.properties file MUST contain
a 'xmi.source' property, which must give the name of the XMI file. This name assumed to be relative to the folder.
Note, this name is NOT assumed to be named <dm.filename.prefix>.xml or so!
Some folders contain a ...-UML.png file. This is an image containing a diagram obtained from the 
MagicDraw CE 12.1 tool with which the XMI file was created.

The vo-dml.properties file MAY define a property named 'html.preamble'. If not null this should identify a file containing
an HTML snippet (form TBD) that will be inserted at a certain part of the generated HTML documentation.
It allows some customization of the data model documentaiton. Was used by SimDM effort. 
None of the current models have a preamble.

./models/ivoa_wg.css
A CSS file used by generated HTML documents.
Put here in SVN so that a relative link can be given to it from the generated HTML.

./models/xmi.css
A CSS file used by generated HTML documents.
Put here in SVN so that a relative link can be given to it from the generated HTML.

- ./models/profile
A special model containing definitions for most common primitive types.
Advise to be used by all other models as their main source for such primitive types.

- ./uml/
Contains various UML representations.

- ./uml/IVOA UML Profile v-3.xml
A MagicDraw UML profile that can be used inside of a MagicDraw data model.
Best start is to use a template model that is TBD


- ./xsd/
Contains XML definitions.

- ./xsd/vo-dml.xsd
Contains an XML schema defining the structure of the VO-DML representation of a data model.

- ./xsd/vo-dml.sch.xml
This file defines a Schematron schema containing validity rules that are hard or impossible to express in XML schema.
Used by the build.xml's 'validate_vo-dml' target.

- ./xslt/
This folder contains various XSLT scripts used in generating various artefacts.

- ./xslt/xmi2vo-dml.xsl
Contains XSLT that can generate a vo-dml representation from a properly defined UML model expressed in XMI.
It is shown to work with XMI generated using MagicDraw Community Edition 12.1.
Models defined in that tool MUST also use a particular UML "profile", defining stereotypes and tags for 
adding more specific features to our model. A template UML diagram will be provided.
TODO The details of the MagicDraw modelling must be documented in (much) more detail.
  For now you'd need assistance of Gerard Lemson or Laurent Bourges.
BUT note that it is NOT required to use UML, it is just one method to produce a vo-dml representation which is the
real core of the data model and the sole source of all further products.

Note. This script assigns utype-s to all model elements based on the XMI-id used for the element in the XMI model.
These are random strings, and have no structure. This script does NOT generate the more readable utype-s.
This script assigns this same ID string to the @id attribute of the <identifier> element containing the <utype> element.
All <utyperef> elements will use this same string to identify the referenced utype.
See below in the description of the generate-utypes4vo-dml.xsl script how these utype and utyperef elements are updated
with the human readable utype strings.

- ./xslt/common.xsl
XSLT script containing some common templates used by other scripts.

- ./xslt/generate-utypes4vo-dml.xsl
XSLT script that generates human readable utype-s for a vo-dml diagram and updates utyperef-s to use the proper
These currently still follow the UTYPE syntax propsed in the SimDM model, and in the "original" UTYPEs document.
Its main role is to produce a human readable, guaranteed unique set of utypes that 
Is currently used in the build.xml's run_xmi2vo-dml target to update the utype-s using the opaque @id strings.
Since one may define a utype explicitly in XMI and the derived the vo-dml model, only those utypes are updated for which the 
utype value is equal to the value of the @id attribute in the containing <identifier> element.

The @id attribute is NOT required, maybe we should remove it from vo-dml.xsd

- ./xslt/utype.xsl
A utyility XSLT script containing some templates used in generating utypes from the vo-dml rep.

- ./xslt/vo-dml2modelproxy.xsl
an XSLT script that takes a vo-dml model and generates a model proxy file.
PLEASE IGNORE FOR NOW as its use very much depends on an assumed structure of imported models in vo-dml that 
should be discussed further.

- ./xslt/vo-dml2html.xsl
XSLT script that generates a default HMTL document from a vo-dml representation.
Is completely cross linked, contains all element (should at least).
Each element has an <a name="[utype]"> anchor in front of its definition.
This is assumed in the HTML generation when links to external models are created.
TODO expand on this description.

- ./xslt/vo-dml2gvd.xsl
An XSLT script used to generate a so called GVD file that describe a model diagram from the vo-dml representation
accpordiong to GraphViz GVD format.
This file is used by GraphViz to generate an image for the model.
It also (in the build.xml's run_vo-dml2gvd target) generates a map of the image
that is inserted into the HTML to create a cross linking between diagram and data model element in the HTML document.

