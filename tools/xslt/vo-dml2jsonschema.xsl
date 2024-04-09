<?xml version="1.0" encoding="UTF-8"?>
<!--
create a json schema
FIXME - this is still not a complete representation of the JSON produced
 -->

<!DOCTYPE stylesheet [
        <!ENTITY cr "<xsl:text>
</xsl:text>">
        <!ENTITY bl "<xsl:text> </xsl:text>">
        ]>

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:vodml-base="http://www.ivoa.net/xml/vo-dml/xsd/base/v0.1"
                exclude-result-prefixes="bnd"
>


  <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes" />

  <xsl:strip-space elements="*" />

  <!-- Input parameters -->
  <xsl:param name="lastModifiedText"/>
  <xsl:param name="binding"/>
  <xsl:include href="binding_setup.xsl"/>

 <!-- main pattern : processes for root node model -->
  <xsl:template match="/">
    <xsl:message >Generating JSON <xsl:value-of select="document-uri(.) "/> - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,' and ')" /></xsl:message>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="vo-dml:model">

    <xsl:variable name="modelname" select="name"/>
      {
      "$schema": "https://json-schema.org/draft/2020-12/schema"
      <xsl:call-template name="id"/>
       ,"title" : "<xsl:value-of select="title"/>"
        ,<xsl:apply-templates select="description"/>
        ,"$defs" : {
        "$comment": "local definitions are here"
        <xsl:apply-templates select="objectType" />
        <xsl:apply-templates select="dataType" />
        <xsl:apply-templates select="primitiveType"/>
        <xsl:apply-templates select="enumeration"/>
        <xsl:apply-templates select="package"/>
        }
      }

  </xsl:template>
  <xsl:template match="description">
    "description" : "<xsl:value-of select="normalize-space(translate(description,$dq,$sq))"/>"
  </xsl:template>
  <xsl:template name="defnName">
    "<xsl:value-of select="substring-after(vf:asvodmlref(current()),':')"/>"
  </xsl:template>


  <xsl:template name="id">
    ,"$id": "<xsl:value-of select="vf:jsonBaseURI(name)"/>"
  </xsl:template>


  <xsl:template match="package">
    <xsl:apply-templates select="objectType"/>
    <xsl:apply-templates select="dataType" />
    <xsl:apply-templates select="primitiveType"/>
    <xsl:apply-templates select="enumeration"/>
    <xsl:apply-templates select="package"/>
  </xsl:template>



  <xsl:template match="objectType">
    , <xsl:call-template name="defnName"/> : {
    "type": "object"
    ,<xsl:apply-templates select="description"/>
    ,"properties" : {
    "$comment" : "filler"
    <!--FIXME think about inheritance -->
    <xsl:apply-templates select="attribute"/>
    <xsl:apply-templates select="composition[not(subsets)]"/>
    <xsl:apply-templates select="reference[not(subsets)]"/>
    }
    }
   &cr;&cr;
  </xsl:template>





  <xsl:template match="dataType">

    , <xsl:call-template name="defnName"/> : {
    "type": "object"
    ,<xsl:apply-templates select="description"/>
    ,"properties" : {
    "$comment" : "filler"
    <!--FiXME think about inheritabnce -->
    <xsl:apply-templates select="attribute"/>
    <xsl:apply-templates select="reference[not(subsets)]"/>
    }
    }
    &cr;&cr;

  </xsl:template>








  <xsl:template match="enumeration">
   , <xsl:call-template name="defnName"/> :
    {
    <xsl:apply-templates select="description"/>
    ,"enum": [<xsl:value-of select="string-join(for $x in literal/name return concat($dq,$x,$dq),',')"/>]

    }
    &cr;&cr;

  </xsl:template>


  <xsl:template match="primitiveType">
  <!-- TODO - not sure -->
  </xsl:template>



  <xsl:template match="attribute" >
    ,"<xsl:value-of select="name"/>" : {
       <xsl:value-of select="vf:jsonType(datatype/vodml-ref)"/>
       ,<xsl:apply-templates select="description"/>
    }
  </xsl:template>

  <xsl:template match="multiplicity">
    <!--  only legal values: 0..1   1   0..*   1..* -->
    <xsl:if test="minOccurs">
      <xsl:attribute name="minOccurs"><xsl:value-of select="minOccurs"/></xsl:attribute>
    </xsl:if>
    <xsl:if test="maxOccurs">
      <xsl:attribute name="maxOccurs">
        <xsl:choose>
          <xsl:when test="maxOccurs &lt;= 0">
            <xsl:value-of select="'unbounded'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="maxOccurs"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>


  <xsl:template match="composition" >


  </xsl:template>

  <xsl:template match="reference" >

  </xsl:template>

</xsl:stylesheet>
