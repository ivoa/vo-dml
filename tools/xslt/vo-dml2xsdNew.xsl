<?xml version="1.0" encoding="UTF-8"?>
<!--

The intention is that this is a better documented, but equivalent version to the java generated schema - it is this version of the schema that is used in validation tests.

note that this schema is substantially different from the era when this code was stored in volute
* references are treated differently
* there is a top level model element that everything is under.
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
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                exclude-result-prefixes="bnd vf vo-dml"
>


  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

  <xsl:strip-space elements="*" />

  <!-- Input parameters -->
  <xsl:param name="lastModifiedText"/>
  <xsl:param name="binding"/>

  <xsl:include href="binding_setup.xsl"/>

  <xsl:variable name="xsd-ns">http://www.w3.org/2001/XMLSchema</xsl:variable>

  <xsl:variable name="modelname" select="/vo-dml:model/name"/>

 <!-- main pattern : processes for root node model -->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="vo-dml:model">

    <xsl:variable name="targetNamespace">
      <xsl:value-of select="vf:xsdNs($modelname)"/>
    </xsl:variable>

    <xsl:variable name="modelns">
      <xsl:value-of select="vf:xsdNsPrefix($modelname)"/>
    </xsl:variable>
    <xsl:message >Generating XSD for  <xsl:value-of select="$modelname "/> - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,', ')" /></xsl:message>



      <xsl:comment>Generated by gradle vo-dml tools <xsl:value-of select="current-dateTime()"/></xsl:comment>
      <xsd:schema version="1.1">
        <xsl:namespace name="{$modelns}">
          <xsl:value-of select="$targetNamespace"/>
        </xsl:namespace>
        <xsl:attribute name="targetNamespace">
          <xsl:value-of select="$targetNamespace"/>
        </xsl:attribute>
        <!--  import base schema -->
        <xsl:apply-templates select="import" mode="xmlns"/>

        <xsl:apply-templates select="import" mode="ns-import"/>
        <xsd:element>
          <xsl:attribute name="name"><xsl:value-of select="concat($modelname,'Model')"/></xsl:attribute>
          <xsd:complexType>
            <xsd:sequence>
              <xsd:element name="refs" minOccurs="0">
                <xsd:complexType>
                <xsd:sequence> <!-- TODO need to worry about order if a sequence -->
                    <xsl:for-each select="vf:refsToSerialize($modelname)">
                      <xsl:variable name="xtype" select="vf:xsdType(current())"/>
                      <xsd:element>
                        <xsl:attribute name="name"><xsl:value-of select="vf:lowerFirst(substring-after($xtype,':'))"/></xsl:attribute>
                        <xsl:attribute name="type"><xsl:value-of select="$xtype"/></xsl:attribute>
                        <xsl:attribute name="minOccurs">0</xsl:attribute>
                        <xsl:attribute name="maxOccurs">unbounded</xsl:attribute>
                      </xsd:element>
                    </xsl:for-each>
                </xsd:sequence>
                </xsd:complexType>
              </xsd:element>
              <xsd:choice minOccurs="0" maxOccurs="unbounded">
                <xsl:for-each select="vf:contentToSerialize($modelname)">
                  <xsl:variable name="xtype" select="vf:xsdType(vf:asvodmlref(current()))"/>
                   <xsd:element>
                     <xsl:attribute name="name"><xsl:value-of select="vf:lowerFirst(substring-after($xtype,':'))"/></xsl:attribute>
                     <xsl:attribute name="type"><xsl:value-of select="$xtype"/></xsl:attribute>
                   </xsd:element>
                </xsl:for-each>
              </xsd:choice>
            </xsd:sequence>
          </xsd:complexType>
        </xsd:element>
        <xsl:apply-templates select="objectType" mode="test"/>
        <xsl:apply-templates select="dataType" mode="test"/>
        <xsl:apply-templates select="primitiveType" mode="test"/>
        <xsl:apply-templates select="enumeration" mode="test"/>

        <xsl:apply-templates select="package"/>

      </xsd:schema>
  </xsl:template>


  <xsl:template match="import" mode="xmlns" >
    <xsl:variable name="mname" select="vf:modelNameFromFile(url)"/>
<!--    <xsl:message>import model <xsl:value-of select="string-join(($mname,vf:xsdNsPrefix($mname), vf:xsdNs($mname)),',')"/> </xsl:message>-->
    <xsl:namespace name="{vf:xsdNsPrefix($mname)}">
      <xsl:value-of select="vf:xsdNs($mname)"/>
    </xsl:namespace>
  </xsl:template>

  <xsl:template match="import" mode="ns-import">
    <xsl:variable name="mname" select="vf:modelNameFromFile(url)"/>
    <xsl:element name="xsd:import">
      <xsl:attribute name="namespace">
        <xsl:value-of select="vf:xsdNs($mname)"/>
      </xsl:attribute>
