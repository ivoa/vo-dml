<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:map="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="map" 
                >
<!-- 
  This XSLT script transforms a data model in VO-DML/XML representation to 
  Python dataclasses

  N.B this script is fragile to indentation (because of python - there should probably be a better way to get indentation to work)

  needs Python 3.7
  
  Paul Harrison (JBO)
-->


  <xsl:output method="text" encoding="UTF-8" indent="yes" />
  <xsl:output name="packageInfoJ" method="text" encoding="UTF-8"/>

  <xsl:strip-space elements="*" />


  <xsl:param name="lastModified"/>
  <xsl:param name="lastModifiedText"/>
  <xsl:param name="output_root" />
  <xsl:param name="vo-dml_package" select="'org.ivoa.vodml.model'"/>
  <xsl:param name="binding"/>
    <xsl:param name="isMain"/>
   <xsl:include href="binding_setup.xsl" />


    <xsl:variable name="root_package" select="$mapping/map:mappedModels/model[name=$themodelname]/python-package"/>
    <xsl:variable name="root_package_dir" select="replace($root_package,'[.]','/')"/>


  <!-- main pattern : processes for root node model -->
    <xsl:template match="/">
  <xsl:message >Generating Python - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,' and ')" /></xsl:message>
  <xsl:apply-templates mode="intro"/>
 </xsl:template>

  <!-- model pattern : generates gen-log and processes nodes package and generates the ModelVersion class and persistence.xml -->
  <xsl:template match="vo-dml:model" mode="intro">
    <xsl:message>
-------------------------------------------------------------------------------------------------------
-- Generating Python code for model <xsl:value-of select="name"/> [<xsl:value-of select="title"/>].
-- last modification date of the model <xsl:value-of select="lastModified"/>
-------------------------------------------------------------------------------------------------------
    </xsl:message>


      <xsl:if test="not($mapping/map:mappedModels/model[name=$themodelname])">
          <xsl:message terminate="yes">
              There is no binding for model <xsl:value-of select="$themodelname"/>
          </xsl:message>
      </xsl:if>
       <!--
          <xsl:message>root_package = <xsl:value-of select="$root_package"/></xsl:message>
          <xsl:message>root_package_dir = <xsl:value-of select="$root_package_dir"/></xsl:message>
       -->


<!--       <xsl:apply-templates select="." mode="modelClass">-->
<!--          <xsl:with-param name="root_package" select="$root_package"/>-->
<!--          <xsl:with-param name="root_package_dir" select="$root_package_dir"/>-->
<!--      </xsl:apply-templates>-->
      <xsl:apply-templates select="." mode="packageDesc"/>
      <xsl:apply-templates select="." mode="content"/>
  </xsl:template>




  <xsl:template match="vo-dml:model|package" mode="content">

      <xsl:variable name="file" select="concat($root_package_dir, '/',string-join(./ancestor-or-self::*/name,'_') , '.py')"/>
      <xsl:variable name="package-vodml-ref" select="concat(./ancestor-or-self::vo-dml:model/name,':',string-join(./ancestor-or-self::package/name,'.'))"/>
      <xsl:message>package = <xsl:value-of select="concat(name,' ',$file,' ',$package-vodml-ref)"></xsl:value-of></xsl:message>
      <xsl:result-document href="{$file}">
<xsl:text>
import dataclasses
from enum import Enum

</xsl:text>
          <xsl:for-each select="distinct-values((*/((attribute|reference|composition|constraint[contains(@xsi:type,'SubsettedRole')])/datatype/vodml-ref)|*/extends/vodml-ref))">
              <xsl:if test="not(vf:isPythonBuiltin(.))">
                  <xsl:variable name="typepackage" select="concat(substring-before(.,':'),':',string-join(tokenize(substring-after(.,':'),'\.')[position() != last()],'.'))"/>
                  <xsl:choose>
                      <xsl:when test="(not(vf:hasMapping(.,'python')) and $typepackage = $package-vodml-ref)   ">
class <xsl:value-of select="vf:PythonType(.)"/><xsl:text>: pass # forward reference</xsl:text>
                      </xsl:when>
                      <xsl:otherwise>
                          <xsl:variable name="fulltype" select="vf:FullPythonType(.,true())"/>
