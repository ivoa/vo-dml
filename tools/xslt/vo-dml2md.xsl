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
     <xsl:apply-templates select="//(primitiveType|enumeration|dataType|objectType)"/>
  </xsl:template>

  <xsl:template match="primitiveType|enumeration|dataType|objectType">
      <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
      <xsl:variable name="hr" select="concat($vodml-id[1],'/',$vodml-id[2],'.md')"/>
      <xsl:message>writing description to <xsl:value-of select="$hr"/></xsl:message>
      <xsl:result-document method="text" encoding="UTF-8" indent="no" href="{$hr}">
          <xsl:apply-templates select="current()" mode="desc"/>
      </xsl:result-document>

  </xsl:template>
  <xsl:template match="primitiveType" mode="desc">
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
# PrimitiveType <xsl:value-of select="name"/>

<xsl:apply-templates select="description"/>

  </xsl:template>

  <xsl:template match="enumeration" mode="desc">
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
# Enumeration <xsl:value-of select="name"/>

      <xsl:apply-templates select="description"/>
      <xsl:apply-templates select="current()" mode="mermdiag"/>

  </xsl:template>
  <xsl:template match="dataType" mode="desc">
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
# <xsl:if test="@abstract">_abstract_</xsl:if>  DataType <xsl:value-of select="name"/>

      <xsl:apply-templates select="description"/>
      <xsl:apply-templates select="current()" mode="mermdiag"/>
  </xsl:template>
  <xsl:template match="objectType" mode="desc">
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
# <xsl:if test="@abstract">_abstract_</xsl:if> ObjectType <xsl:value-of select="name"/>

      <xsl:apply-templates select="description"/>
      <xsl:apply-templates select="current()" mode="mermdiag"/>

  </xsl:template>

    <xsl:template match="description">
        &cr;&cr;
        <xsl:value-of select="current()"/>
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
    <xsl:template match="dataType" mode="merm">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:variable name="thisClass" select="name"/>
        class <xsl:value-of select="name"/>{
        &lt;&lt;dataType&gt;&gt;&cr;
        <xsl:for-each select="attribute">
            <xsl:value-of select="concat(name,$nl)"/>
        </xsl:for-each>
        }
        <xsl:call-template name="doSupers"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doSubs"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doRefs"/>
    </xsl:template>
    <xsl:template match="objectType" mode="merm">
        <xsl:variable name="thisClass" select="name"/>
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>

        class <xsl:value-of select="name"/>{
        <xsl:for-each select="attribute">
            <xsl:value-of select="concat(name,$nl)"/>
        </xsl:for-each>
        }
        <xsl:call-template name="doSupers"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doSubs"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doRefs"/>
        <xsl:call-template name="doComposition"/>
    </xsl:template>


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

  <xsl:template name="linkTo" as="xsd:string" >
      <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
      <xsl:value-of select="concat('[',$vodml-id[2],'](',$vodml-id[1],'/',$vodml-id[2],'.md)')"/>
  </xsl:template>

</xsl:stylesheet>
