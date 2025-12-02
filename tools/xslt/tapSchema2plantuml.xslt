<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
        <!ENTITY cr "<xsl:text>
</xsl:text>">
        <!ENTITY bl "<xsl:text> </xsl:text>">
        <!ENTITY nbsp "&#160;">
        <!ENTITY tab "&#160;&#160;&#160;&#160;">
        <!ENTITY ss "&lt;&lt;">
        <!ENTITY es "&gt;&gt;">
        ]>
<!--
This stylesheet will transform a tap schema representation into a plantuml
ER-diagram https://plantuml.com/ie-diagram
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tap="http://ivoa.net/dm/tapschema/v1"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:vft="http://www.ivoa.net/xml/VODML/tapfunctions"
>
    <xsl:output method="text" encoding="UTF-8" indent="no" />
    <xsl:variable name='nl'><xsl:text>
</xsl:text></xsl:variable>

    <xsl:template match="tap:tapschemaModel">

@startuml

' hide the spot
' hide circle

' avoid problems with angled crows feet
skinparam linetype ortho
        <xsl:apply-templates select="schema/tables/table"/>
        <xsl:text>

        </xsl:text>
        <xsl:apply-templates select="schema/tables/table/fkeys/foreignKey" mode="relations"/>


@enduml

    </xsl:template>

<xsl:template match="table">
entity "<xsl:value-of select="table_name"/>" as <xsl:value-of select="table_name"/> {
<!-- primary keys FIXME need better way to decide this -->
    <xsl:apply-templates select="columns/column[indexed='true']"/>
---
<!-- content -->
    <xsl:apply-templates select="columns/column[indexed='false']"/>
    <xsl:if test="fkeys/foreignKey">
---
      <xsl:apply-templates select="fkeys/foreignKey"/>
    </xsl:if>
}
</xsl:template>

<xsl:template match="column">
   <xsl:value-of select="concat(vft:columnNameNormalisation(column_name),' : ',datatype,$nl)"/>
</xsl:template>
<xsl:template match="foreignKey">
    <xsl:apply-templates select="columns/fKColumn"/>
</xsl:template>
<xsl:template match="fKColumn" >
    <xsl:variable name="datatype">
        <xsl:value-of select="//column[column_name=current()/target_column]/datatype"/>
    </xsl:variable>
    <xsl:value-of select="concat(vft:columnNameNormalisation(from_column),' : ',$datatype,vft:stereotype('FK'),$nl)"/>
</xsl:template>

    <xsl:template match="foreignKey" mode="relations">
       <!-- FIXME think about multiplicities and directions -->
    <xsl:value-of select="concat(ancestor::table/table_name,' }o--||',target_table,$nl)"/>
    </xsl:template>


    <xsl:function name="vft:columnNameNormalisation" as="xsd:string">
        <xsl:param name="col" as="xsd:string"/>
        <xsl:value-of select="tokenize($col,'[\.]')[last()]"/>
    </xsl:function>
    <xsl:function name="vft:stereotype" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="concat('&lt;&lt;',$s,'&gt;&gt;')"/>
    </xsl:function>

</xsl:stylesheet>