<?xml version="1.0" encoding="UTF-8"?>
<!--
This is still an experimental implementation - the canonical form of the XSD schema is the schema that can be generated from the generated java code.
t
The intention is that this wll eventually be a better documented, but equivalent version to the java generated schema

note that this schema is substantially different from the era when this code was stored in volute
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
                xmlns:vfs="http://www.ivoa.net/xml/VODML/schemaFunctions"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:vodml-base="http://www.ivoa.net/xml/vo-dml/xsd/base/v0.1"
                exclude-result-prefixes="bnd vf vfs"
>


  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

  <xsl:strip-space elements="*" />



  <!-- Input parameters -->
  <xsl:param name="lastModifiedText"/>
  <xsl:param name="binding"/>
  <xsl:param name="schemalocation_root" select="'http://volute.g-vo.org/svn/trunk/projects/dm/vo-dml/xsd/'"/>


  <xsl:include href="binding_setup.xsl"/>

  <xsl:variable name="xsd-ns">http://www.w3.org/2001/XMLSchema</xsl:variable>



 <!-- main pattern : processes for root node model -->
  <xsl:template match="/">
    <xsl:message >Generating XSD - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,' and ')" /></xsl:message>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="vo-dml:model">

    <xsl:variable name="modelname" select="name"/>

    <xsl:variable name="xsd-location">
      <xsl:value-of select="vfs:xsdFileName($modelname)"/>
    </xsl:variable>

    <xsl:variable name="targetNamespace">
      <xsl:value-of select="vfs:xsdNs($modelname)"/>
    </xsl:variable>

    <xsl:variable name="modelns">
      <xsl:value-of select="vfs:xsdNsPrefix($modelname)"/>
    </xsl:variable>

    <xsl:message >Writing to XSD file -<xsl:value-of select="$xsd-location"/></xsl:message>
    <xsl:result-document href="{$xsd-location}" >
      <xsl:comment>Generated by gradle vodml tools <xsl:value-of select="current-dateTime()"/></xsl:comment>
      <xsd:schema>
        <xsl:namespace name="{$modelns}">
          <xsl:value-of select="$targetNamespace"/>
        </xsl:namespace>
        <xsl:attribute name="targetNamespace">
          <xsl:value-of select="$targetNamespace"/>
        </xsl:attribute>
        <!--  import base schema -->
        <xsl:apply-templates select="import" mode="xmlns"/>
        <xsl:element name="xsd:import">
          <xsl:attribute name="namespace" ><xsl:value-of select="$base-schemanamespace"/></xsl:attribute>
          <xsl:attribute name="schemaLocation"><xsl:value-of select="$base-schemalocation"/></xsl:attribute>
        </xsl:element>

        <xsl:apply-templates select="import" mode="ns-import"/>

        <xsl:apply-templates select="objectType" mode="test"/>
        <xsl:apply-templates select="dataType" mode="test"/>
        <xsl:apply-templates select="primitiveType" mode="test"/>
        <xsl:apply-templates select="enumeration" mode="test"/>

        <xsl:apply-templates select="package"/>

      </xsd:schema>
    </xsl:result-document>
  </xsl:template>


  <xsl:template match="import" mode="xmlns" >
    <xsl:variable name="mname" select="vf:modelNameFromFile(url)"/>
    <xsl:message>import model <xsl:value-of select="string-join(($mname,vfs:xsdNsPrefix($mname), vfs:xsdNs($mname)),',')"/> </xsl:message>
    <xsl:namespace name="{vfs:xsdNsPrefix($mname)}">
      <xsl:value-of select="vfs:xsdNs($mname)"/>
    </xsl:namespace>
  </xsl:template>

  <xsl:template match="import" mode="ns-import">
    <xsl:variable name="mname" select="vf:modelNameFromFile(url)"/>
    <xsl:element name="xsd:import">
      <xsl:attribute name="namespace">
        <xsl:value-of select="vfs:xsdNs($mname)"/>
      </xsl:attribute>
      <xsl:attribute name="schemaLocation">
        <xsl:value-of select="vfs:xsdLocation($mname)"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>



  <xsl:template match="package">
    <xsl:apply-templates select="objectType" mode="test"/>
    <xsl:apply-templates select="dataType" mode="test"/>
    <xsl:apply-templates select="primitiveType" mode="test"/>
    <xsl:apply-templates select="enumeration" mode="test"/>
    <xsl:apply-templates select="package"/>
  </xsl:template>

  <xsl:template match="objectType|dataType|enumeration|primitiveType" mode="test">
    <xsl:variable name="mappedtype" select="vf:findmapping(vf:asvodmlref(current()),'xsd')"/>

    <xsl:if test="not($mappedtype) or $mappedtype = ''" >
      <xsl:apply-templates select="." mode="declare"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="objectType" mode="declare">

    <xsl:variable name="typename">
      <xsl:call-template name="localTypeName"/>
    </xsl:variable>
    <xsd:complexType>
      <xsl:attribute name="name">
        <xsl:value-of select="$typename"/>
      </xsl:attribute>
      <xsl:if test="@abstract = 'true'">
        <xsl:attribute name="abstract">
          <xsl:value-of select="'true'"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="add_annotation"/>
      <xsd:complexContent>
        <xsd:extension>
          <xsl:attribute name="base">
            <xsl:choose>
              <xsl:when test="extends">
                <xsl:value-of select="vfs:xsdType(extends/vodml-ref)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$baseType"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates select="." mode="content"/>
        </xsd:extension>
      </xsd:complexContent>
    </xsd:complexType>&cr;&cr;
  </xsl:template>



  <!--   !!!! IMPORTANT !!!!
 The order of the elements MUST be the same as the order in which the properties appear in the jaxb.xsl propOrder.
 This order is {attribute,collection[not(subsets)],reference[not(subsets)]}.
 NB Might we prefer attribute,referemce, collection???
 -->
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
    <xsd:complexType>
      <xsl:attribute name="name">
        <xsl:call-template name="localTypeName"/>
      </xsl:attribute>
      <xsl:if test="@abstract = 'true'">
        <xsl:attribute name="abstract">
          <xsl:value-of select="'true'"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="add_annotation"/>
      <xsl:choose>
        <xsl:when test="extends">
          <xsd:complexContent>
            <xsd:extension>
              <xsl:attribute name="base">
                <xsl:value-of select="vfs:xsdType(extends/vodml-ref)"/>
              </xsl:attribute>
              <xsl:apply-templates select="." mode="content"/>
            </xsd:extension>
          </xsd:complexContent>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="." mode="content"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsd:complexType>&cr;&cr;
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
    <xsd:simpleType>
      <xsl:attribute name="name">
        <xsl:call-template name="localTypeName"/>
      </xsl:attribute>
      <xsl:call-template name="add_annotation"/>
      <xsd:restriction base="xsd:string">
        <xsl:apply-templates select="literal"/>
      </xsd:restriction>
    </xsd:simpleType>&cr;&cr;
  </xsl:template>




  <xsl:template match="enumeration/literal">
    <xsd:enumeration>
      <xsl:attribute name="value"><xsl:value-of select="name"/></xsl:attribute>
      <xsl:call-template name="add_annotation"/>

    </xsd:enumeration>
  </xsl:template>



  <xsl:template match="primitiveType" mode="declare">
    <xsd:simpleType>
      <xsl:attribute name="name">
        <xsl:call-template name="localTypeName"/>
      </xsl:attribute>
      <xsl:call-template name="add_annotation"/>
      <xsd:restriction base="xsd:string">
      </xsd:restriction>
    </xsd:simpleType>&cr;&cr;
  </xsl:template>



  <xsl:template match="attribute" >

    <xsd:element>
      <xsl:attribute name="name" >
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsl:attribute name="type" >
        <xsl:value-of select="vfs:xsdType(datatype/vodml-ref)"/>
      </xsl:attribute>
      <xsl:apply-templates select="multiplicity"/>
      <xsl:call-template name="add_annotation"/>
    </xsd:element>
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
    <xsd:element>
      <xsl:attribute name="name" >
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsl:attribute name="type" >
        <xsl:value-of select="vfs:xsdType(current()/datatype/vodml-ref)"/>
      </xsl:attribute>
      <xsl:apply-templates select="multiplicity"/>
    </xsd:element>
  </xsl:template>

  <xsl:template match="reference" >
    <xsd:element>
      <xsl:attribute name="name" >
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsl:attribute name="type" >
        <xsl:value-of select="$referenceType"/>
      </xsl:attribute>
      <xsl:apply-templates select="multiplicity"/>
      <xsl:call-template name="add_annotation"/>
    </xsd:element>
  </xsl:template>


  <xsl:template match="attribute" mode="declare">

    <xsd:element>
      <xsl:attribute name="name">
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:call-template name="typeAssignment"/>
      </xsl:attribute>
    </xsd:element>
  </xsl:template>

  <xsl:template name="localTypeName">
    <xsl:value-of select="substring-after(vfs:xsdType(vf:asvodmlref(current())),':')"/>
  </xsl:template>

  <xsl:template name="typeAssignment">
    <xsl:value-of select="vfs:xsdType(datatype/vodml-ref)"/>
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



  <xsl:template match="objectType|dataType|enumeration|primitiveType" mode="type-name">
    <xsl:value-of select="substring-after(vfs:xsdType(vf:asvodmlref(current())),':')"/>
  </xsl:template>

  <xsl:function name="vfs:xsdType" as="xsd:string">
    <xsl:param name="vodml-ref" as="xsd:string"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
    <xsl:variable name="type">
      <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'xsd')"/>
    <xsl:choose>
      <xsl:when test="$mappedtype != ''">
        <xsl:value-of select="$mappedtype"/>
      </xsl:when>
      <xsl:otherwise>
          <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>
          <xsl:variable name="root" select="vfs:xsdNsPrefix($modelname)"/>
          <xsl:value-of select="concat($root,':',substring-after($vodml-ref,':'))"/>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$type"/>
  </xsl:function>

  <xsl:function name="vfs:xsdNsPrefix" as="xsd:string">
    <xsl:param name="modelName" as="xsd:string"/>
    <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelName]/xml-targetnamespace/@prefix"/>
  </xsl:function>
  <xsl:function name="vfs:xsdNs" as="xsd:string">
    <xsl:param name="modelName" as="xsd:string"/>
    <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelName]/xml-targetnamespace/text()"/>
  </xsl:function>
  <xsl:function name="vfs:xsdFileName" as="xsd:string">
    <xsl:param name="modelName" as="xsd:string"/>
    <xsl:value-of select="concat(substring-before($mapping/bnd:mappedModels/model[name=$modelName]/file,'.vo-dml.xml'),'.xsd')"/>
  </xsl:function>


</xsl:stylesheet>
