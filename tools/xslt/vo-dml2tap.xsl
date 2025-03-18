<?xml version="1.0" encoding="UTF-8"?>
<!--
This will produce a tap schema representation of the data model database serialization

FIXME This is not yet complete
* subsetting rules not done
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
                xmlns:tap="http://ivoa.net/dm/tapschema/v1"
                exclude-result-prefixes="bnd vf vo-dml"
        expand-text="true"
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


    <xsl:message >Generating TAPSchema for  <xsl:value-of select="$modelname "/> - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,', ')" /></xsl:message>

      <xsl:comment>Generated by gradle vo-dml tools <xsl:value-of select="current-dateTime()"/></xsl:comment>
      <tap:tapschemaModel>
        <schema>
         <schema_name>{name}</schema_name>
         <description>{description}</description>

       <tables>
       <xsl:apply-templates select="objectType"/>

        <xsl:apply-templates select="package"/>
        <!-- TODO should do imports as we probably want the whole schema in one hit rather than separately for each model. -->
       </tables>
        </schema>
      </tap:tapschemaModel>
  </xsl:template>


  <xsl:template match="package">
    <xsl:apply-templates select="objectType"/>
    <xsl:apply-templates select="package"/>
  </xsl:template>


  <xsl:template match="objectType[not(vf:noTableInComposition(vf:asvodmlref(.)))]" >
   <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
   <xsl:if test="not(extends and vf:isRdbSingleTable($modelname))">
   <table>
     <table_name>{vf:rdbTableName($vodml-ref)}</table_name>
       <table_type>table</table_type>
       <utype>{$vodml-ref}</utype>
       <description>{description}</description>
       <columns>
           <xsl:if test="count(attribute/constraint[ends-with(@xsi:type,':NaturalKey')]) = 0">
             <!--add the primary key column -->
             <column>
                 <column_name>{vf:rdbIDColumnName($vodml-ref)}</column_name>
                 <xsl:comment>primary key</xsl:comment>
                 <datatype>BIGINT</datatype>
                 <description>primary key for {name}</description>
                 <indexed>true</indexed>
                 <principal>false</principal>
                 <std>true</std> <!--IMPL if generated from VO-DML - should be a standard -->
             </column>
           </xsl:if>
           <xsl:apply-templates select="$models//composition[datatype/vodml-ref=$vodml-ref]" mode="fkeyColumn"/>
           <xsl:choose>
               <xsl:when test="vf:isRdbSingleTable($modelname)">
                   <xsl:choose>
                       <xsl:when test="vf:hasSubTypes($vodml-ref)  and not(extends)"> <!-- base type-->
                            <column>
                                <column_name>{concat(name,'.',vf:rdbODiscriminatorName($vodml-ref))}</column_name>
                                <datatype>VARCHAR</datatype>
                                <description>discriminator column for {$vodml-ref} sub-types</description>
                                <utype>{$vodml-ref}</utype>
                                <indexed>false</indexed>
                                <principal>false</principal>
                                <std>true</std><!--IMPL if generated from VO-DML - should be a standard -->
                            </column>
                           <xsl:apply-templates select="(attribute|reference|composition),vf:subTypes($vodml-ref)/(attribute|reference|composition)" mode="defn"/>

                       </xsl:when>
                       <xsl:when test="not(extends)">
                           <xsl:apply-templates select="(attribute|reference|composition)" mode="defn"/>
                       </xsl:when>
                       <xsl:otherwise><!--do nothing --></xsl:otherwise>
                   </xsl:choose>
               </xsl:when>
               <xsl:otherwise> <!-- joined table mode -->
                   <xsl:choose>
                       <xsl:when test="vf:hasSubTypes($vodml-ref)  and not(extends)"> <!-- base type-->
                           <xsl:apply-templates select="(attribute|reference|composition)" mode="defn"/>
                       </xsl:when>
                       <xsl:when test="extends">
                           <!-- FIXME - need to add the fkey -->
                           <xsl:apply-templates select="(attribute|reference|composition)" mode="defn"/>
                       </xsl:when>
                       <xsl:otherwise>
                           <xsl:apply-templates select="(attribute|reference|composition)" mode="defn"/>
                       </xsl:otherwise>
                   </xsl:choose>
               </xsl:otherwise>
           </xsl:choose>
       </columns>
       <fkeys>
           <xsl:apply-templates select="reference" mode="fkey"/>
           <xsl:apply-templates select="$models//composition[datatype/vodml-ref=$vodml-ref]" mode="fkey"/>
           <xsl:if test="vf:isRdbSingleTable($modelname)">
               <xsl:apply-templates select="vf:subTypes($vodml-ref)/reference" mode="fkey"/>
               <!-- TODO need to do the composition back refs too? -->
           </xsl:if>
           <xsl:if test="not(vf:isRdbSingleTable($modelname)) and extends">
               <foreignKey>
                   <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
                   <key_id>{vf:tapFkeyID($vodml-ref)}</key_id>
                   <description>join back to supertype {extends/vodml-ref}</description>
                   <utype>{$vodml-ref}</utype>
                   <columns>
                       <fKColumn>
                           <from_column>{vf:tapTargetColumnName($vodml-ref)}</from_column>
                           <target_column>{vf:tapTargetColumnName(extends/vodml-ref)}</target_column>
                       </fKColumn>
                   </columns>
                   <target_table>{vf:rdbTableName(extends/vodml-ref)}</target_table>
               </foreignKey>

           </xsl:if>
           <xsl:apply-templates select="attribute[vf:isDataType(.)]" mode="dtyperef"/>
           <xsl:apply-templates select="composition[vf:noTableInComposition(datatype/vodml-ref)]" mode="dtyperef"/>

       </fkeys>
   </table>
   </xsl:if>
  </xsl:template>
    <xsl:template match="objectType[vf:noTableInComposition(vf:asvodmlref(.))]" >
        <!-- IMPL do not create separate table -->
    </xsl:template>
    <xsl:template match="attribute[not(vf:isDataType(.))]" mode="defn" >
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <column>
            <column_name>{vf:tapcolumnName($vodml-ref)}</column_name>
            <xsl:comment>attribute of {vf:typeRole(datatype/vodml-ref)} {datatype/vodml-ref}</xsl:comment>
            <datatype>{vf:rdbTapType(datatype/vodml-ref)}</datatype>
            <description>{description}</description>
            <utype>{$vodml-ref}</utype>
            <indexed>{count(constraint[ends-with(@xsi:type,':NaturalKey')])> 0}</indexed>
            <principal>false</principal><!-- TODO need a way of actually specifying this -->
            <std>true</std><!--IMPL if generated from VO-DML - should be a standard -->
        </column>
    </xsl:template>

    <xsl:template match="attribute[vf:isDataType(.)]" mode="defn" >
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>

        <xsl:variable name="atv">
            <xsl:apply-templates select="current()" mode="attrovercols2"/>             
        </xsl:variable>
