<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tap="http://ivoa.net/dm/tapschema/v1" xmlns:vft="http://www.ivoa.net/xml/VODML/tapfunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <xsl:output method="text"/> 
	<xsl:template match="tap:tapschemaModel">
		<xsl:apply-templates select="schema"/>
	</xsl:template>
   <xsl:template match="schema">
   <!-- TODO do not ignore schema -->
       <xsl:apply-templates select="tables/table"/>
       <xsl:apply-templates select="tables/table/fkeys/foreignKey/columns/fKColumn"/>
   </xsl:template>
   <xsl:template match="table">
     <xsl:text>create table </xsl:text>
     <xsl:value-of select="table_name"/>
     <xsl:text> (</xsl:text>
     <xsl:apply-templates select="columns/column"/>
     <xsl:apply-templates select="columns/column[indexed = 'true']"/>
     <xsl:text>);&#xa;</xsl:text>
   </xsl:template>
   <xsl:template match="column[indexed = 'true']">
     <xsl:value-of select="concat('primary key ',vft:columnNameNormalisation(column_name))"></xsl:value-of>
   </xsl:template>
   <xsl:template match="column">
     <xsl:value-of select="concat(vft:columnNameNormalisation(column_name),' ', datatype,', ')"></xsl:value-of>
   </xsl:template>
   <xsl:template match="fKColumn">
     <xsl:value-of select="concat('alter table if exists ',ancestor-or-self::table/table_name ,' add constraint ', replace(ancestor-or-self::foreignKey/key_id,'\.','_'), ' foreign key (',vft:columnNameNormalisation(from_column),') references ', ancestor-or-self::foreignKey/target_table)"/>
       <xsl:text>;&#xa;</xsl:text>
   </xsl:template>  

   <xsl:function name="vft:columnNameNormalisation" as="xsd:string">
        <xsl:param name="col" as="xsd:string"/>
        <xsl:value-of select="tokenize($col,'[\.]')[last()]"/>
    </xsl:function>	

</xsl:stylesheet>