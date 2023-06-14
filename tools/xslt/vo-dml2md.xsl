<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
<!ENTITY nbsp "&#160;">
<!ENTITY tab "&#160;&#160;&#160;&#160;">
]>
<!-- 
This stylesheet will create markdown description of the model, primarily targeted at
further processing by mkdocs to produce complete model documentation.
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
    xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"

>
    <xsl:output method="text" encoding="UTF-8" indent="no" />
    <xsl:output method="xml" encoding="UTF-8" indent="no" name="svgform" omit-xml-declaration="true" />

  <xsl:param name="binding"/>
  <!-- IF Graphviz png and map are available use these  -->
  <xsl:param name="graphviz_png"/>
    <xsl:variable name="modname">
        <xsl:choose>
            <xsl:when test="/vo-dml:model/vodml-id"><xsl:value-of select="/vo-dml:model/vodml-id"  /></xsl:when>
            <xsl:otherwise><xsl:value-of select="/vo-dml:model/name"  /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:param name="modelsToDocument" select="$modname"/>

    <xsl:variable name="docmods" as="xsd:string*">
        <xsl:sequence select="tokenize($modelsToDocument,',')"/>
    </xsl:variable>

    <xsl:variable name="thisModelName" select="/vo-dml:model/name"/>

  <xsl:include href="binding_setup.xsl"/>
  

  <xsl:template match="/">
    <xsl:message>Starting Markdown documentation for <xsl:value-of select="vo-dml:model/name"/> </xsl:message>
    <xsl:apply-templates select="vo-dml:model"/>
  </xsl:template>
  

  
  <xsl:template match="vo-dml:model">
# <xsl:value-of select="name"/>
&bl;
## Introduction

<xsl:value-of select="description"/>
&bl;
### Authors

<xsl:for-each select="author">
* <xsl:value-of select="author"/>
</xsl:for-each>

    <xsl:if test="$graphviz_png">

&bl;
### Overview diagram

The whole model is represented in a model diagram below


 <!-- IMPL should create temp file name -->
  <xsl:result-document format="svgform" href="/tmp/test.svg">
  <xsl:apply-templates select="document($graphviz_png)" mode="svg"/>
  </xsl:result-document>
  <xsl:value-of select="unparsed-text('/tmp/test.svg')"/>

    </xsl:if>

<xsl:if test="//primitiveType">
## Primitives

    <xsl:for-each select="//primitiveType">
        <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
</xsl:if>

      <xsl:if test="//enumeration">

## Enums

    <xsl:for-each select="//enumeration">
        <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
      </xsl:if>

      <xsl:if test="//dataType">

## DataTypes

    <xsl:for-each select="//dataType">
        <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
      </xsl:if>

      <xsl:if test="//objectType">

## ObjectTypes

    <xsl:for-each select="//objectType">
    <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
      </xsl:if>
      <!-- now main doc for each type in separate files -->
     <xsl:apply-templates select="(primitiveType|enumeration|dataType|objectType|package)"/>
  </xsl:template>

  <xsl:template match="primitiveType|enumeration|dataType|objectType">
      <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
      <xsl:variable name="hr" select="concat($vodml-id[1],'/',$vodml-id[2],'.md')"/>
      <xsl:message>writing description to <xsl:value-of select="$hr"/></xsl:message>
      <xsl:result-document method="text" encoding="UTF-8" indent="no" href="{$hr}">
          <xsl:apply-templates select="current()" mode="desc"/>
      </xsl:result-document>

  </xsl:template>
    <xsl:template match="package">
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:variable name="hr" select="concat($vodml-id[1],'/',$vodml-id[2],'.md')"/>
        <xsl:message>writing description to <xsl:value-of select="$hr"/></xsl:message>
        <xsl:result-document method="text" encoding="UTF-8" indent="no" href="{$hr}">
            <xsl:apply-templates select="current()" mode="desc"/>
        </xsl:result-document>
        <xsl:apply-templates select="(primitiveType|enumeration|dataType|objectType|package)"/>
    </xsl:template>

  <xsl:template match="primitiveType|enumeration|dataType|objectType" mode="desc">
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
# <xsl:if test="@abstract">_abstract_</xsl:if>  <xsl:value-of select="concat(' ', name(),' ', name)"/>

      <xsl:if test="extends">
          &cr;<xsl:text>extends </xsl:text>
          <xsl:apply-templates select="extends/vodml-ref"/>
          &cr;
      </xsl:if>

      <xsl:apply-templates select="description"/>
      <xsl:apply-templates select="current()" mode="mermdiag"/>
<xsl:if test="name() != 'primitiveType'">

## Members