from <xsl:value-of select="vf:PythonModule(.)"/> import <xsl:value-of select="tokenize($fulltype, '\.')[last()]"/>
                      </xsl:otherwise>
                  </xsl:choose>
              </xsl:if>
          </xsl:for-each>


          <xsl:apply-templates select="objectType|dataType|enumeration|primitiveType" mode="file"/>
      </xsl:result-document>
      <xsl:apply-templates select="package" mode="content"/>

  </xsl:template>


  <xsl:template match="objectType|dataType|enumeration|primitiveType" mode="file">

    <xsl:variable name="vodml-id" select="vodml-id" />
    <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
    <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'python')"/>
    <xsl:choose>
    <xsl:when test="not($mappedtype) or $mappedtype = ''" >
      <xsl:message >Writing code for <xsl:value-of select="name"/> base=<xsl:value-of select="vf:baseTypes($vodml-ref)/name"/> haschildren=<xsl:value-of select="vf:hasSubTypes($vodml-ref)"/> contained=<xsl:value-of select="vf:isContained($vodml-ref)"/> referredto=<xsl:value-of select="vf:referredTo($vodml-ref)"/> </xsl:message>
      <xsl:apply-templates select="." mode="content"/>
    </xsl:when>
      <xsl:otherwise>
       <xsl:message>1) Mapped type for <xsl:value-of select="$vodml-ref"/> = '<xsl:value-of select="$mappedtype"/>'</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template match="attribute|composition|reference" mode="paramDecl">
      <xsl:variable name="type" select="vf:PythonType(datatype/vodml-ref)"/>
      <xsl:choose>
          <xsl:when test="name()='composition' and multiplicity/maxOccurs != 1" >
              <xsl:choose>
                  <xsl:when test="vf:isSubSetted(vf:asvodmlref(.))">
                      <xsl:value-of select="concat(name,' : list[',$type, '] =field(default_factory=list, kw_only=True)')" />
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:value-of select="concat(name,' : list[',$type, '] =field(default_factory=list, kw_only=True)')" />
                  </xsl:otherwise>
              </xsl:choose>

          </xsl:when>
          <xsl:otherwise>
              <xsl:choose>
                  <xsl:when test="xsd:int(multiplicity/maxOccurs) gt 1">
                      <xsl:value-of select="concat(name,' : list[',$type, ']=field(default_factory=list, kw_only=True)')" /> <!-- IMPL arrays are just lists for now -->
                  </xsl:when>
                  <xsl:when test="multiplicity/maxOccurs = -1">
                      <xsl:value-of select="concat(name,' : list[',$type, ']=field(default_factory=list, kw_only=True) ')" />
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:value-of select="concat(name, ': ',$type)" />
                  </xsl:otherwise>
              </xsl:choose>

          </xsl:otherwise>
      </xsl:choose>

  </xsl:template>

    <!-- template class creates a java class (JPA compliant) for UML object & data types -->
  <xsl:template match="objectType|dataType" mode="content">
    <xsl:param name="path"/>
    <xsl:variable name="vodml-ref"><xsl:apply-templates select="vodml-id" mode="asvodml-ref"/></xsl:variable>
    <xsl:text>
</xsl:text>
    <xsl:call-template name="vodmlAnnotation"/><xsl:text>

@dataclasses.dataclass</xsl:text><xsl:if test="@abstract"><xsl:text>(init=False)</xsl:text></xsl:if>
class <xsl:value-of select="name"/>
      <xsl:if test="extends"><xsl:value-of select="concat('(',vf:PythonType(extends/vodml-ref),')')"/></xsl:if>:
    """
    * <xsl:apply-templates select="." mode="desc" />
    *
    * <xsl:value-of select="name()"/>: &bl;<xsl:value-of select="name" />
    *
    * <xsl:value-of select="$vodmlauthor"/>
    """
      <xsl:if test="local-name() eq 'objectType' and not (extends) and not(attribute/constraint[ends-with(@xsi:type,':NaturalKey')])" >

          <xsl:if test="vf:referredTo($vodml-ref)">
           </xsl:if>

      </xsl:if>
<!-- 
      /** serial uid = last modification date of the UML model */
      private static final long serialVersionUID = LAST_MODIFICATION_DATE;
 -->
      <xsl:apply-templates select="(attribute|composition|reference)[multiplicity/minOccurs=1 and multiplicity/maxOccurs=1]" mode="declare" /> <!-- attempt to get required before optional -
                        does not work for class hierarchies, see https://stackoverflow.com/questions/51575931/class-inheritance-in-python-3-7-dataclasses-->
      <xsl:apply-templates select="(attribute|composition|reference)[not(multiplicity/minOccurs=1 and multiplicity/maxOccurs=1)]" mode="declare" />
      <xsl:apply-templates select="constraint[ends-with(@xsi:type,':SubsettedRole')]" mode="declare" />
