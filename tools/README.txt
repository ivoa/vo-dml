UNDER CONSTRUCTION (GL 2014-04-23)
----------------------------------

This project contains a definition of a VO Data Modelling Language, VO-DML, 
models built accoring to the language and various scripts to validate these and build derived data products from them.
The folder structure is as follows:

<root>

- ./build.xml
ant build file with targets used for generating a vo-dml representation of a particular type of model XMI file, 
as well as generating HTML and utype-s from the vo-dml representation.
See the end of this file for an explanation of the main ant targets.

- ./build.properties
See documentation inside the file and the description of build.xml at the end of this file.

-./doc/
Folder containing VO-DML and UTYPE specifications, as well as some earlier document mainly created during the utype tiger team.

-./doc/examples/
Folder containing some example VOTable documents with various types of UTYPE based annotation.
Also files containing object instantiations derived from such VOTable files. 

- ./models/
Folder containing specific IVOA models in VO-DML form together with generated HTML documentation.
Each model has its own folder.

Most models are derived from an XMI file, contained in the model specific folder. 
Each folder MUST contain a file called vo-dml.properties so that the ant tasks can use it.
This file MUST contain a property named 'dm.filename.prefix', which governs the names of all generated files:
 <dm.filename.prefix>.vo-dml.xml gives the name of the VO-DML representation of the model.
This is used as source for generation from the vo-dml/xml rep to for example HTML.
It is used as target if one generates the vo-dml/xml. from a UML/XMI representation.

All sub-folders of model/  SHOULD contain the vo-dml/xml representation generated from the XMI or written by hand. 
All SHOULD contain an HTML documentation file named <dm.filename.prefix>.html derived from the vo-dml/xml file.
Most (all) contain a <dm.filename.prefix>.png file containing a diagram of the model derived from the vo-dml/xml file using GraphViz.
This image is used inside the HTML file. 

IF one wants to generate the vo-dml/xml from an XMI version of the model, the vo-dml.properties file MUST contain
a 'xmi.source' property, which must give the name of the XMI file. This name is assumed to be relative to the folder.
Note, this name is NOT assumed to be named <dm.filename.prefix>.xml!
Some folders contain a ...-UML.png file. This is an image containing a diagram obtained from the 
MagicDraw CE 12.1 tool with which the XMI file was created.

The vo-dml.properties file MAY define a property named 'html.preamble'. If this value is set it should identify a file containing
an HTML snippet (form TBD) that will be inserted at a certain part of the generated HTML documentation.
It allows some customization of the data model documentation. Was used by SimDM effort. 
None of the current models have a preamble.

./models/ivoa_wg.css
A CSS file used by generated HTML documents.
Put here in SVN so that a relative link can be given to it from the generated HTML.

./models/xmi.css
A CSS file used by generated HTML documents.
Put here in SVN so that a relative link can be given to it from the generated HTML.

- ./models/ivoa
A special model containing definitions for most common primitive types as well as for quantity.
SHOULD be used by all other models as their main source for such primitive types.

- ./uml/
Contains a UML profile that should be used by all MagicDraw CE 12.1 UML representation in models/ if they should be compiled using the
xmi2vo-dml.xsl script.

- ./uml/IVOA UML Profile v-3.xml
A MagicDraw UML profile that can be used inside of a MagicDraw data model.
Best start for creating a new UML model that can be used as source for the xmi2vo-dml.xsl script 
however is to use a template model in ./models/template 


- ./xsd/
Contains XML schema and Schematron file defining the formal VO-DML/XML representation.

- ./xsd/vo-dml.xsd
Contains an XML schema defining the structure of the VO-DML representation of a data model.

- ./xsd/vo-dml.sch.xml
This file defines a Schematron schema containing validity rules that are hard or impossible to express in XML schema.
Used by the build.xml's 'validate_vo-dml' target.

- ./xsd/vo-dml-instance.xsd
Contains an XML schema defining the structure of basic instantiations of VO-DML data models.

- ./xsd/vo-dml.mapping.xsd
Contains an XML schema defining the structure of the mapping file used by XSLT processor and 
various Java classes used for manipulating models and their instances.



- ./xslt/
This folder contains various XSLT scripts used in generating various artefacts.