|      name | type | mult | description |
|-----------|------|------|-------------|
      <xsl:apply-templates select="* except(description|name|extends|vodml-id)"/>

    <xsl:if test="constraint[@xsi:type='vo-dml:SubsettedRole']">

## Subset Detail

        <xsl:apply-templates select="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="ssdetail"/>
    </xsl:if>
</xsl:if>


  </xsl:template>
    <xsl:template match="package" mode="desc">
# Package <xsl:value-of select="concat(name,$nl)"/>

        <xsl:apply-templates select="description"/>

        <xsl:if test="package">

## Contained packages

            <xsl:for-each select="package">
* <xsl:value-of select="concat('[',name,'](',name,'.md)')"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="description">
        &cr;&cr;
        <xsl:if test="not(matches(text(),'^\s*TODO'))"><xsl:value-of select='.'/></xsl:if><xsl:text></xsl:text>
    </xsl:template>

    <xsl:template match="enumeration|dataType|objectType" mode="mermdiag">
&cr;&cr;
```mermaid
classDiagram
    <xsl:apply-templates select="current()" mode="merm"/>
```
&cr;
    </xsl:template>

    <xsl:template match="enumeration" mode="merm">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        class <xsl:value-of select="name"/>{
           &lt;&lt;enumeration&gt;&gt;&cr;
           <xsl:for-each select="literal">
               <xsl:value-of select="concat(name,$nl)"/>
           </xsl:for-each>
        }
    </xsl:template>
    <xsl:template match="dataType|objectType" mode="merm">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:variable name="thisClass" select="name"/>
        class <xsl:value-of select="name"/>{
        <xsl:if test="name()= dataType">
        &lt;&lt;dataType&gt;&gt;&cr;
        </xsl:if>
        <xsl:apply-templates select="(attribute|constraint)" mode="merm"/>
        }
        <xsl:call-template name="doSupers"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doSubs"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doRefs"/>
        <xsl:call-template name="doComposition"/>
    </xsl:template>

    <xsl:template match="attribute" mode="merm">
        <xsl:value-of select="concat(datatype/vodml-ref,' ',name,$nl)"/>
    </xsl:template>
    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="merm">
        <xsl:value-of select="concat(datatype/vodml-ref,' ',vf:nameFromVodmlref(role/vodml-ref),$nl)"/>
    </xsl:template>

    <xsl:template match="constraint" mode="merm">
        <!-- don't display general constraints -->
    </xsl:template>

    <xsl:template match="attribute|reference|composition">
        <xsl:text> | </xsl:text>
        <xsl:value-of select="name"/>
        <xsl:text> | </xsl:text>
        <xsl:apply-templates select="datatype/vodml-ref"/>
        <xsl:text> | </xsl:text>
        <xsl:apply-templates select="multiplicity"/><xsl:if test="@isOrdered"><xsl:text> ordered</xsl:text></xsl:if>
        <xsl:text> | </xsl:text>
        <xsl:value-of select="string-join(for $s in description/text() return normalize-space($s),' ')"/>
        <xsl:text> | </xsl:text> &cr;
    </xsl:template>

    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']">
        <xsl:text> | </xsl:text>
        <xsl:value-of select="vf:nameFromVodmlref(role/vodml-ref)"/>
        <xsl:text> | </xsl:text>
        <xsl:apply-templates select="datatype/vodml-ref" /><xsl:text> | </xsl:text>
        <xsl:apply-templates select="multiplicity"/><xsl:if test="@isOrdered"><xsl:text> ordered</xsl:text></xsl:if>
        <xsl:text> | </xsl:text>
        <xsl:value-of select="string-join(for $s in description/text() return normalize-space($s),' ')"/>
        <xsl:text> | </xsl:text> &cr;
    </xsl:template>

    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="ssdetail">

### <xsl:value-of select="vf:nameFromVodmlref(role/vodml-ref)"/>
          <xsl:variable name="subSettedTypeId" select="string-join(tokenize(role/vodml-ref,'[.]')[position() != last()],'.')"/>
        <xsl:variable name="subsettedThing" as="element()">
            <xsl:copy-of select="$models/key('ellookup',current()/role/vodml-ref)" />
        </xsl:variable>