<!--      <xsl:apply-templates select="." mode="constructor"/>-->


      <xsl:if test="vf:referredTo($vodml-ref) and attribute/constraint[ends-with(@xsi:type,':NaturalKey')]">
          <!--TODO deal with multiple natural keys -->
          <!-- TODO this assumes that the natural key is a string -->

      </xsl:if>

      <xsl:if test="not(@abstract)">
      </xsl:if>
  </xsl:template>




  <xsl:template match="enumeration" mode="content">
    <xsl:param name="dir"/>
    <xsl:param name="path"/>
      <xsl:text>


class </xsl:text><xsl:value-of select="concat(name,'(Enum):')"/>
    """
    * <xsl:apply-templates select="." mode="desc" />
    *
    * Enumeration <xsl:value-of select="name"/> :
    *
    * <xsl:value-of select="$vodmlauthor"/>
    """
<xsl:apply-templates select="literal"  />
&cr;
   </xsl:template>

  <xsl:template match="primitiveType" mode="content">
    <xsl:param name="path"/>
    <xsl:variable name="valuetype">
      <xsl:choose>
        <xsl:when test="extends">
          <xsl:value-of select="vf:PythonType(extends/vodml-ref)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>Primitive type <xsl:value-of select="name"/> is being represented as a String - in general it is probably best to specialize primitive types with the binding mechanism to get desired representation/behavious</xsl:message>
            <xsl:value-of select="'str'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      <xsl:call-template name="vodmlAnnotation"/><xsl:text>


