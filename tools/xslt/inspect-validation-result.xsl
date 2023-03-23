<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
]>

<xsl:stylesheet version="3.0"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
               	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                >
  
  <!--
    Templates used by XSLT scripts to derive vodml-id and vodml-ref -s for attributes, references and collections
  -->
  	<xsl:output method="text" version="1.0" encoding="UTF-8"
		indent="yes" />
<xsl:param name="outputfile"/>
  <xsl:template match="/">
    <xsl:message>+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++</xsl:message>
  <xsl:choose>
  <xsl:when test="//svrl:failed-assert">
  
    <xsl:result-document href="{$outputfile}">
      <xsl:message>Schematron errors and/or warnings found, see <xsl:value-of select="$outputfile"/></xsl:message>
    	<xsl:apply-templates select="//svrl:failed-assert"/>
    </xsl:result-document>
    </xsl:when>
    <xsl:otherwise>
    <xsl:message>No errors found, VO-DML document passes Schematron validation.</xsl:message>
    </xsl:otherwise>
    </xsl:choose> 
  </xsl:template>
  
  <xsl:template match="svrl:failed-assert">
-------&cr;
<xsl:value-of select="@flag"/>:
-------<xsl:value-of select="svrl:text"/>
  </xsl:template>
 
</xsl:stylesheet>