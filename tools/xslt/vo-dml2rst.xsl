<?xml version="1.0" encoding="UTF-8"?>
<!--
This stylesheet creates reStructuredText (RST) documentation for Sphinx.
It is equivalent to vo-dml2md.xsl but produces RST/Sphinx output instead of mkdocs Markdown.
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1">

    <xsl:output method="text" encoding="UTF-8" indent="no" />

    <xsl:param name="binding"/>
    <xsl:param name="modelsToDocument"/>
    <xsl:param name="graphviz_svg"/> <!-- NB - this is an svg! -->


    <xsl:include href="binding_setup.xsl"/>


    <xsl:variable name="thisModelName" select="/vo-dml:model/name"/>

    <xsl:variable name="docmods" as="xsd:string*">
        <xsl:choose>
            <xsl:when test="$modelsToDocument">
                <xsl:sequence select="tokenize($modelsToDocument,',')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$mapping/bnd:mappedModels/model/name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="modelsInScope" select="(/vo-dml:model/name, vf:importedModelNames(/vo-dml:model/name))"/>

    <!-- Create an RST underline of the same length as the text -->
    <xsl:function name="vf:underline" as="xsd:string">
        <xsl:param name="text"/>
        <xsl:param name="char"/>
        <xsl:variable name="len" select="string-length(string($text))"/>
        <xsl:value-of select="string-join(for $i in 1 to $len return $char, '')"/>
    </xsl:function>

    <!-- RST :doc: link for use from within a type file -->
    <xsl:function name="vf:doRstLink">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="substring-before($vodml-ref,':') = $docmods">
                <xsl:value-of select="concat(':ref:`',vf:nameFromVodmlref($vodml-ref),' &lt;',replace($vodml-ref, '[:.]', '_'),'&gt;`')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$vodml-ref"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- PlantUML class definition helper (same as vo-dml2md.xsl) -->
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


    <!-- Entry point -->
    <xsl:template match="/">
        <xsl:message>Starting Sphinx RST documentation for <xsl:value-of select="vo-dml:model/name"/></xsl:message>
        <xsl:apply-templates select="vo-dml:model"/>
    </xsl:template>

    <!-- Model overview: produces the main RST file with toctree -->
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

        <xsl:if test="$graphviz_svg">
            <xsl:value-of select="concat($nl, vf:underline('Overview Diagram', '~'), $nl, $nl)"/>
        <xsl:text>The whole model is represented in a model diagram below

        </xsl:text>
            <!-- IMPL this depends on https://github.com/sphinx-contrib/imagesvg -->
            <xsl:value-of select="concat($nl,'.. imagesvg:: ', $graphviz_svg, $nl)"/>
            <xsl:value-of select="concat('   :tagtype: object',$nl,$nl)"/>
        </xsl:if>
        <xsl:if test="//package">
            <xsl:text>Packages</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Packages', '-'), $nl, $nl)"/>
            <xsl:for-each select="//package">
                <xsl:sort select="name"/>
                <xsl:value-of select="concat('* *', name, '* ')"/><xsl:apply-templates select="description"/><xsl:value-of select="$nl"/>
            </xsl:for-each>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:if test="//primitiveType">
            <xsl:text>Primitives</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Primitives', '-'), $nl, $nl)"/>
            <xsl:for-each select="//primitiveType">
                <xsl:sort select="name"/>
                <xsl:text>* </xsl:text><xsl:call-template name="linkToOverview"/><xsl:value-of select="$nl"/>
            </xsl:for-each>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:if test="//enumeration">
            <xsl:text>Enumerations</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Enumerations', '-'), $nl, $nl)"/>
            <xsl:for-each select="//enumeration">
                <xsl:sort select="name"/>
                <xsl:text>* </xsl:text><xsl:call-template name="linkToOverview"/><xsl:value-of select="$nl"/>
            </xsl:for-each>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:if test="//dataType">
            <xsl:text>DataTypes</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('DataTypes', '-'), $nl, $nl)"/>
            <xsl:for-each select="//dataType">
                <xsl:sort select="name"/>
                <xsl:text>* </xsl:text><xsl:call-template name="linkToOverview"/><xsl:value-of select="$nl"/>
            </xsl:for-each>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:if test="//objectType">
            <xsl:text>ObjectTypes</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('ObjectTypes', '-'), $nl, $nl)"/>
            <xsl:for-each select="//objectType">
                <xsl:sort select="name"/>
                <xsl:text>* </xsl:text><xsl:call-template name="linkToOverview"/><xsl:value-of select="$nl"/>
            </xsl:for-each>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:if test="import">
            <xsl:text>Imports</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Imports', '-'), $nl, $nl)"/>
            <xsl:for-each select="import">
                <xsl:variable name="bnd" select="$mapping/bnd:mappedModels/model[file=current()/url]"/>
                <xsl:value-of select="concat('* ', $bnd/name, $nl)"/>
            </xsl:for-each>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <!-- Sphinx toctree for navigation -->
        <xsl:if test="//(primitiveType|enumeration|dataType|objectType)">
            <xsl:value-of select="concat($nl, '.. toctree::', $nl)"/>
            <xsl:value-of select="concat('   :maxdepth: 1', $nl)"/>
            <xsl:value-of select="concat('   :caption: Types', $nl, $nl)"/>
            <xsl:for-each select="//(primitiveType|enumeration|dataType|objectType)">
                <xsl:sort select="vf:asvodmlref(current())"/>
                <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
                <xsl:value-of select="concat('   ',$vodml-id[2], ' ',$lt,$vodml-id[1], '/', string-join(tokenize($vodml-id[2],'[.]'),'/'), $gt,$nl)"/>
            </xsl:for-each>
        </xsl:if>

        <!-- Generate individual type RST files -->
        <xsl:apply-templates select="(primitiveType|enumeration|dataType|objectType|package)"/>
    </xsl:template>

    <!-- Write each top-level type to its own RST file -->
    <xsl:template match="primitiveType|enumeration|dataType|objectType">
        <xsl:variable name="hr" select="concat(string-join(tokenize(vf:asvodmlref(current()),'[:.]'),'/'), '.rst')"/>
        <xsl:message>writing RST description to <xsl:value-of select="$hr"/></xsl:message>
        <xsl:result-document method="text" encoding="UTF-8" href="{$hr}">
            <xsl:apply-templates select="current()" mode="desc"/>
        </xsl:result-document>
    </xsl:template>

    <!-- Write package RST file and recurse into children -->
    <xsl:template match="package">
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:variable name="hr" select="concat($vodml-id[1], '/', $vodml-id[2], '.rst')"/>
        <xsl:message>writing RST description to <xsl:value-of select="$hr"/></xsl:message>
        <xsl:result-document method="text" encoding="UTF-8" href="{$hr}">
            <xsl:apply-templates select="current()" mode="desc"/>
        </xsl:result-document>
        <xsl:apply-templates select="(primitiveType|enumeration|dataType|objectType|package)"/>
    </xsl:template>




    <xsl:template name="makeTarget">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:value-of select="concat('.. _', replace($vodml-ref, '[:.]', '_'), ':', $nl, $nl)"/>
    </xsl:template>
    <!-- desc templates for each type -->

    <xsl:template match="dataType|objectType" mode="desc">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:call-template name="makeTarget"/>
        <xsl:variable name="header">
            <xsl:if test="@abstract">abstract </xsl:if>
            <xsl:value-of select="concat(name(), ' ', name)"/>
        </xsl:variable>
        <xsl:value-of select="concat($header, $nl, vf:underline($header, '='), $nl, $nl)"/>

        <xsl:if test="extends">
            <xsl:text>extends </xsl:text>
            <xsl:apply-templates select="extends/vodml-ref"/>
            <xsl:value-of select="concat($nl, $nl)"/>
        </xsl:if>

        <xsl:apply-templates select="description"/>
        <xsl:value-of select="concat($nl, $nl)"/>

        <xsl:apply-templates select="current()" mode="plantdiag"/>

        <xsl:if test="attribute|reference|composition|constraint[@xsi:type='vo-dml:SubsettedRole']">
            <xsl:text>Members</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Members', '-'), $nl, $nl)"/>
            <xsl:text>.. list-table::</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>   :widths: 20 20 10 50</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>   :header-rows: 1</xsl:text><xsl:value-of select="concat($nl, $nl)"/>
            <xsl:text>   * - Name</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>     - Type</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>     - Multiplicity</xsl:text><xsl:value-of select="$nl"/>
            <xsl:text>     - Description</xsl:text><xsl:value-of select="$nl"/>
            <xsl:apply-templates select="attribute|reference|composition|constraint[@xsi:type='vo-dml:SubsettedRole']" mode="row"/>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:if test="constraint[@xsi:type='vo-dml:SubsettedRole']">
            <xsl:text>Subset Detail</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Subset Detail', '-'), $nl, $nl)"/>
            <xsl:apply-templates select="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="ssdetail"/>
        </xsl:if>

        <xsl:if test="vf:referredTo($vodml-ref) or vf:hasReferencesInContainmentHierarchy($vodml-ref)">
            <xsl:text>References Detail</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('References Detail', '-'), $nl, $nl)"/>
            <xsl:for-each select="reference/datatype/vodml-ref">
                <xsl:choose>
                    <xsl:when test="vf:isContainedInModels(current(),$models/vo-dml:model/name)">
                        <xsl:value-of select="concat('* ', vf:doRstLink(current()), ' is contained in ')"/>
                        <xsl:value-of select="string-join(for $i in vf:containingTypes(current()) return vf:doRstLink(vf:asvodmlref($i)),', ')"/>
                        <xsl:value-of select="$nl"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('* ', vf:doRstLink(current()), ' is model wide.', $nl)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <xsl:if test="vf:referredTo($vodml-ref)">
                <xsl:value-of select="concat($nl, 'This is referred to by ')"/>
                <xsl:value-of select="string-join(for $i in vf:referredBy($vodml-ref) return vf:doRstLink($i),', ')"/>
                <xsl:value-of select="$nl"/>
            </xsl:if>
            <xsl:if test="count(vf:containedReferencesInContainmentHierarchy($vodml-ref)) > 0">
                <xsl:value-of select="concat('Has contained reference(s) ', string-join(for $i in vf:containedReferencesInContainmentHierarchy($vodml-ref) return vf:doRstLink($i),', '), ' in the containment hierarchy.', $nl)"/>
            </xsl:if>
            <xsl:value-of select="$nl"/>
        </xsl:if>

        <xsl:if test="vf:isContainedInModels($vodml-ref,$models/vo-dml:model/name)">
            <xsl:text>Containment</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Containment', '-'), $nl, $nl)"/>
            <xsl:value-of select="concat('This is contained by ', string-join(for $i in vf:containingTypes($vodml-ref) return vf:doRstLink(vf:asvodmlref($i)),', '), $nl)"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="enumeration" mode="desc">
        <xsl:call-template name="makeTarget"/>
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:variable name="header" select="concat('enumeration ', name)"/>
        <xsl:value-of select="concat($header, $nl, vf:underline($header, '='), $nl, $nl)"/>

        <xsl:apply-templates select="description"/>
        <xsl:value-of select="concat($nl, $nl)"/>

        <xsl:apply-templates select="current()" mode="plantdiag"/>

        <xsl:text>Values</xsl:text>
        <xsl:value-of select="concat($nl, vf:underline('Values', '-'), $nl, $nl)"/>
        <xsl:apply-templates select="literal"/>
    </xsl:template>

    <xsl:template match="primitiveType" mode="desc">
        <xsl:call-template name="makeTarget"/>
        <xsl:variable name="header" select="concat('primitiveType ', name)"/>
        <xsl:value-of select="concat($header, $nl, vf:underline($header, '='), $nl, $nl)"/>
        <xsl:apply-templates select="description"/>
        <xsl:value-of select="$nl"/>
    </xsl:template>

    <xsl:template match="package" mode="desc">
        <xsl:call-template name="makeTarget"/>
        <xsl:variable name="header" select="concat('Package ', name)"/>
        <xsl:value-of select="concat($header, $nl, vf:underline($header, '='), $nl, $nl)"/>
        <xsl:apply-templates select="description"/>
        <xsl:value-of select="$nl"/>
        <xsl:if test="package">
            <xsl:text>Contained packages</xsl:text>
            <xsl:value-of select="concat($nl, vf:underline('Contained packages', '-'), $nl, $nl)"/>
            <xsl:for-each select="package">
                <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
                <xsl:value-of select="concat('* :doc:`', name, ' &lt;', $vodml-id[2], '&gt;`', $nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Row template for member tables -->
    <xsl:template match="attribute|reference|composition" mode="row">
        <xsl:text>   * - </xsl:text><xsl:value-of select="name"/>
        <xsl:if test="constraint[ends-with(@xsi:type,':NaturalKey')]"> *(natural key)*</xsl:if>
        <xsl:if test="./self::reference"> *(reference)*</xsl:if>
        <xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="datatype/vodml-ref"/><xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="multiplicity"/><xsl:if test="@isOrdered"> ordered</xsl:if><xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="description"/><xsl:value-of select="$nl"/>
    </xsl:template>

    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="row">
        <xsl:text>   * - </xsl:text><xsl:value-of select="vf:nameFromVodmlref(role/vodml-ref)"/><xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="datatype/vodml-ref"/>
        <xsl:value-of select="concat(' (subset of ', vf:nameFromVodmlref(role/vodml-ref), ')')"/>
        <xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="multiplicity"/><xsl:if test="@isOrdered"> ordered</xsl:if><xsl:value-of select="$nl"/>
        <xsl:text>     - </xsl:text><xsl:apply-templates select="description"/><xsl:value-of select="$nl"/>
    </xsl:template>

    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="ssdetail">
        <xsl:variable name="subSettedTypeId" select="string-join(tokenize(role/vodml-ref,'[.]')[position() != last()],'.')"/>
        <xsl:variable name="subsettedThing" as="element()">
            <xsl:copy-of select="$models/key('ellookup',current()/role/vodml-ref)" />
        </xsl:variable>
        <xsl:variable name="subHeader" select="vf:nameFromVodmlref(role/vodml-ref)"/>
        <xsl:value-of select="concat($subHeader, $nl, vf:underline($subHeader, '~'), $nl, $nl)"/>
        <xsl:value-of select="concat('Subsets ', vf:nameFromVodmlref(role/vodml-ref), ' in ', vf:doRstLink($subSettedTypeId), ' from type ')"/>
        <xsl:value-of select="concat(vf:doRstLink($subsettedThing/datatype/vodml-ref), ' to ', vf:doRstLink(current()/datatype/vodml-ref))"/>
        <xsl:value-of select="$nl"/>
    </xsl:template>

    <!-- link for overview context: path is {modelname}/{id} -->
    <xsl:template name="linkToOverview">
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:value-of select="concat(':doc:`', $vodml-id[2], ' &lt;', $vodml-id[1], '/', string-join(tokenize($vodml-id[2],'[.]'),'/'), '&gt;`')"/>
    </xsl:template>

    <!-- vodml-ref template: renders an RST cross-reference link -->
    <xsl:template match="vodml-ref">
        <xsl:value-of select="vf:doRstLink(.)"/>
    </xsl:template>

    <!-- description: normalize whitespace, skip TODO placeholders -->
    <xsl:template match="description">
        <xsl:if test="not(matches(text(),'^\s*TODO'))"><xsl:value-of select='normalize-space(.)'/></xsl:if>
    </xsl:template>

    <!-- literal (enumeration values) -->
    <xsl:template match="literal">
        <xsl:value-of select="concat('* **', name, '** - ')"/><xsl:apply-templates select="description"/><xsl:value-of select="$nl"/>
    </xsl:template>

    <!-- extends: suppress in default mode (handled inline in desc) -->
    <xsl:template match="extends"/>

    <!-- constraint: suppress in default mode -->
    <xsl:template match="constraint"/>

    <!-- multiplicity -->
    <xsl:template match="multiplicity">
        <xsl:choose>
            <xsl:when test="number(minOccurs) eq 1 and number(maxOccurs) eq 1">1</xsl:when>
            <xsl:when test="number(minOccurs) eq 0 and number(maxOccurs) eq 1">0..1</xsl:when>
            <xsl:when test="number(minOccurs) eq 0 and number(maxOccurs) eq -1">0..*</xsl:when>
            <xsl:when test="number(minOccurs) eq 1 and number(maxOccurs) eq -1">1..*</xsl:when>
            <xsl:otherwise><xsl:value-of select="concat('[',minOccurs,'..', maxOccurs,']')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- PlantUML diagram wrapper for Sphinx (sphinxcontrib-plantuml) -->
    <xsl:template match="enumeration|dataType|objectType" mode="plantdiag">
        <xsl:variable name="diagContent">
            <xsl:apply-templates select="current()" mode="diag"/>
        </xsl:variable>
        <xsl:value-of select="concat($nl, '.. uml::', $nl, $nl)"/>
        <!-- Indent every non-empty line with 3 spaces for RST directive content -->
        <xsl:value-of select="string-join(
            for $line in tokenize(string($diagContent), '\n')
            return (if ($line != '') then concat('   ', $line) else ''),
            $nl)"/>
        <xsl:value-of select="concat($nl, $nl)"/>
    </xsl:template>

    <!-- PlantUML diagram content templates (same logic as vo-dml2md.xsl) -->

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
        <xsl:value-of select="concat(' {', $nl)"/>
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

    <!-- IMPL this uses https://github.com/mi-parkes/sphinx-diagram-connect -->
    <xsl:function name="vf:doPlantUMLLink" >
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="substring-before($vodml-ref,':') = $docmods">
                <xsl:value-of select="concat('url of ',vf:nameFromVodmlref($vodml-ref),' is [[',$dq,':ref:`',replace($vodml-ref, '[:.]', '_'),'`',$dq,']]')"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- do nothing - TODO link to external? -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
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