@dataclasses.dataclass
class </xsl:text><xsl:value-of select="name"/>:
    """
    *  <xsl:apply-templates select="." mode="desc" />
    *  PrimitiveType <xsl:value-of select="name"/> :
    *
    *  <xsl:value-of select="$vodmlauthor"/>
    """

    value: <xsl:value-of select="$valuetype"/>


  </xsl:template>


    <xsl:template match="attribute" mode="declare">
        <xsl:variable name="type" select="vf:PythonType(datatype/vodml-ref)"/>
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
        <xsl:if test="not(vf:isSubSetted($vodml-ref))">
            <xsl:text>
    </xsl:text>
            <xsl:call-template name="vodmlAnnotation"/>
            <xsl:choose>
                <xsl:when test="xsd:int(multiplicity/maxOccurs) gt 1">
                    <xsl:value-of select="concat(name, ': list[',$type,'] =dataclasses.field(default_factory=list, kw_only=True)')"/> <!-- IMPL arrays are just lists for now -->
                </xsl:when>
                <xsl:when test="xsd:int(multiplicity/maxOccurs) lt 0">
                    <xsl:value-of select="concat(name, ': list[',$type,'] =dataclasses.field(default_factory=list, kw_only=True)')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(name,': ',$type)"/>
                    <xsl:if test="vf:isOptional(.)"><xsl:text> =  dataclasses.field(kw_only=True, default=None)</xsl:text></xsl:if>
                </xsl:otherwise>
            </xsl:choose>
    """
     Attribute <xsl:value-of select="name"/> : multiplicity <xsl:apply-templates select="multiplicity" mode="tostring"/>

        <xsl:apply-templates select="." mode="desc"/>
    """
        </xsl:if>
    </xsl:template>


    <xsl:template match="constraint[ends-with(@xsi:type,':SubsettedRole')]" mode="declare">
        <!-- FIXME subsets can also be of compositions and references - worry about multiplicity-->
        <xsl:variable name="subsetted" select="$models/key('ellookup',current()/role/vodml-ref)"/>
        <xsl:if test="name($subsetted)='attribute' and datatype/vodml-ref != $subsetted/datatype/vodml-ref"> <!-- only do this if types are different (subsetting can change just the semantic stuff)-->
            <xsl:variable name="javatype" select="vf:PythonType(datatype/vodml-ref)"/>
            <xsl:variable name="name" select="tokenize(role/vodml-ref/text(),'[.]')[last()]"/>
            <xsl:text>
    </xsl:text>
            <xsl:value-of select="concat($name,': ',$javatype)"/><xsl:text>
    """</xsl:text>
    * Attribute <xsl:value-of select="name"/> : subsetted
    *
            <xsl:apply-templates select="$subsetted" mode="desc"/>.
    """
        </xsl:if>
    </xsl:template>






    <xsl:template match="composition[multiplicity/maxOccurs != 1]" mode="declare">
        <xsl:variable name="type" select="vf:PythonType(datatype/vodml-ref)"/>
        <xsl:call-template name="vodmlAnnotation"/><xsl:text>

    </xsl:text>
        <xsl:choose>
            <xsl:when test="vf:isSubSetted(vf:asvodmlref(.))">
                <xsl:value-of select="concat(name, ': list[',$type,']=dataclasses.field(default_factory=list, kw_only=True)')"/> # IMPL is subsetted
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(name, ': list[',$type,']=dataclasses.field(default_factory=list, kw_only=True)')"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>
    """
    *
    * Composition </xsl:text><xsl:value-of select="name"/> : ( Multiplicity : <xsl:apply-templates select="multiplicity" mode="tostring"/>)
    <xsl:apply-templates select="." mode="desc"/>
    *
    """

    </xsl:template>

    <xsl:template match="composition[multiplicity/maxOccurs = 1]" mode="declare">
        <xsl:variable name="type" select="vf:PythonType(datatype/vodml-ref)"/>
        <xsl:call-template name="vodmlAnnotation"/>
        <xsl:text>

    </xsl:text>
        <xsl:value-of select="concat(name,': ',$type,' = dataclasses.field(kw_only=True, default=None)')"/><xsl:text>
    """
    * Composition </xsl:text><xsl:value-of select="name"/> : ( Multiplicity : <xsl:apply-templates select="multiplicity" mode="tostring"/>)
    *
    *    <xsl:apply-templates select="." mode="desc" />
    """

    </xsl:template>








  <xsl:template match="reference" mode="declare"><!-- IMPL could be the same as attribute - actually more usefully so if reference allowed to have >1 multiplicity -->
    <xsl:variable name="type" select="vf:PythonType(datatype/vodml-ref)"/>
    <xsl:call-template name="vodmlAnnotation"/><xsl:text>
    </xsl:text>
      <xsl:value-of select="concat(name, ': ', $type)"/><xsl:text>
    """
    * ReferenceObject </xsl:text><xsl:value-of select="name"/> :
    * <xsl:apply-templates select="." mode="desc" />
    * ( Multiplicity : <xsl:apply-templates select="multiplicity" mode="tostring"/>) """
  </xsl:template>



    <xsl:template match="literal" >
    <xsl:variable name="up">
      <xsl:call-template name="constant">
        <xsl:with-param name="text" select="name"/>
      </xsl:call-template>
    </xsl:variable>
        <xsl:text>
    </xsl:text><xsl:value-of select="$up"/> = <xsl:value-of select="count(preceding-sibling::literal)"/>
    """
    * Value <xsl:value-of select="name"/> :
    *
    * <xsl:apply-templates select="." mode="desc" />
    """
  </xsl:template>






  <xsl:template match="*" mode="desc">
    <xsl:choose>
      <xsl:when test="count(description) > 0 and normalize-space(description) != 'TODO : Missing description : please, update your UML model asap.'">
          <xsl:value-of select="description" disable-output-escaping="yes"/>
          <xsl:if test="not(ends-with(normalize-space(description/text()), '.'))">
              <xsl:value-of select="'.'"/>
          </xsl:if>
      </xsl:when>
      <xsl:otherwise>
<!--       <xsl:message >TODO : <xsl:value-of select="name"/> Missing description : please, update your VO-DML model asap.</xsl:message> -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>  




  <!-- specific documents --> 

 

  <xsl:template match="vo-dml:model" mode="packageDesc">
      <xsl:variable name="file" select="concat($root_package_dir,'/__init__.py')"/>
      <!-- open file for this class -->
      <xsl:message >Writing package info file <xsl:value-of select="$file"/></xsl:message>
      <xsl:result-document href="{$file}" >
"""
          <xsl:value-of select="title"/>

          <xsl:value-of select="description"/>
"""
     </xsl:result-document>
  </xsl:template>








   <xsl:template name="vodmlAnnotation">
     <!-- nothing for now -->
 </xsl:template>


</xsl:stylesheet>
