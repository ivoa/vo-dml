<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<!-- 
  This XSLT is used by intermediate2java.xsl to generate JAXB annotations and JAXB specific java code.
  
  Java 1.8+ is required by JAXB 2.1.
-->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"

                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl">


  <xsl:template match="objectType|dataType" mode="JAXBAnnotation">
     <xsl:variable name="isContained">
      <xsl:apply-templates select="." mode="testrootelements">
        <xsl:with-param name="count" select="'0'"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="rootelname">
          <xsl:apply-templates select="." mode="root-element-name"/>
    </xsl:variable>
    
  @javax.xml.bind.annotation.XmlAccessorType( javax.xml.bind.annotation.XmlAccessType.NONE )  
  @javax.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
    <xsl:choose>
      <xsl:when test="number($isContained) = 0 and not(@abstract = 'true')">
    @javax.xml.bind.annotation.XmlRootElement( name = "<xsl:value-of select="$rootelname"/>")
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="primitiveType" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
  </xsl:template>

<!--
 have removed proporder for now
 -->
  <xsl:template match="objectType|dataType" mode="propOrder">
    <xsl:if test="attribute|composition|reference">
      <xsl:text>,propOrder={
      </xsl:text>
      <!--IMPL this is all a bit long-winded, but keep structure in case want to do something different -->
        <xsl:for-each select="attribute,composition[not(subsets)],reference[not(subsets)]">
        <xsl:variable name="prop">
           <xsl:value-of select="name"/>
        </xsl:variable>
        <xsl:text>"</xsl:text><xsl:value-of select="$prop"/><xsl:text>"</xsl:text><xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
        </xsl:for-each>
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="enumeration" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
    @javax.xml.bind.annotation.XmlEnum
  </xsl:template>

  <!-- template attribute : adds JAXB annotations for primitive types, data types & enumerations -->
  <xsl:template match="attribute" mode="JAXBAnnotation">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    @javax.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
  </xsl:template>

  <!-- reference resolved via JAXB -->
  <xsl:template match="reference" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlIDREF
  </xsl:template>

  <xsl:template match="reference" mode="JAXBAnnotation_reference">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    @javax.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = Reference.class)
  </xsl:template>

  <xsl:template match="composition" mode="JAXBAnnotation">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    @javax.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
  </xsl:template>

  <xsl:template match="literal" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlEnumValue("<xsl:value-of select="value"/>")
  </xsl:template>

  <xsl:template match="attribute|reference|composition" mode="required">
    <xsl:choose>
      <xsl:when test="starts-with(multiplicity, '0')">false</xsl:when>
      <xsl:otherwise>true</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="vo-dml:model|package" mode="jaxb.index">
    <xsl:param name="dir"/>
    <xsl:variable name="file" select="concat($output_root, '/', $dir, '/jaxb.index')"/>
    <!-- open file for this package -->
    <xsl:message >Writing to jaxb index file <xsl:value-of select="$file"/></xsl:message>

    <xsl:result-document href="{$file}">
      <xsl:for-each select="objectType|dataType">
        <xsl:value-of select="name"/>&cr;
      </xsl:for-each>
    </xsl:result-document> 
  </xsl:template>
</xsl:stylesheet>