<!--        <xsl:message>**** <xsl:copy-of select="$atv" copy-namespaces="no"/></xsl:message>-->

        <xsl:apply-templates select="$atv" mode="dtypeexpandcols"/>

    </xsl:template>
    <xsl:template match="attribute[vf:isDataType(.)]" mode="dtyperef" >
        <xsl:variable name="atv">
            <xsl:apply-templates select="current()" mode="attrovercols2"/>
        </xsl:variable>
        <xsl:apply-templates select="$atv" mode="dtypeexpandrefs"/>
    </xsl:template>
    <xsl:template match="composition[vf:noTableInComposition(datatype/vodml-ref)]" mode="dtyperef" >
        <xsl:variable name="atv">
            <xsl:apply-templates select="current()" mode="attrovercols2"/>
        </xsl:variable>
        <xsl:apply-templates select="$atv" mode="dtypeexpandrefs"/>
    </xsl:template>

<!-- note  that these templates are matching on the construct created by the attrovercols2 mode on attributes -->
    <xsl:template match="att[not(*)]" mode="dtypeexpandcols">
        <xsl:variable name="top-vodml-ref" select="ancestor-or-self::dt[last()]/@v"/>
        <xsl:variable name="top-el" select="$models/key('ellookup',$top-vodml-ref)"/>
        <column>
            <column_name><xsl:value-of select="string-join(current()/ancestor-or-self::att/@c,'_')"/></column_name>
            <xsl:comment>attribute from dtype</xsl:comment>
            <datatype>{vf:rdbTapType(@type)}</datatype>
            <description>{$top-el/description}</description><!-- TODO would perhaps like to include datatype description too -->
            <utype>{$top-vodml-ref}</utype>
            <indexed>{count($top-el/constraint[ends-with(@xsi:type,':NaturalKey')])> 0}</indexed>
            <principal>false</principal><!-- TODO need a way of actually specifying this -->
            <std>true</std><!--IMPL if generated from VO-DML - should be a standard -->
        </column>
    </xsl:template>

    <xsl:template match="ref" mode="dtypeexpandcols">
        <xsl:variable name="top-vodml-ref" select="ancestor-or-self::dt[last()]/@v"/>
        <xsl:variable name="top-el" select="$models/key('ellookup',$top-vodml-ref)"/>
        <column>
            <column_name><xsl:value-of select="string-join(current()/(ancestor-or-self::att|ancestor-or-self::ref)/@c,'_')"/></column_name>
            <xsl:comment>reference from datatype</xsl:comment>
            <datatype>{vf:rdbKeyType(@type)}</datatype>
            <description>{$top-el/description}</description><!-- TODO would perhaps like to include datatype description too -->
            <utype>{@v}</utype>
            <indexed>true</indexed>
            <principal>false</principal><!-- TODO need a way of actually specifying this -->
            <std>true</std><!--IMPL if generated from VO-DML - should be a standard -->
        </column>
    </xsl:template>

    <xsl:template match="ref" mode="dtypeexpandrefs">
        <xsl:variable name="top-vodml-ref" select="ancestor-or-self::dt[last()]/@v"/>
        <xsl:variable name="top-el" select="$models/key('ellookup',$top-vodml-ref)"/>
        <foreignKey>
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
            <key_id>{vf:tapFkeyID($top-vodml-ref)}</key_id>
            <xsl:comment>reference to {@type}</xsl:comment>

            <description>{$top-el/description}</description>
            <utype>{$top-vodml-ref}</utype>
            <columns>
                <fKColumn>
                    <from_column><xsl:value-of select="string-join(current()/(ancestor-or-self::att|ancestor-or-self::ref)/@c,'_')"/></from_column>
                    <target_column>{vf:tapTargetColumnName(@type)}</target_column>
                </fKColumn>
            </columns>
            <target_table>{vf:rdbTableName(@type)}</target_table>
        </foreignKey>
    </xsl:template>




    <xsl:template match="reference" mode="defn">
        <column>
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <column_name>{vf:tapcolumnName($vodml-ref)}</column_name>
        <xsl:comment>reference to {datatype/vodml-ref}</xsl:comment>
        <datatype>{vf:rdbKeyType(datatype/vodml-ref)}</datatype>
        <description>{description}</description>
        <utype>{$vodml-ref}</utype>
        <indexed>false</indexed><!-- IMPL or true?! -->
        <principal>false</principal><!-- TODO need a way of actually specifying this -->
        <std>true</std><!--IMPL if generated from VO-DML - should be a standard -->
        </column>
    </xsl:template>
    <xsl:template match="composition[vf:noTableInComposition(datatype/vodml-ref)]" mode="defn">
        <xsl:variable name="atv">
            <xsl:apply-templates select="current()" mode="attrovercols2"/>
        </xsl:variable>