- ./xslt/xmi2vo-dml_MD_CE_12.1.xsl
Contains XSLT that can generate a vo-dml representation from a properly defined UML model expressed in XMI.
It is shown to work with XMI generated using MagicDraw Community Edition 12.1.
Models defined in that tool MUST also use a particular UML "profile", defining stereotypes and tags for 
adding more specific features to our model. A template UML diagram will be provided.
TODO The details of the MagicDraw modelling must be documented in (much) more detail.
  For now you'd need assistance of Gerard Lemson or Laurent Bourges.
BUT note that it is NOT required to use UML, it is just one method to produce a vo-dml representation which is the
real core of the data model and the sole source of all further products.

Note. This script assigns a vodml-id to all model elements based on the XMI-id used for the element in the XMI model.
These are random strings, and have no structure. This script does NOT generate the more readable vodml-id values.
This script assigns this same ID string to the @id attribute of the <identifier> element containing the <vodml-id> element.
All <utype> elements will use this same string to identify the referenced <vodml-id>.
The more readable path expressions for the vodml-id elements is generated by the generate-utypes4vo-dml.xsl script.
See below how that works.

- ./xslt/xmi2vo-dml_Modelio_UML2.4.1.xsl
Script that generates vo-dml form UML created by Modelio when designed according to some pattern mimicking the profile
defined for MagicDraw. Seems to work (though not craegullt tested) for Mark's Modelio models for Cube/ImageDM.

- ./xslt/common.xsl
XSLT script containing some common templates used by other scripts.

- ./xslt/generate-utypes4vo-dml.xsl
XSLT script that generates human readable values for the <vodml-id> elements for a vo-dml diagram and updates <utype> values accordingly.
These follow the path syntax defined in appendix D of the VO-DMl spec, which itself is based on the UTYPE syntax proposed 
in the SimDM model, and in the "original" UTYPEs document.
Its main role is to produce a human readable value that are guaranteed unique within the context of a <model> element. 
This value is generated only for <vodml-id> elements that have an @id attribute that has the same value as the element itself.
This is to avoid updating <vodml-id> elements that have an explicitly defined value defined e.g. in the original UML/XMI model.

- ./xslt/utype.xsl
A utility XSLT script containing some templates used in generating utypes from the vo-dml rep.


- ./xslt/vo-dml2html.xsl
XSLT script that generates a default HMTL document from a vo-dml representation.
Is completely cross linked, contains all element (should at least).
Each element has an <a name="[utype]"> anchor in front of its definition.
This is assumed in the HTML generation when links to external models are created.
TODO expand on this description.
CAN include a table with possible paths. NOTE do not do that for STC!!!

- ./xslt/vo-dml2gvd.xsl
An XSLT script used to generate a so called GVD file that describe a model diagram from the vo-dml representation
accordiong to GraphViz GVD format.
This file is used by GraphViz to generate an image for the model.
It also (in the build.xml's run_vo-dml2gvd target) generates a map of the image
that is inserted into the HTML to create a cross linking between diagram and data model element in the HTML document.

- ./xslt/vo-dml2pojo.xsl
Generates "perfectly ordinary java" class definitions based on the models and the mapping_file.xml.
Have a deepToString method for serializing the objects to an XML format compatible with ./xsd/vo-dml-instance.xml.
Have generic property getters and setters ...
TBC
${models}
- HOW TO compile.
Need to generate java code for ivoa model, move this to source before calling ant compile, as custom java/src classes need it.

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++  How to use build.xml and description of its targets  +++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
1. check out complete vo-dml project from SVN. URL = https://volute.googlecode.com/svn/trunk/projects/dm/vo-dml/
2. ensure one has ant installed. versions tested are 1.8, 1.9
3. configure build.properties file according to description in SVN version.
4. if one has an XMI file built according ot one of the supported profiles (MD_CE_12.1 or Modelio_UML2.4.1), 
run the corresponding run_xmi2vo-dml_[XMI-spec] target. 
5. run run_vo-dml2html to generate HTML documentation.
6. run run_vo-dml2pojo to generate Java classes. Needs properly defined mapping file, see example in
https://volute.googlecode.com/svn/trunk/projects/dm/vo-dml/java/gen/mapping_file.xml
7. especially when written by hand, vo-dml files should be validated.
Target run_validate_vo-dml does so. Will indicate XSD violations in console, 
will write schematron rule violations in file indicated by console massage.
