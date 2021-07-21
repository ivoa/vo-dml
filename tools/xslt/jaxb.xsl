<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<!-- 
  This XSLT is used by intermediate2java.xsl to generate JAXB annotations and JAXB specific java code.
  
  Java 1.5+ is required by JAXB 2.1.
-->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
								xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl">
  
  <xsl:import href="common.xsl"/>
  <xsl:import href="common-xsd.xsl"/>

  <xsl:param name="targetnamespace_root"/> 

  <xsl:key name="element" match="*//*" use="@xmiid"/>




  <xsl:template match="objectType|dataType" mode="JAXBAnnotation">
    <xsl:variable name="namespace"> 
      <xsl:call-template name="namespace-for-package">
        <xsl:with-param name="packageid" select="..[name()='package']/@xmiid"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="isContained">
      <xsl:apply-templates select="." mode="testrootelements">
        <xsl:with-param name="count" select="'0'"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="rootelname">
          <xsl:apply-templates select="." mode="root-element-name"/>
    </xsl:variable>
    
  @XmlAccessorType( XmlAccessType.NONE )  
  @XmlType( name = "<xsl:value-of select="name"/>"<xsl:apply-templates select="." mode="propOrder"/>, namespace = "<xsl:value-of select="$namespace"/>")
    <xsl:choose>
      <xsl:when test="number($isContained) = 0 and not(@abstract = 'true')">
    @XmlRootElement( name = "<xsl:value-of select="$rootelname"/>", namespace = "<xsl:value-of select="$targetnamespace_root"/>")
      </xsl:when>
      <xsl:otherwise>
<!-- always produce a JAXB annotation to be able to marshall fragments -->        
<!-- GL 2009-05-12: do we really want this? Note that also DataType-s get this root element now.
Ofcourse if we always use the schemas to validate XML documents this will still be prevented, but ... -->
    @XmlRootElement( name = "<xsl:value-of select="$rootelname"/>", namespace = "<xsl:value-of select="$targetnamespace_root"/>")
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




<!--   !!!! IMPORTANT !!!!
 The propOrder MUST be the same as the order in which the properties appear in the <sequence> in the the XML schema, intermediate2xsd.xsl.
 This order is {attribute,collection[not(subsets)],reference[not(subsets)]}.
 NB Might we prefer attribute,referemce, collection??? 
 -->
  <xsl:template match="objectType|dataType" mode="propOrder">
    <xsl:if test="attribute|collection|reference">
      <xsl:text>,propOrder={
      </xsl:text>
        <xsl:for-each select="attribute,collection[not(subsets)],reference[not(subsets)]">
        <xsl:variable name="prop">
          <xsl:if test="name()='reference'">p_</xsl:if><xsl:value-of select="name"/>
        </xsl:variable>
        <xsl:text>"</xsl:text><xsl:value-of select="$prop"/><xsl:text>"</xsl:text><xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
        </xsl:for-each>
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>



  <xsl:template match="enumeration" mode="JAXBAnnotation">
    <xsl:variable name="namespace"> 
      <xsl:call-template name="namespace-for-package">
        <xsl:with-param name="packageid" select="..[name()='package']/@xmiid"/>
      </xsl:call-template>
    </xsl:variable>
    @XmlType( name = "<xsl:value-of select="name"/>", namespace = "<xsl:value-of select="$namespace"/>")
    @XmlEnum
  </xsl:template>




  <!-- template attribute : adds JAXB annotations for primitive types, data types & enumerations -->
  <xsl:template match="attribute" mode="JAXBAnnotation">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="xmiid" select="datatype/@xmiidref"/></xsl:call-template></xsl:variable>
    @XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
  </xsl:template>




  <!-- reference can not be resolved directly by JAXB -->
  <xsl:template match="reference" mode="JAXBAnnotation">
    @XmlTransient
  </xsl:template>




  <xsl:template match="reference" mode="JAXBAnnotation_reference">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="xmiid" select="datatype/@xmiidref"/></xsl:call-template></xsl:variable>
    @XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = Reference.class)
  </xsl:template>




  <xsl:template match="collection" mode="JAXBAnnotation">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="xmiid" select="datatype/@xmiidref"/></xsl:call-template></xsl:variable>
    @XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
  </xsl:template>




  <xsl:template match="literal" mode="JAXBAnnotation">
    @XmlEnumValue("<xsl:value-of select="value"/>")
  </xsl:template>
    



  <xsl:template match="attribute|reference|collection" mode="required">
    <xsl:choose>
      <xsl:when test="starts-with(multiplicity, '0')">false</xsl:when>
      <xsl:otherwise>true</xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  

  <xsl:template match="package" mode="jaxb.index">
    <xsl:param name="dir"/>
    <xsl:variable name="file" select="concat('src/', $dir, '/jaxb.index')"/>
    <!-- open file for this class -->
    <xsl:message >Opening file <xsl:value-of select="$file"/></xsl:message>

    <xsl:result-document href="{$file}">
      <xsl:for-each select="objectType">
        <xsl:value-of select="name"/>&cr;
      </xsl:for-each>
    </xsl:result-document> 
  </xsl:template>

  

  <xsl:template match="model" mode="jaxb.context.classpath">
    <xsl:variable name="file" select="'jaxb.context.classpath'"/>
    <!-- open file for this class -->
    <xsl:message >Opening file <xsl:value-of select="$file"/></xsl:message>

    <xsl:result-document href="{$file}">
      <xsl:text>jaxb.context.classpath=</xsl:text><xsl:value-of select="'org.ivoa.dm.model'"/>
      <xsl:for-each select="package">
        <xsl:apply-templates select="." mode="jaxb.context.classpath">
          <xsl:with-param name="path" select="$root_package"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:result-document> 
  </xsl:template>

  <xsl:template match="package"  mode="jaxb.context.classpath">
    <xsl:param name="path"/>
    <xsl:variable name="thispath">
      <xsl:value-of select="concat($path,'.',name)"/>
    </xsl:variable>
    <xsl:if test="objectType|dataType|enumeration">
      <xsl:text>:</xsl:text><xsl:value-of select="$thispath"/>
    </xsl:if>
    <xsl:apply-templates select="package" mode="jaxb.context.classpath">
      <xsl:with-param name="path" select="$thispath"/>
    </xsl:apply-templates>
  </xsl:template>


</xsl:stylesheet>