<!-- would like to not issue this - use catalogues all the time- but gradle build time testing is not working without this for some reason... -->   <xsl:attribute name="schemaLocation">
       <xsl:value-of select="vf:xsdFileName($mname)"/>
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

        <xsl:choose>
          <xsl:when test="extends">
            <xsd:complexContent>
            <xsd:extension>
              <xsl:attribute name="base">
                <xsl:value-of select="vf:xsdType(extends/vodml-ref)"/>
              </xsl:attribute>
              <xsl:apply-templates select="." mode="content"/>
            </xsd:extension>
            </xsd:complexContent>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." mode="content"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="vf:referredTo(vf:asvodmlref(current())) and not(attribute/constraint[ends-with(@xsi:type,':NaturalKey')]) and not(extends)">
          <xsd:attribute name="_id" type="xsd:ID"/>
        </xsl:if>

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
        <xsl:apply-templates select="attribute[not(vf:findTypeDetail(vf:asvodmlref(.))/isAttribute)]"/>
        <xsl:apply-templates select="composition[not(subsets)]"/>
        <xsl:apply-templates select="reference[not(subsets)]"/>
      </xsd:sequence>
      <xsl:apply-templates select="attribute[vf:findTypeDetail(vf:asvodmlref(.))/isAttribute]"/>
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
                <xsl:value-of select="vf:xsdType(extends/vodml-ref)"/>
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
        <xsl:apply-templates select="attribute[not(vf:findTypeDetail(vf:asvodmlref(.))/isAttribute)]"/>
        <xsl:apply-templates select="reference[not(subsets)]"/>
      </xsd:sequence>
      <xsl:apply-templates select="attribute[vf:findTypeDetail(vf:asvodmlref(.))/isAttribute]"/>
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



  <xsl:template match="attribute[vf:findTypeDetail(vf:asvodmlref(.))/isAttribute]" >
    <xsd:attribute>
      <xsl:attribute name="name" >
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsl:attribute name="type" >
        <xsl:choose>
          <xsl:when test="constraint[ends-with(@xsi:type,':NaturalKey')]">
            <xsl:value-of select="'xsd:ID'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="vf:xsdType(datatype/vodml-ref)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="use">
        <xsl:choose>
          <xsl:when test="minOccurs = 0">optional</xsl:when>
          <xsl:otherwise>required</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:call-template name="add_annotation"/>

    </xsd:attribute>
   </xsl:template>
  <xsl:template match="attribute[not(vf:findTypeDetail(vf:asvodmlref(.))/isAttribute)]" >
  <xsd:element>
    <xsl:attribute name="name" >
      <xsl:value-of select="name"/>
    </xsl:attribute>
    <xsl:attribute name="type" >
      <xsl:choose>
        <xsl:when test="constraint[ends-with(@xsi:type,':NaturalKey')]">
          <xsl:value-of select="'xsd:ID'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="vf:xsdType(datatype/vodml-ref)"/>
        </xsl:otherwise>
      </xsl:choose>
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

  <xsl:template match="composition[multiplicity/maxOccurs != 1 and not($mapping/bnd:mappedModels/model[name=$modelname]/xml/@compositionStyle='unwrapped')]" >
    <xsd:element>
      <xsl:attribute name="name" >
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsd:complexType>
        <xsd:sequence>
          <xsd:element>
            <xsl:attribute name="name" >
              <xsl:value-of select="$models/key('ellookup',current()/datatype/vodml-ref)/name"/>
            </xsl:attribute>
            <xsl:attribute name="type" >
              <xsl:value-of select="vf:xsdType(current()/datatype/vodml-ref)"/>
            </xsl:attribute>
            <xsl:apply-templates select="multiplicity"/>
          </xsd:element>
        </xsd:sequence>
      </xsd:complexType>
    </xsd:element>
  </xsl:template>

  <xsl:template match="composition" >
    <xsd:element>
      <xsl:attribute name="name" >
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsl:attribute name="type" >
        <xsl:value-of select="vf:xsdType(current()/datatype/vodml-ref)"/>
      </xsl:attribute>
      <xsl:apply-templates select="multiplicity"/>
    </xsd:element>
  </xsl:template>


  <xsl:template match="reference" >
    <xsl:comment><xsl:text>this is a reference</xsl:text></xsl:comment>
    <xsd:element>

      <xsl:attribute name="name" >
        <xsl:value-of select="name"/>
      </xsl:attribute>
      <xsl:attribute name="type">xsd:IDREF</xsl:attribute>

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
    <xsl:value-of select="substring-after(vf:xsdType(vf:asvodmlref(current())),':')"/>
  </xsl:template>

  <xsl:template name="typeAssignment">
    <xsl:value-of select="vf:xsdType(datatype/vodml-ref)"/>
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
    <xsl:value-of select="substring-after(vf:xsdType(vf:asvodmlref(current())),':')"/>
  </xsl:template>

 
</xsl:stylesheet>
