<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="3.0"
                xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:uml="http://schema.omg.org/spec/UML/2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"

>

    <!--
    This XSLT script contains common  functions that depend only on a single instance of a VO-DML file being in scope.
    -->

    <!-- this function does not rely on vodml-id being present -->
    <xsl:function name="vf:asvodmlref" as="xsd:string">
        <xsl:param name="el" as="element()"/>
        <xsl:value-of select="concat($el/ancestor::vo-dml:model/name,':',string-join($el/ancestor-or-self::*/name[not(../name() = 'vo-dml:model')], '.'))"/>
    </xsl:function>

    <xsl:function name="vf:nameFromVodmlref" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:value-of select="tokenize($vodml-ref,'[\.:]')[last()]"/>
    </xsl:function>

    <xsl:function name="vf:upperFirst" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="concat(upper-case(substring($s,1,1)),substring($s,2))"/>
    </xsl:function>
    <xsl:function name="vf:lowerFirst" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="concat(lower-case(substring($s,1,1)),substring($s,2))"/>
    </xsl:function>

    <xsl:function name="vf:capitalize">
        <xsl:param name="name"/>
        <xsl:value-of select="concat(upper-case(substring($name,1,1)),substring($name,2))"/>
    </xsl:function>

    <xsl:function name="vf:multiplicityAsSymbol">
        <xsl:param name="m" as="element()"/>
        <xsl:choose>
            <xsl:when test="not($m/@minOccurs) and not($m/@maxOccurs)"><!-- do nothing --></xsl:when>
            <xsl:when test="number($m/@minOccurs) eq 1 and number($m/@maxOccurs) eq 1"><!-- do nothing --></xsl:when>
            <xsl:when test="number($m/@minOccurs) eq 0 and (number($m/@maxOccurs) eq 1 or not($m/@maxOccurs))">0..1</xsl:when>
            <xsl:when test="number($m/@minOccurs) eq 0 and $m/@maxOccurs='unbounded'">0..*</xsl:when>
            <xsl:when test="(not($m/@minOccurs) or number($m/@minOccurs) eq 1) and $m/@maxOccurs='unbounded'">1..*</xsl:when>
            <xsl:when test="not($m/@minOccurs) and $m/@maxOccurs"><xsl:value-of select="concat('1..', $m/@maxOccurs)"/></xsl:when>
            <xsl:when test="not($m/@maxOccurs) and $m/@minOccurs"><xsl:value-of select="concat($m/@maxOccurs,'..', $m/@maxOccurs)"/></xsl:when> <!-- this is probably illegal xsd, but just in case -->
            <xsl:otherwise><xsl:value-of select="concat($m/@minOccurs,'..', $m/@maxOccurs)"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>