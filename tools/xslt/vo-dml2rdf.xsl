<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
<!ENTITY tab "<xsl:text>    </xsl:text>">
]>

<!-- 
This stylesheet is used to translate elements from a VO-DML/XML representation of a data model to 
RDF turtle predicates
We use here the following mapping between our metadata model and that of RDF [TBD is this a meaningful statement?]

Intermediate		|	RDF
=====================
objectType			|   class
valueType				|  
primitivetype   |
enumeration     |
datatype        |
attribute				| P rdfs:prop
reference				|
collection			|
extends
 -->

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1.0"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  
  <xsl:import href="common.xsl"/>
  
  <xsl:output method="text" encoding="UTF-8" indent="no" />
  
  <xsl:strip-space elements="*" />

  <xsl:param name="sq">'</xsl:param>
  <xsl:param name="dq">"</xsl:param>
  <xsl:param name="nl">\n</xsl:param>
  <xsl:param name="cr">\r</xsl:param>
  <xsl:param name="namespace"/>
  
  <xsl:template match="/">@prefix rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;.
@prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;.
@prefix <xsl:value-of select="/vo-dml:model/name"/>: &lt;http://www.ivoa.net/vo-dml/models/<xsl:value-of select="/vo-dml:model/name"/>#&gt;.
<xsl:apply-templates select="/vo-dml:model/import"/>
&cr;&cr;
<xsl:apply-templates select="vo-dml:model"/>
  </xsl:template>
  
<xsl:template match="import">@prefix <xsl:value-of select="vodml-id"/>: &lt;<xsl:value-of select="url"/>#&gt;.
</xsl:template> 
  
  <xsl:template match="vo-dml:model|package">

<xsl:apply-templates select="objectType"/>
<xsl:apply-templates select="dataType"/>
    <xsl:apply-templates select="primitiveType"/>
<!--  
    <xsl:apply-templates select="enumeration"/>
-->
<xsl:apply-templates select="package"/>
    
  </xsl:template>  
  
  
  
<xsl:template match="objectType|dataType|primitiveType"><xsl:value-of select="concat(/vo-dml:model/name,':',vodml-id)"/> a rdfs:Class; 
&tab;rdfs:label "<xsl:value-of select="name"/>"@en;
<xsl:apply-templates select="description"/>
<xsl:if test="extends">
&tab;rdfs:subClassOf <xsl:value-of select="extends/vodml-ref"/>;
</xsl:if>
&tab;.
&cr;      
<xsl:apply-templates select="attribute"/>
<xsl:apply-templates select="collection"/>
<xsl:apply-templates select="reference"/>
</xsl:template>
  
<xsl:template match="attribute|reference|collection"><xsl:value-of select="concat(/vo-dml:model/name,':',vodml-id)"/> a rdf:Property; 
&tab;rdfs:label "<xsl:value-of select="name"/>"@en;
<xsl:apply-templates select="description"/>
&tab;rdfs:domain <xsl:value-of select="concat(/vo-dml:model/name,':',../vodml-id)"/>;
&tab;rdfs:range <xsl:value-of select="datatype/vodml-ref"/>;
<xsl:if test="subsets">
&tab;rdfs:subPropertyOf <xsl:value-of select="subsets/vodml-ref"/>;
</xsl:if>
&tab;.
&cr;      
</xsl:template>

<xsl:template match="description">
&tab;rdfs:comment "<xsl:call-template name="trim"><xsl:with-param name="val"><xsl:value-of select="replace(replace(replace(.,$dq, $sq),$nl,' '),$cr,' ')"/></xsl:with-param> </xsl:call-template>"@en;
</xsl:template>
  
</xsl:stylesheet>
