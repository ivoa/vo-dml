<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                exclude-result-prefixes="bnd vf"
>
   <xsl:output name="xmlcatf" method="xml" version="1.0" encoding="UTF-8" indent="yes" />
    <xsl:output name="jsoncatf" method="text" version="1.0" encoding="UTF-8" indent="yes" />

    <xsl:strip-space elements="*" />

    <!-- Input parameters -->
    <xsl:param name="binding"/>
    <xsl:param name="xml-catalogue"/>
    <xsl:param name="json-catalogue"/>
    <xsl:include href="binding_setup.xsl"/>
    <xsl:template match="/" name="main">
        <xsl:result-document href="{$xml-catalogue}" format="xmlcatf">
            <xsl:call-template name="xmlcat"/>
        </xsl:result-document>
        <xsl:result-document href="{$json-catalogue}" format="jsoncatf">
            <xsl:call-template name="jsoncat"/>
        </xsl:result-document>
    </xsl:template>

    <xsl:template name="xmlcat">
        <catalog  xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">
            <xsl:for-each select="$mapping/bnd:mappedModels/model">
                <xsl:element name="system">
                    <xsl:attribute name="systemId"><xsl:value-of select="vf:xsdFileName(name)"/></xsl:attribute>
                    <xsl:attribute name="uri"><xsl:value-of select="vf:xsdNs(name)"/></xsl:attribute>
                </xsl:element>
            </xsl:for-each>
        </catalog>
    </xsl:template>
    <xsl:template name="jsoncat">
        <xsl:for-each select="$mapping/bnd:mappedModels/model">
            <xsl:value-of select="concat(vf:jsonBaseURI(name),' ',vf:jsonFileName(name), $nl)"/>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>