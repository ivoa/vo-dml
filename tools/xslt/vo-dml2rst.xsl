<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1">
<!-- FIXME this is very incomplete-->
    <xsl:output method="text" encoding="UTF-8" indent="no" />
    <xsl:output method="xml" encoding="UTF-8" indent="no" name="svgform" omit-xml-declaration="true" />

    <xsl:include href="binding_setup.xsl"/>

    <xsl:variable name="nl" select="'&#10;'"/>
    <xsl:variable name="dq" select="'&quot;'"/>

    <xsl:function name="vf:underline" as="xsd:string">
        <xsl:param name="text"/>
        <xsl:param name="char"/>
        <xsl:variable name="len" select="string-length($text)"/>
        <xsl:value-of select="string-join(for $i in 1 to $len return $char, '')"/>
    </xsl:function>

    <xsl:template match="/">
        <xsl:message>Starting Sphinx reST documentation for <xsl:value-of select="vo-dml:model/name"/></xsl:message>
        <xsl:apply-templates select="vo-dml:model"/>
    </xsl:template>

    <xsl:template match="vo-dml:model">
        <xsl:variable name="title" select="name"/>
        <xsl:value-of select="concat($title, $nl, vf:underline($title, '='), $nl, $nl)"/>

        <xsl:value-of select="concat('**version ', version, '** *', (format-dateTime(xsd:dateTime(lastModified),'[Y0001]-[M01]-[D01]')), '*', $nl, $nl)"/>

        <xsl:text>Introduction</xsl:text>
        <xsl:value-of select="concat($nl, vf:underline('Introduction', '-'), $nl, $nl)"/>
        <xsl:apply-templates select="description"/>
        <xsl:value-of select="concat($nl, $nl)"/>

        <xsl:text>Authors</xsl:text>
        <xsl:value-of select="concat($nl, vf:underline('Authors', '~'), $nl, $nl)"/>
        <xsl:value-of select="concat(author, $nl, $nl)"/>

        <xsl:if test="//package">
            <xsl:text>Packages</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Packages', '-'), $nl, $nl)"/>
            <xsl:for-each select="//package">
                <xsl:sort select="name"/>
                <xsl:text>* </xsl:text><xsl:value-of select="concat('*', name, '*')"/> <xsl:apply-templates select="description"/><xsl:value-of select="$nl"/>
            </xsl:for-each>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:apply-templates select="(primitiveType|enumeration|dataType|objectType|package)"/>
    </xsl:template>

    <xsl:template match="primitiveType|enumeration|dataType|objectType">
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:variable name="hr" select="concat($vodml-id[1], '/', $vodml-id[2], '.rst')"/>
        <xsl:message>Writing description to <xsl:value-of select="$hr"/></xsl:message>
        <xsl:result-document method="text" encoding="UTF-8" href="{$hr}">
            <xsl:apply-templates select="current()" mode="desc"/>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="dataType|objectType" mode="desc">
        <xsl:variable name="header" select="name"/>
        <xsl:if test="@abstract">abstract </xsl:if><xsl:value-of select="concat($header, $nl, vf:underline($header, '-'), $nl, $nl)"/>

        <xsl:apply-templates select="description"/>
        <xsl:value-of select="concat($nl, $nl)"/>

        <xsl:apply-templates select="current()" mode="mermdiag"/>

        <xsl:if test="attribute|reference|composition">
            <xsl:text>.. list-table:: Members</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>   :widths: 20 20 10 50</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>   :header-rows: 1</xsl:text><xsl:value-of select="concat($nl, $nl)"/>
            <xsl:text>   * - Name</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>     - Type</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>     - Mult</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>     - Description</xsl:text><xsl:value-of select="$nl"/>
            <xsl:apply-templates select="attribute|reference|composition" mode="row"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="attribute|reference|composition" mode="row">
        <xsl:text>   * - </xsl:text><xsl:value-of select="name"/><xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:call-template name="linkTo"/><xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="multiplicity"/><xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="description"/><xsl:value-of select="$nl"/>
    </xsl:template>

    <xsl:template name="linkTo">
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:value-of select="concat(':doc:`', name, ' &lt;', $vodml-id[1], '/', $vodml-id[2], '&gt;`')"/>
    </xsl:template>

    <xsl:template match="enumeration|dataType|objectType" mode="mermdiag">
        <xsl:value-of select="concat('.. uml::', $nl, $nl)"/>
        <xsl:text>   hide empty members</xsl:text><xsl:value-of select="$nl"/>
        <xsl:apply-templates select="current()" mode="diag"/>
        <xsl:value-of select="concat($nl, $nl)"/>
    </xsl:template>

</xsl:stylesheet>