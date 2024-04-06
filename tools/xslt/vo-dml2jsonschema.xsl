<?xml version="1.0" encoding="UTF-8"?>
<!--
crete a json schema

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

  <xsl:variable name="xsd-ns">http://www.w3.org/2001/XMLSchema</xsl:variable>
 <!-- main pattern : processes for root node model -->
  <xsl:template match="/">
    <xsl:message >Generating JSON - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,' and ')" /></xsl:message>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="vo-dml:model">

    <xsl:variable name="modelname" select="name"/>
    <xsl:message>Model = <xsl:value-of select="$modelname"/></xsl:message>
    <xsl:variable name="path">
      <xsl:apply-templates select="." mode="xsd-path">
        <xsl:with-param name="delimiter" select="'/'"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="xsd-location">
      <xsl:value-of select="concat($modelname,'.json')"/>
    </xsl:variable>

    <xsl:variable name="targetNamespace">
      <xsl:value-of select="vf:ns4model($modelname)"/>
    </xsl:variable>

    <xsl:variable name="modelns">
      <xsl:value-of select="vf:nsprefix4model($modelname)"/>
    </xsl:variable>

    <xsl:message >Opening file <xsl:value-of select="$xsd-location"/></xsl:message>
    <xsl:result-document href="{$xsd-location}" >
      {
      "$schema": "https://json-schema.org/draft/2020-12/schema",

        <!--  import base schema  - need ids
        <xsl:apply-templates select="import" mode="xmlns"/> -->


        <xsl:apply-templates select="objectType" mode="test"/>
        <xsl:apply-templates select="dataType" mode="test"/>
        <xsl:apply-templates select="primitiveType" mode="test"/>
        <xsl:apply-templates select="enumeration" mode="test"/>

        <xsl:apply-templates select="package"/>


      }
    </xsl:result-document>
  </xsl:template>







  <xsl:template match="package">
    <xsl:apply-templates select="objectType" mode="test"/>
    <xsl:apply-templates select="dataType" mode="test"/>
    <xsl:apply-templates select="primitiveType" mode="test"/>
    <xsl:apply-templates select="enumeration" mode="test"/>
    <xsl:apply-templates select="package"/>
  </xsl:template>

  <xsl:template match="objectType|dataType|enumeration|primitiveType" mode="test">
    <xsl:variable name="mappedtype" select="vf:findmapping(vf:asvodmlref(.),'json')"/>

    <xsl:if test="not($mappedtype) or $mappedtype = ''" >
      <xsl:apply-templates select="." mode="declare"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="objectType" mode="declare">

    <xsl:variable name="typename">
      <xsl:apply-templates select="." mode="type-name"/>
    </xsl:variable>
    {
    "type": "object",
    <!--FiXME think about inheritabnce -->

    }
   &cr;&cr;
  </xsl:template>




  <xsl:template match="objectType" mode="content">
    <xsl:variable name="numprops" select="count(attribute|reference[not(subsets)]|composition)"/>
    <xsl:if test="number($numprops) > 0">
      <xsd:sequence>
        <xsl:apply-templates select="attribute"/>
        <xsl:apply-templates select="composition[not(subsets)]"/>
        <xsl:apply-templates select="reference[not(subsets)]"/>
      </xsd:sequence>
    </xsl:if>
  </xsl:template>




  <xsl:template match="dataType" mode="declare">
    <xsl:variable name="typename">
      <xsl:apply-templates select="." mode="type-name"/>
    </xsl:variable>
    {
    "type": "object",
    <xsl:call-template name="add_annotation"/>
    <!--FiXME think about inheritabnce -->

    }
    &cr;&cr;

  </xsl:template>




  <xsl:template match="dataType" mode="content">
    <xsl:variable name="numprops" select="count(attribute|reference[not(subsets)])"/>
    <xsl:if test="number($numprops) > 0">
      <xsd:sequence>
        <xsl:apply-templates select="attribute"/>
        <xsl:apply-templates select="reference[not(subsets)]"/>
      </xsd:sequence>
    </xsl:if>
  </xsl:template>




  <xsl:template match="enumeration" mode="declare">
    <xsl:variable name="typename">
      <xsl:apply-templates select="." mode="type-name"/>
    </xsl:variable>
    {
    "enum": {<xsl:value-of select="string-join(literal,',')"/>}
    <xsl:call-template name="add_annotation"/>


    }
    &cr;&cr;

  </xsl:template>








  <xsl:template match="primitiveType" mode="declare">
  <!-- TODO - not sure -->
  </xsl:template>



  <xsl:template match="attribute" >
    <xsl:variable name="type">
      <xsl:call-template name="XSDType">
        <xsl:with-param name="model" select="ancestor::vo-dml:model"/>
        <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>
    "<xsl:value-of select="name"/>" : {"type" : <xsl:value-of select="$type"/> }
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
    <xsl:variable name="type">
      <xsl:call-template name="XSDType">
        <xsl:with-param name="model" select="ancestor::vo-dml:model"/>
        <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>

  </xsl:template>

  <xsl:template match="reference" >
    <xsl:variable name="type">
      <xsl:call-template name="XSDType">
        <xsl:with-param name="model" select="ancestor::vo-dml:model"/>
        <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>

  </xsl:template>


  <xsl:template match="attribute" mode="declare">
    <xsl:variable name="type">
      <xsl:call-template name="XSDType">
        <xsl:with-param name="model" select="ancestor::vo-dml:model"/>
        <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>

  </xsl:template>






  <!--    named util templates    -->
  <!-- Add appinfo element -->
  <xsl:template name="add_annotation">
    <xsl:if test="description or vodml-id">
      <xsd:annotation>
        <xsl:if test="description and normalize-space(description) != 'TODO : Missing description : please, update your UML model asap.'">
          <xsd:documentation>
            <xsl:value-of select="description"/>
          </xsd:documentation>
        </xsl:if>
        <xsl:if test="vodml-id">
          <xsl:call-template name="add_appinfo"/>
        </xsl:if>
      </xsd:annotation>
    </xsl:if>
  </xsl:template>


  <xsl:template name="add_appinfo">
    <xsd:appinfo>
      <vodml-ref>
        <xsl:apply-templates select="./vodml-id" mode="asvodml-ref"/>
      </vodml-ref>
    </xsd:appinfo>
  </xsl:template>

  <!-- copied from vo-dml2pojo -->
  <xsl:template name="Model4vodml-ref" as="element()">
    <xsl:param name="model"/>
    <xsl:param name="vodml-ref"/>
    <xsl:if test="not($model)">
      <xsl:message>Model4vodml-ref: No model supplied for </xsl:message>
    </xsl:if>
    <xsl:variable name="prefix" select="substring-before($vodml-ref,':')"/>
    <xsl:variable name="vodml-id" select="substring-after($vodml-ref,':')"/>
    <xsl:if test="not($prefix) or $prefix=''">
      <xsl:message>!!!!!!! ERROR No prefix found in Model4vodml-ref for <xsl:value-of select="$vodml-ref"/></xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="not($prefix) or $prefix = '' or $model/name = $prefix">
        <xsl:copy-of select="$model"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$mapping/bnd:mappedModels/model[name=$prefix]/file">
            <xsl:variable name="file" select="$mapping/bnd:mappedModels/model[name=$prefix]/file"/>
            <xsl:copy-of select="document($file)/vo-dml:model"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="import" select="$model/import[name = $prefix]/url"/>
            <xsl:copy-of select="document($import)/vo-dml:model"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template name="XSDType">
    <xsl:param name="model" />
    <xsl:param name="vodml-ref"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
    <xsl:param name="length" select="''"/>
    <xsl:param name="fullpath" select="'true'"/>

    <xsl:if test="not($model)">
      <xsl:message>XSDType: No model supplied for <xsl:value-of select="$vodml-ref"/></xsl:message>
    </xsl:if>

    <xsl:variable name="mappedtype">
      <xsl:call-template name="findmapping">
        <xsl:with-param name="model" select="$model"/>
        <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$mappedtype != ''">
        <xsl:value-of select="$mappedtype"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$fullpath='true'">
            <!--         <xsl:message >Finding full path for <xsl:value-of select="$vodml-ref"/></xsl:message>   -->
            <xsl:call-template  name="fullpath">
              <xsl:with-param name="model" select="$model"/>
              <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>

            <xsl:variable name="type" select="vf:el4vodmlref($vodml-ref)"/>


            <xsl:value-of select="$type/name"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template name="findmapping">
    <xsl:param name="model" as="element()"/>
    <xsl:param name="vodml-ref"/>

    <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>
    <xsl:if test="not($modelname) or $modelname=''">
      <xsl:message>!!!!!!! ERROR No prefix found in findmaping for <xsl:value-of select="$vodml-ref"/></xsl:message>
    </xsl:if>
    <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/xsd-type"/>
  </xsl:template>

  <!-- find a java package path towards the type identified with the name -->
  <xsl:template name="fullpath">
    <xsl:param name="vodml-ref"/>
    <xsl:param name="model"/>

    <xsl:variable name="themodel" as="element()">
      <xsl:call-template name="Model4vodml-ref">
        <xsl:with-param name="model" select="$model"/>
        <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="root" select="$themodel/name"/>

    <xsl:variable name="vodmlid" select="substring-after($vodml-ref,':' )"/>
    <xsl:variable name="path">
      <xsl:for-each select="$themodel//*[vodml-id=$vodmlid]/ancestor-or-self::*[name() != 'vo-dml:model']">
        <xsl:value-of select="./name"/>
        <xsl:if test="position() != last()">
          <xsl:text>.</xsl:text>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="concat($root,':',$path)"/>

  </xsl:template>

  <xsl:template match="objectType|dataType|enumeration|primitiveType" mode="type-name">
    <xsl:variable name="path">
      <xsl:for-each select="./ancestor-or-self::*[name() != 'vo-dml:model']">
        <xsl:value-of select="./name"/>
        <xsl:if test="position() != last()">
          <xsl:text>.</xsl:text>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="$path"/>
  </xsl:template>

</xsl:stylesheet>
