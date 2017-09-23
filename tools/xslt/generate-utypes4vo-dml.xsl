<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
<!ENTITY dotsep "<xsl:text>.</xsl:text>">
<!ENTITY colonsep "<xsl:text>:</xsl:text>">
<!ENTITY slashsep "<xsl:text>/</xsl:text>">
<!-- separator between model and child -->
<!ENTITY modelsep "<xsl:text>:</xsl:text>"> 
<!ENTITY psep "<xsl:text>.</xsl:text>"> <!-- separator between packages -->
<!ENTITY casep "<xsl:text>.</xsl:text>"> <!-- separator between class and attribute -->
<!ENTITY aasep "<xsl:text>.</xsl:text>"> <!-- separator between attributes -->
]>

<xsl:stylesheet version="2.0" 
                xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:uml="http://schema.omg.org/spec/UML/2.0"
               	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1">
  
  <!--
    Templates used by XSLT scripts to derive vodml-id and vodml-ref -s for attributes, references and compositions
  -->
  	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

  <xsl:template match="/">
  	<xsl:apply-templates select="vo-dml:model"/>
  </xsl:template>
  
  <xsl:template match="@*|node()">
    <xsl:if test="name() != 'idref'">
  	<xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
  	</xsl:copy>
    </xsl:if>
  </xsl:template>
 
  <xsl:template match="@*|node()" mode="copy">
    <xsl:if test="name() != 'idref'">
  	<xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="copy"/>
  	</xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="vodml-id">
      <xsl:element name="vodml-id">
      <xsl:apply-templates select=".." mode="vodml-id"/>
      </xsl:element>
  </xsl:template>

  <xsl:template match="*[vodml-id]" mode="vodml-id">
        <xsl:if test="name() = 'vo-dml:model'">
        <xsl:value-of select="vodml-id"/>
        </xsl:if>
        <xsl:if test="name() != 'vo-dml:model'">
      <xsl:choose>
        <xsl:when test="vodml-id/@id = vodml-id">
        <xsl:variable name="prefix">
        <xsl:choose>
        <xsl:when test="../name() != 'vo-dml:model'">
        <xsl:apply-templates select=".." mode="vodml-id"/><xsl:apply-templates select="." mode="separator"/>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$prefix"/><xsl:value-of select="name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="vodml-id"/>
      </xsl:otherwise>
      </xsl:choose>
      </xsl:if>
  </xsl:template>

  
  <!-- generate a vodml-ref -->
  <xsl:template match="vodml-ref">
  <xsl:variable name="vodml-ref" select="."/>
  <!--  check whether a vodml-ref must be generated. This is assumed to be the case when
  the vodml-ref is the same as the @id of some element in the model.
   -->
    <xsl:variable name="vodml-id" select="/vo-dml:model//vodml-id[@id = $vodml-ref]"/>
    <xsl:choose>
      <xsl:when test="$vodml-id">
      <xsl:element name="vodml-ref">
        <xsl:value-of select="/vo-dml:model/name"/>&modelsep;<xsl:apply-templates select="$vodml-id/.." mode="vodml-id"/>
      </xsl:element>
      </xsl:when>
      <xsl:otherwise> <!-- in modelimport? then model prefix will have been added already -->
        <xsl:element name="vodml-ref">
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  

   <xsl:template match="objectType|dataType|enumeration|primitiveType|package" mode="separator">
    <xsl:choose>
      <xsl:when  test="../name() = 'vo-dml:model'">&modelsep;</xsl:when>
    <xsl:otherwise>&psep;</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="attribute|reference|composition|container|literal|constraint" mode="separator">
&casep;
  </xsl:template>


  
</xsl:stylesheet>