Subsets <xsl:value-of select="concat(vf:nameFromVodmlref(role/vodml-ref), ' in ',vf:doLink($subSettedTypeId), ' from type ')"/>
        <xsl:value-of select="concat(vf:doLink($subsettedThing/datatype/vodml-ref), ' to ',vf:doLink(current()/datatype/vodml-ref))"/>

    </xsl:template>

    <xsl:template match='vodml-ref'>
        <xsl:value-of select="vf:doLink(.)"/>
    </xsl:template>

    <xsl:template match="literal">
 *  <xsl:value-of select="name"/><xsl:text> </xsl:text><xsl:apply-templates select="description"/>&cr;
    </xsl:template>

    <xsl:template match="extends">
        <!-- nothing in general description -->
    </xsl:template>

    <xsl:template match="semanticconcept">
        <xsl:text>semantic "</xsl:text><xsl:value-of select="topConcept"/><xsl:text>" in "</xsl:text><xsl:value-of select="vocabularyURI"/><xsl:text>"</xsl:text>
    </xsl:template>




    <xsl:template match="constraint">
        <!-- dont output in notmal mode-->
    </xsl:template>

    <xsl:template match="constraint" mode="desc">
        <xsl:text>constraint  </xsl:text><xsl:apply-templates select="description"/>
    </xsl:template>


    <xsl:template match="multiplicity">
        <xsl:choose>
            <xsl:when test="number(minOccurs) eq 1 and number(maxOccurs) eq 1"><!-- do nothing --></xsl:when>
            <xsl:when test="number(minOccurs) eq 0 and number(maxOccurs) eq 1"> optional</xsl:when>
            <xsl:when test="number(minOccurs) eq 0 and number(maxOccurs) eq -1"> 0 or more </xsl:when>
            <xsl:when test="number(minOccurs) eq 1 and number(maxOccurs) eq -1"> 1 or more </xsl:when>
            <xsl:otherwise><xsl:value-of select="concat('[',minOccurs,'..', maxOccurs,']')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- mermaid diagrams -->
    <xsl:template name="doSupers">
        <xsl:param name="vodml-ref"/>
        <xsl:if test="vf:hasSuperTypes($vodml-ref)">
            <xsl:variable name="thisClass" as="element()">
                <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
            </xsl:variable>
            <xsl:variable name="bases" select="vf:baseTypeIds($vodml-ref)"/>
            <xsl:value-of select="concat($thisClass/name,' --|',$gt,' ',vf:nameFromVodmlref($bases[1]),$nl)"/>
            <xsl:for-each select="1 to count($bases) -1">
                <xsl:value-of select="concat(vf:nameFromVodmlref($bases[xsd:integer(current())]),' --|',$gt,' ',vf:nameFromVodmlref($bases[xsd:integer(current())+1]),$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template name="doSubs">
        <xsl:param name="vodml-ref"/>
        <xsl:if test="count(//*[extends/vodml-ref = $vodml-ref]) > 0">
            <xsl:variable name="thisClass" as="element()">
                <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
            </xsl:variable>
            <xsl:for-each select="for $x in //*[extends/vodml-ref = $vodml-ref] return vf:asvodmlref($x) ">
                <xsl:value-of select="concat(vf:nameFromVodmlref(current()),' --|',$gt,' ',$thisClass/name,$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template name="doRefs">
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:message select="concat($thisClass,' refs=',string-join(current()/reference/name,','))"/>
        <xsl:if test="reference">
            <xsl:for-each select="reference">
                <xsl:value-of select="concat($thisClass,' --',$gt,' ',vf:nameFromVodmlref(current()/datatype/vodml-ref),' : ',current()/name,$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template name="doComposition">
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:message select="concat($thisClass,' comps=',string-join(current()/reference/name,','))"/>
        <xsl:if test="composition">
            <xsl:for-each select="composition">
                <xsl:value-of select="concat($thisClass,' *-- ',vf:nameFromVodmlref(current()/datatype/vodml-ref),' : ',current()/name,$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="/" mode="svg" priority="300">
        <div>
            <xsl:apply-templates select="@*|node()" mode="svg"/>
        </div>
    </xsl:template>
    <xsl:template match="comment()" mode="svg" priority="200"/>
    <xsl:template match="@*|node()" mode="svg" priority="100">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="svg"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="linkTo" as="xsd:string" > <!-- only works from top level overview -->
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:value-of select="concat('[',$vodml-id[2],'](',$vodml-id[1],'/',$vodml-id[2],'.md)')"/>
    </xsl:template>

    <xsl:function name="vf:doLink" >
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="substring-before($vodml-ref,':') = $docmods">
                <xsl:choose>
                    <xsl:when test="substring-before($vodml-ref,':')= $thisModelName">
                        <xsl:value-of select="concat('[',substring-after($vodml-ref,':'),'](',substring-after($vodml-ref,':'),'.md)')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('[',$vodml-ref,'](../',substring-before($vodml-ref,':'),'/',substring-after($vodml-ref,':'),'.md)')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$vodml-ref"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
