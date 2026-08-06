<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Copyright (c) 2026. Paul Harrison, University of Manchester
  -->

<!--
This includable stylesheet contains templates for generating PlantUML diagrams from VO-DML models. It is intended to be used in conjunction with other XSLT stylesheets that process VO-DML XML files.
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1">
    <xsl:output method="text" encoding="UTF-8" indent="no" />
    <!-- PlantUML diagram content templates (same logic as vo-dml2md.xsl) -->
    <xsl:function name="vf:diagclassdef" as="xsd:string">
        <xsl:param name="vodml-ref"/>
        <xsl:variable name="thisClass" as="element()">
            <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
        </xsl:variable>
        <xsl:variable name="result">
            <xsl:if test="$thisClass/@abstract">abstract </xsl:if>
            <xsl:text>class </xsl:text><xsl:value-of select="$thisClass/name"/>
            <xsl:if test="name($thisClass)='dataType'"> &lt;&lt;dataType&gt;&gt;</xsl:if>
        </xsl:variable>
        <xsl:value-of select="string-join($result)"/>
    </xsl:function>

    <xsl:template match="enumeration" mode="diag">
        <xsl:value-of select="concat('enum ', name, ' {', $nl)"/>
        <xsl:for-each select="literal">
            <xsl:value-of select="concat(name, $nl)"/>
        </xsl:for-each>
        <xsl:value-of select="concat('}', $nl)"/>
    </xsl:template>

    <xsl:template match="dataType|objectType" mode="diag">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:variable name="thisClass" select="name"/>
        <xsl:if test="@abstract">abstract </xsl:if>
        <xsl:text>class </xsl:text><xsl:value-of select="name"/>
        <xsl:if test="current()/name()='dataType'"><xsl:text> &lt;&lt;dataType&gt;&gt;</xsl:text></xsl:if>
        <xsl:text> #LightGray ##[bold]Purple</xsl:text>
        <xsl:value-of select="concat(' {', $nl)" disable-output-escaping="yes"/>
        <xsl:apply-templates select="(attribute|constraint)" mode="diag"/>
        <xsl:value-of select="concat('}', $nl)"/>
        <xsl:call-template name="doSupers"><xsl:with-param name="vodml-ref" select="$vodml-ref"/></xsl:call-template>
        <xsl:call-template name="doSubs"><xsl:with-param name="vodml-ref" select="$vodml-ref"/></xsl:call-template>
        <xsl:call-template name="doRefs"/>
        <xsl:call-template name="doComposition"/>
        <xsl:call-template name="doComposedBy"/>
        <xsl:call-template name="doReferredTo"/>
        <xsl:call-template name="doDiagLinks"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>

    </xsl:template>

    <xsl:template match="attribute" mode="diag">
        <xsl:value-of select="concat(datatype/vodml-ref, ' ', name, $nl)"/>
    </xsl:template>

    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="diag">
        <xsl:value-of select="concat(datatype/vodml-ref, ' ', vf:nameFromVodmlref(role/vodml-ref), $nl)"/>
    </xsl:template>

    <xsl:template match="constraint" mode="diag">
        <!-- suppress general constraints in diagrams -->
    </xsl:template>

    <xsl:template name="doDiagLinks">
        <xsl:param name="vodml-ref"/>
        <xsl:variable name="thisClass" as="element()">
            <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
        </xsl:variable>
        <xsl:variable name="classIds" as="xsd:string*">
            <xsl:sequence  select="vf:baseTypeIds($vodml-ref)"/>
            <xsl:sequence select="for $x in $models/vo-dml:model[name = $modelsInScope ]//*[extends/vodml-ref = $vodml-ref] return vf:asvodmlref($x)"/>
            <xsl:sequence select="$thisClass/reference/datatype/vodml-ref"/>
            <xsl:sequence select="$thisClass/composition/datatype/vodml-ref"/>
            <xsl:sequence select="distinct-values(for $x in $models/vo-dml:model[name = $modelsInScope ]//objectType[composition/datatype/vodml-ref = $vodml-ref] return vf:asvodmlref($x))"/>
            <xsl:sequence select="distinct-values(for $x in $models/vo-dml:model[name = $modelsInScope ]//objectType[reference/datatype/vodml-ref = $vodml-ref] return vf:asvodmlref($x))"/>
        </xsl:variable>
        <xsl:for-each select="$classIds">
            <xsl:value-of select="concat($nl,vf:doPlantUMLLink(current()))"/>
        </xsl:for-each>

    </xsl:template>
    <xsl:template name="doSupers">
        <xsl:param name="vodml-ref"/>
        <xsl:if test="vf:hasSuperTypes($vodml-ref)">
            <xsl:variable name="thisClass" as="element()">
                <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
            </xsl:variable>
            <xsl:variable name="bases" select="vf:baseTypeIds($vodml-ref)"/>
            <xsl:value-of select="concat(vf:diagclassdef($bases[1]), $nl)"/>
            <xsl:value-of select="concat($thisClass/name, ' -[#red]-|', $gt, ' ', vf:nameFromVodmlref($bases[1]), $nl)"/>
            <xsl:for-each select="1 to count($bases) - 1">
                <xsl:value-of select="concat(vf:diagclassdef($bases[xsd:integer(current())+1]), $nl,
                    vf:nameFromVodmlref($bases[xsd:integer(current())]), ' -[#red]-|', $gt, ' ',
                    vf:nameFromVodmlref($bases[xsd:integer(current())+1]), $nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="doSubs">
        <xsl:param name="vodml-ref"/>
        <xsl:if test="count(//*[extends/vodml-ref = $vodml-ref]) > 0">
            <xsl:variable name="thisClass" as="element()">
                <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
            </xsl:variable>
            <xsl:for-each select="for $x in //*[extends/vodml-ref = $vodml-ref] return vf:asvodmlref($x)">
                <xsl:value-of select="concat(vf:diagclassdef(current()), $nl,
                    vf:nameFromVodmlref(current()), ' -[#red]-|', $gt, ' ', $thisClass/name, $nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="doRefs">
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:if test="reference">
            <xsl:for-each select="reference">
                <xsl:value-of select="concat(vf:diagclassdef(current()/datatype/vodml-ref), $nl,
                    $thisClass, ' -[#green]-', $gt, ' ', vf:multiplicityForDiagram(current()/multiplicity), ' ',
                    vf:nameFromVodmlref(current()/datatype/vodml-ref), ' : ', current()/name, $nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="doComposition">
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:if test="composition">
            <xsl:for-each select="composition">
                <xsl:value-of select="concat(vf:diagclassdef(current()/datatype/vodml-ref), $nl,
                    $thisClass, ' *-[#blue]- ', vf:multiplicityForDiagram(current()/multiplicity), ' ',
                    vf:nameFromVodmlref(current()/datatype/vodml-ref), ' : ', current()/name, $nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="doComposedBy">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:if test="$models/vo-dml:model[name = $modelsInScope]//composition/datatype[vodml-ref=$vodml-ref]">
            <xsl:for-each select="$models/vo-dml:model[name = $modelsInScope]//objectType/composition[datatype/vodml-ref=$vodml-ref]">
                <xsl:value-of select="concat(vf:diagclassdef(vf:asvodmlref(current()/parent::objectType)), $nl,
                    current()/parent::objectType/name, ' *-[#blue]- ', vf:multiplicityForDiagram(current()/multiplicity),
                    ' ', $thisClass, ' : ', current()/name, $nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="doReferredTo">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:if test="$models/vo-dml:model[name = $modelsInScope]//reference/datatype[vodml-ref=$vodml-ref]">
            <xsl:for-each select="$models/vo-dml:model[name = $modelsInScope]//objectType/reference[datatype/vodml-ref=$vodml-ref]">
                <xsl:value-of select="concat(vf:diagclassdef(vf:asvodmlref(current()/parent::objectType)), $nl,
                    current()/parent::objectType/name, ' -[#green]-', $gt, ' ', vf:multiplicityForDiagram(current()/multiplicity),
                    ' ', $thisClass, ' : ', current()/name, $nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>