<!--        <xsl:message>composition <xsl:value-of select="vf:asvodmlref(current())"/> <xsl:copy-of select="$atv" copy-namespaces="no"/></xsl:message>-->
        <xsl:apply-templates select="$atv" mode="dtypeexpandcols"/>
    </xsl:template>

    <xsl:template match="composition" mode="defn">
    <!-- do nothing if called - it all happens for the type being composed -->
    </xsl:template>

    <xsl:template match="reference" mode="fkey">
        <foreignKey>
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
            <key_id>{vf:tapFkeyID($vodml-ref)}</key_id>
            <xsl:comment>reference to {datatype/vodml-ref}</xsl:comment>

            <description>{description}</description>
            <utype>{$vodml-ref}</utype>
            <columns>
                <fKColumn>
                    <from_column>{vf:tapcolumnName($vodml-ref)}</from_column>
                    <target_column>{vf:tapTargetColumnName(datatype/vodml-ref)}</target_column>
                </fKColumn>
            </columns>
            <target_table>{vf:rdbTableName(datatype/vodml-ref)}</target_table>
        </foreignKey>
    </xsl:template>

    <xsl:template match="composition" mode="fkey">
        <xsl:if test="number(multiplicity/maxOccurs) != 1"> <!-- IMPL keys not created for OneToOne -->
        <foreignKey>
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
            <xsl:variable name="target" select="vf:asvodmlref(current()/parent::*)"/>
            <key_id>{vf:tapFkeyID($vodml-ref)}</key_id>
            <xsl:comment>back reference to {datatype/vodml-ref} composition of {$target} </xsl:comment>
            <description>foreign key for {datatype/vodml-ref} composition of {$target} </description>
            <utype>{$vodml-ref}</utype> <!-- IMPL not sure is this is the appropriate utype -->
            <columns>
                <fKColumn>
                    <from_column>{vf:tapJoinColumnName(current())}</from_column>
                    <target_column>{vf:tapTargetColumnName($target)}</target_column>
                </fKColumn>
            </columns>
            <target_table>{vf:rdbTableName($target)}</target_table>
        </foreignKey>
        </xsl:if>
    </xsl:template>
    <xsl:template match="composition" mode="fkeyColumn">
        <xsl:if test="number(multiplicity/maxOccurs) != 1"> <!-- IMPL keys not created for OneToOne -->
        <column>
            <!-- thing that we are pointing to is the parent of the composition -->
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(current()/parent::*)"/>
            <column_name>{vf:tapJoinColumnName(current())}</column_name>
            <datatype>{vf:rdbKeyType($vodml-ref)}</datatype>
            <description>foreign key column for {$vodml-ref} composition of {datatype/vodml-ref}</description>
            <utype>{$vodml-ref}</utype>
            <indexed>false</indexed><!-- IMPL or true?! -->
            <principal>false</principal><!-- TODO need a way of actually specifying this -->
            <std>true</std><!--IMPL if generated from VO-DML - should be a standard -->
        </column>
        </xsl:if>
    </xsl:template>

    <!-- need to make the columnID unique over whole document - done by prepending the table name
    this will have to be removed before writing to tapschema db -->
    <xsl:function name="vf:tapcolumnName" as="xsd:string" >
        <xsl:param name="vodml-ref" as="xsd:string" />
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:sequence select="concat($el/parent::*/name,'.',$el/name)"/>
    </xsl:function>
    <!-- make a reference to a column -->
    <xsl:function name="vf:tapTargetColumnName" as="xsd:string" >
        <xsl:param name="vodml-ref" as="xsd:string" />
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:sequence select="concat($el/name,'.',vf:rdbJoinTargetColumnName($vodml-ref))"/>
    </xsl:function>

    <xsl:function name="vf:tapJoinColumnName" as="xsd:string" >
        <xsl:param name="comp" as="element()"/><!-- the composition -->
        <xsl:variable name="parent" select="$comp/parent::*" /><!-- the parent of the composition elemnt -->
        <xsl:sequence select="concat('FK_',$comp/name,'.',vf:rdbCompositionJoinName($parent))"/>
    </xsl:function>

    <xsl:function name="vf:tapFkeyID" as="xsd:string" > <!-- generate unique FK id -->
        <xsl:param name="vodml-ref" as="xsd:string" />
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:sequence select="concat('FK_',$el/parent::*/name,'.',$el/name)"/>
    </xsl:function>


</xsl:stylesheet>
