<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
<!ENTITY nbsp "&#160;">
<!ENTITY tab "&#160;&#160;&#160;&#160;">
]>
<!-- 
This stylesheet will create markdown description of the model, primarily targeted at
further processing by mkdocs to produce complete model documentation.
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
    xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
>
    <xsl:output method="text" encoding="UTF-8" indent="no" />
    <xsl:output method="xml" encoding="UTF-8" indent="no" name="svgform" omit-xml-declaration="true" />
    <xsl:output method="text" encoding="UTF-8" indent="no" name="nav" />

  <xsl:param name="binding"/>
  <!-- IF Graphviz png and map are available use these  -->
  <xsl:param name="graphviz_png"/>
    <xsl:variable name="modname">
        <xsl:choose>
            <xsl:when test="/vo-dml:model/vodml-id"><xsl:value-of select="/vo-dml:model/vodml-id"  /></xsl:when>
            <xsl:otherwise><xsl:value-of select="/vo-dml:model/name"  /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:param name="modelsToDocument"/>
    <xsl:param name="autoGenDirName" select="'generated'"/>



    <xsl:variable name="thisModelName" select="/vo-dml:model/name"/>


  <xsl:include href="binding_setup.xsl"/>
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
  

  <xsl:template match="/">
    <xsl:message>Starting Markdown documentation for <xsl:value-of select="vo-dml:model/name"/> </xsl:message>
    <xsl:apply-templates select="vo-dml:model"/>
  </xsl:template>
  

  
  <xsl:template match="vo-dml:model">
# <xsl:value-of select="name"/>
&cr;
<xsl:value-of select="concat('version ',version, ' _',(format-dateTime(xsd:dateTime(lastModified),'[Y0001]-[M01]-[D01]')),'_')"/>

&cr;
## Introduction

<xsl:value-of select="description"/>
&cr;
### Authors

<xsl:value-of select="author"/>


    <xsl:if test="$graphviz_png">
&cr;
### Overview diagram

The whole model is represented in a model diagram below


 <!-- IMPL should create temp file name -->
  <xsl:result-document format="svgform" href="/tmp/test.svg">
  <xsl:apply-templates select="document($graphviz_png)" mode="svg"/>
  </xsl:result-document>
  <xsl:value-of select="unparsed-text('/tmp/test.svg')"/>

    </xsl:if>

<xsl:if test="//package">
## Packages

    <xsl:for-each select="//package"> <!-- FIXME does not do nested packages nicely -->
        <xsl:sort select="name"/>
* <xsl:value-of select="concat('*',name,'*')"/> <xsl:apply-templates select="description"/>
    </xsl:for-each>
</xsl:if>

<xsl:if test="//primitiveType">
## Primitives

    <xsl:for-each select="//primitiveType">
        <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
</xsl:if>

      <xsl:if test="//enumeration">

## Enums

    <xsl:for-each select="//enumeration">
        <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
      </xsl:if>

      <xsl:if test="//dataType">

## DataTypes

    <xsl:for-each select="//dataType">
        <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
      </xsl:if>

      <xsl:if test="//objectType">

## ObjectTypes

    <xsl:for-each select="//objectType">
    <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/>
    </xsl:for-each>
      </xsl:if>

      <xsl:if test="//reference/datatype/vodml-ref">
## References

        <xsl:for-each select="//(dataType|objectType)[vf:asvodmlref(.) = distinct-values(//reference/datatype/vodml-ref)]">
            <xsl:sort select="name"/>
* <xsl:call-template name="linkTo"/><xsl:if test="vf:isContained(vf:asvodmlref(current()))"> contained</xsl:if>

        </xsl:for-each>

      </xsl:if>

      <xsl:if test="import">
&cr;
## Imports
          <xsl:for-each select="import">
              <xsl:variable name="bnd" select="$mapping/bnd:mappedModels/model[file=current()/url]"/>
* <xsl:value-of select="concat($bnd/name, $nl)"/>
          </xsl:for-each>
      </xsl:if>


      <!-- now main doc for each type in separate files -->
     <xsl:apply-templates select="(primitiveType|enumeration|dataType|objectType|package)"/>
     <xsl:apply-templates select="current()" mode="nav"/>
  </xsl:template>

    <xsl:template match="vo-dml:model" mode="nav">
        <xsl:variable name="outf" select="concat(substring-before(vf:fileNameFromModelName(name),'.xml'),'_nav.json')"/>
        <xsl:result-document href="{$outf}" format="nav" >

            {
            "<xsl:value-of select="concat(name,' model')" />": [
            {
            "Overview": "<xsl:value-of select="concat($autoGenDirName,'/',substring-before(vf:fileNameFromModelName(name),'.xml'),'.md')"/>"
            }

            <xsl:if test="//objectType">
                ,{
                "ObjectTypes": [

                <xsl:for-each select="//objectType">
                    <xsl:sort select="vf:asvodmlref(current())"/>
                    <xsl:call-template name="jsonNav"/>
                    <xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
                ]
                }
            </xsl:if>
            <xsl:if test="//dataType">
                ,{
                "DataTypes": [
                <xsl:for-each select="//dataType">
                    <xsl:sort select="vf:asvodmlref(current())"/>
                    <xsl:call-template name="jsonNav"/>
                    <xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
                ]
                }
            </xsl:if>
            <xsl:if test="//primitiveType">
                ,{
                "PrimitiveTypes": [
                <xsl:for-each select="//primitiveType">
                    <xsl:sort select="vf:asvodmlref(current())"/>
                    <xsl:call-template name="jsonNav"/>
                    <xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
                ]
                }
            </xsl:if>
            <xsl:if test="//enumeration">
                ,{
                "Enumerations": [
                <xsl:for-each select="//enumeration">
                    <xsl:sort select="vf:asvodmlref(current())"/>
                    <xsl:if test="position() != 1">,</xsl:if>
                    <xsl:call-template name="jsonNav"/>
                </xsl:for-each>
                ]
                }
            </xsl:if>
            ]
            }

        </xsl:result-document>
    </xsl:template>

  <xsl:template match="primitiveType|enumeration|dataType|objectType">
      <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
      <xsl:variable name="hr" select="concat($vodml-id[1],'/',$vodml-id[2],'.md')"/>
      <xsl:message>writing description to <xsl:value-of select="$hr"/></xsl:message>
      <xsl:result-document method="text" encoding="UTF-8" indent="no" href="{$hr}">
          <xsl:apply-templates select="current()" mode="desc"/>
      </xsl:result-document>

  </xsl:template>
    <xsl:template match="package">
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:variable name="hr" select="concat($vodml-id[1],'/',$vodml-id[2],'.md')"/>
        <xsl:message>writing description to <xsl:value-of select="$hr"/></xsl:message><!-- TODO this package file itself not linked in final docs - is it useful? -->
        <xsl:result-document method="text" encoding="UTF-8" indent="no" href="{$hr}">
            <xsl:apply-templates select="current()" mode="desc"/>
        </xsl:result-document>
        <xsl:apply-templates select="(primitiveType|enumeration|dataType|objectType|package)"/>
    </xsl:template>

  <xsl:template match="primitiveType|dataType|objectType" mode="desc">
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
# <xsl:if test="@abstract">_abstract_</xsl:if>  <xsl:value-of select="concat(' ', name(),' ', name)"/>

      <xsl:if test="extends">
          &cr;<xsl:text>extends </xsl:text>
          <xsl:apply-templates select="extends/vodml-ref"/>
          &cr;
      </xsl:if>
&cr;&cr;
      <xsl:apply-templates select="description"/>
&cr;
      <xsl:if test="name() != 'primitiveType'">
      <xsl:apply-templates select="current()" mode="mermdiag"/>


## Members

|      name | type | mult | description |
|-----------|------|------|-------------|
      <xsl:apply-templates select="* except(description|name|extends|vodml-id)"/>

    <xsl:if test="constraint[@xsi:type='vo-dml:SubsettedRole']">

## Subset Detail

        <xsl:apply-templates select="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="ssdetail"/>
    </xsl:if>
</xsl:if>
    <xsl:if test="vf:referredTo($vodml-ref) or vf:hasReferencesInContainmentHierarchy($vodml-ref)">
## References Detail

      <xsl:for-each select="reference/datatype/vodml-ref">
          <xsl:choose>
              <xsl:when test="vf:isContained(current())">
*  <xsl:value-of select="vf:doLink(current())"/> is contained in  <xsl:value-of select="string-join(for $i in vf:containingTypes(current()) return vf:doLink(vf:asvodmlref($i)),', ')"/>
              </xsl:when>
              <xsl:otherwise>
*  <xsl:value-of select="vf:doLink(current())"/>  is model wide.
              </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>

      <xsl:if test="vf:referredTo($vodml-ref)">
This is referred to by <xsl:value-of select="string-join(for $i in vf:referredBy($vodml-ref) return vf:doLink($i),', ')"/>

    </xsl:if>
      <xsl:if test="count(vf:containedReferencesInContainmentHierarchy($vodml-ref)) > 0">
Has contained reference(s) <xsl:value-of select="string-join(for $i in vf:containedReferencesInContainmentHierarchy($vodml-ref) return vf:doLink($i),', ')"/> in the containment hierarchy.
      </xsl:if>
       <!-- TODO report on the bad contained references - ie those in another containment hierarchy -->
       <!-- FIXME still not sure that this is really reporting what we want - i.e. knowing when to do special cloning for a particular type
        in this case it would be good to report where in the containment hierarchy-->

    </xsl:if>

    <xsl:if test="vf:isContained($vodml-ref)">

## Containment

This is contained by <xsl:value-of select="string-join(for $i in vf:containingTypes($vodml-ref) return vf:doLink(vf:asvodmlref($i)),', ')"/>
    </xsl:if>


  </xsl:template>
    <xsl:template match="enumeration" mode="desc">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
# <xsl:if test="@abstract">_abstract_</xsl:if>  <xsl:value-of select="concat(' ', name(),' ', name)"/>

&cr;


        <xsl:apply-templates select="description"/>
        <xsl:apply-templates select="current()" mode="mermdiag"/>

## Values

        <xsl:apply-templates select="literal"/>

    </xsl:template>

    <xsl:template match="package" mode="desc">
# Package <xsl:value-of select="concat(name,$nl)"/>

        <xsl:apply-templates select="description"/>

        <xsl:if test="package">

## Contained packages

            <xsl:for-each select="package">
* <xsl:value-of select="concat('[',name,'](',name,'.md)')"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="description">
        <xsl:if test="not(matches(text(),'^\s*TODO'))"><xsl:value-of select='normalize-space(.)'/></xsl:if><xsl:text></xsl:text>
    </xsl:template>

    <xsl:template match="enumeration|dataType|objectType" mode="mermdiag">
&cr;&cr;
```plantuml format="svg_inline"
hide empty members
        <xsl:apply-templates select="current()" mode="diag"/>
```
&cr;
    </xsl:template>

    <xsl:template match="enumeration" mode="diag">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        enum <xsl:value-of select="name"/>{
           <xsl:for-each select="literal">
               <xsl:value-of select="concat(name,$nl)"/>
           </xsl:for-each>
        }
    </xsl:template>
    <xsl:template match="dataType|objectType" mode="diag">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
        <xsl:variable name="thisClass" select="name"/>
        <xsl:if test="@abstract">abstract</xsl:if> class <xsl:value-of select="name"/>
        <xsl:if test="current()/name()='dataType'"><xsl:text> &lt;&lt;dataType&gt;&gt;</xsl:text></xsl:if><xsl:text> #LightGray ##[bold]Purple</xsl:text>
        {
        <xsl:apply-templates select="(attribute|constraint)" mode="diag"/>
        }
        <xsl:call-template name="doSupers"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doSubs"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>
        <xsl:call-template name="doRefs"/>
        <xsl:call-template name="doComposition"/>
        <xsl:call-template name="doDiagLinks"><xsl:with-param name="vodml-ref" select="$vodml-ref"/> </xsl:call-template>

    </xsl:template>

    <xsl:template match="attribute" mode="diag">
        <xsl:value-of select="concat(datatype/vodml-ref,' ',name,$nl)"/>
    </xsl:template>
    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="diag">
        <xsl:value-of select="concat(datatype/vodml-ref,' ',vf:nameFromVodmlref(role/vodml-ref),$nl)"/>
    </xsl:template>

    <xsl:template match="constraint" mode="diag">
        <!-- don't display general constraints -->
    </xsl:template>

    <xsl:template match="attribute|reference|composition">
        <xsl:text> | </xsl:text>
        <xsl:value-of select="name"/>
        <xsl:if test="constraint[ends-with(@xsi:type,':NaturalKey')]">
            <xsl:value-of select="concat(' :material-key-variant:{title=',$dq,'natural key',$dq,'}')"/>
        </xsl:if>
        <xsl:if test="./self::reference">
            <xsl:value-of select="concat(' :material-arrow-top-right:{title=',$dq,'reference',$dq,'}')"/>
        </xsl:if>

        <xsl:text> | </xsl:text>
        <xsl:apply-templates select="datatype/vodml-ref"/>
        <xsl:if test="semanticconcept">
             <xsl:value-of select="concat(' from [',semanticconcept/vocabularyURI,'](',semanticconcept/vocabularyURI,'){:target=',$dq,'_blank',$dq,'}')"/>
        </xsl:if>
        <xsl:text> | </xsl:text>
        <xsl:apply-templates select="multiplicity"/><xsl:if test="@isOrdered"><xsl:text> ordered</xsl:text></xsl:if>
        <xsl:text> | </xsl:text>
        <xsl:value-of select="string-join(for $s in description/text() return normalize-space($s),' ')"/>
        <xsl:text> | </xsl:text> &cr;
    </xsl:template>

    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']">
        <xsl:text> | </xsl:text>
        <xsl:value-of select="vf:nameFromVodmlref(role/vodml-ref)"/>
        <xsl:text> | </xsl:text>
        <xsl:apply-templates select="datatype/vodml-ref" />
        <xsl:value-of select="concat(' [subset](#',vf:nameFromVodmlref(role/vodml-ref),')')" />
        <xsl:text> | </xsl:text>
        <xsl:apply-templates select="multiplicity"/><xsl:if test="@isOrdered"><xsl:text> ordered</xsl:text></xsl:if>
        <xsl:text> | </xsl:text>
        <xsl:value-of select="string-join(for $s in description/text() return normalize-space($s),' ')"/>
        <xsl:text> | </xsl:text> &cr;
    </xsl:template>

    <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="ssdetail">

### <xsl:value-of select="vf:nameFromVodmlref(role/vodml-ref)"/>
          <xsl:variable name="subSettedTypeId" select="string-join(tokenize(role/vodml-ref,'[.]')[position() != last()],'.')"/>
        <xsl:variable name="subsettedThing" as="element()">
            <xsl:copy-of select="$models/key('ellookup',current()/role/vodml-ref)" />
        </xsl:variable>
Subsets <xsl:value-of select="concat(vf:nameFromVodmlref(role/vodml-ref), ' in ',vf:doLink($subSettedTypeId), ' from type ')"/>
        <xsl:value-of select="concat(vf:doLink($subsettedThing/datatype/vodml-ref), ' to ',vf:doLink(current()/datatype/vodml-ref))"/>
        <xsl:if test="semanticconcept">
            <xsl:text> with </xsl:text><xsl:apply-templates select="semanticconcept" mode="ssdetail"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match='vodml-ref'>
        <xsl:value-of select="vf:doLink(.)"/>
    </xsl:template>

    <xsl:template match="literal">
 *  <xsl:value-of select="concat('*',name,'*')"/><xsl:text> - </xsl:text><xsl:apply-templates select="description"/>&cr;
    </xsl:template>

    <xsl:template match="extends">
        <!-- nothing in general description -->
    </xsl:template>

    <xsl:template match="semanticconcept" mode="ssdetail">
        <xsl:choose>
            <xsl:when test="count(topConcept) = 0">
                <text> vocabulary from </text><xsl:value-of select="concat('[',vocabularyURI,'](',vocabularyURI,')')"/><!-- TODO  would be nice to display vocab inline as collapsible tree-->
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>semantic meaning "</xsl:text><xsl:value-of select="topConcept"/><xsl:text>" in "</xsl:text><xsl:value-of select="vocabularyURI"/><xsl:text>"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>




    <xsl:template match="constraint">
        <!-- dont output in notmal mode-->
    </xsl:template>

    <xsl:template match="constraint" mode="desc">
        <xsl:text>constraint  </xsl:text><xsl:apply-templates select="description"/>
    </xsl:template>

    <xsl:template match="multiplicity">
        <xsl:choose>
            <xsl:when test="number(minOccurs) eq 1 and number(maxOccurs) eq 1"><!-- do nothing --></xsl:when>
            <xsl:when test="number(minOccurs) eq 0 and number(maxOccurs) eq 1"> optional</xsl:when>
            <xsl:when test="number(minOccurs) eq 0 and number(maxOccurs) eq -1"> 0 or more </xsl:when>
            <xsl:when test="number(minOccurs) eq 1 and number(maxOccurs) eq -1"> 1 or more </xsl:when>
            <xsl:otherwise><xsl:value-of select="concat('[',minOccurs,'..', maxOccurs,']')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- diagrams -->
    <xsl:function name="vf:diagclassdef" as="xsd:string">
        <xsl:param name="vodml-ref"/>
        <xsl:variable name="thisClass" as="element()">
            <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
        </xsl:variable>
        <xsl:variable name="result">
        <xsl:if test="$thisClass/@abstract">abstract </xsl:if> class <xsl:value-of select="$thisClass/name"/><xsl:if test="name($thisClass)='dataType'"> &lt;&lt;dataType&gt;&gt;</xsl:if>
        </xsl:variable>
        <xsl:value-of select="string-join($result)"/>
    </xsl:function>
    <xsl:template name="doSupers">
        <xsl:param name="vodml-ref"/>
        <xsl:if test="vf:hasSuperTypes($vodml-ref)">
            <xsl:variable name="thisClass" as="element()">
                <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
            </xsl:variable>
            <xsl:variable name="bases" select="vf:baseTypeIds($vodml-ref)"/>
            <xsl:value-of select="vf:diagclassdef($bases[1]),$nl"/>
            <xsl:value-of select="concat($thisClass/name,' -[#red]-|',$gt,' ',vf:nameFromVodmlref($bases[1]),$nl)"/>
            <xsl:for-each select="1 to count($bases) -1">
                <xsl:value-of select="concat(vf:diagclassdef($bases[xsd:integer(current())+1]),$nl,vf:nameFromVodmlref($bases[xsd:integer(current())]),' -[#red]-|',$gt,' ',vf:nameFromVodmlref($bases[xsd:integer(current())+1]),$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template name="doDiagLinks">
        <xsl:param name="vodml-ref"/>
        <xsl:param name="type">plantuml</xsl:param>
        <xsl:variable name="thisClass" as="element()">
            <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
        </xsl:variable>
        <xsl:variable name="classIds" as="xsd:string*">
            <xsl:sequence  select="vf:baseTypeIds($vodml-ref)"/>
            <xsl:sequence select="for $x in //*[extends/vodml-ref = $vodml-ref] return vf:asvodmlref($x)"/>
            <xsl:sequence select="$thisClass/reference/datatype/vodml-ref"/>
            <xsl:sequence select="$thisClass/composition/datatype/vodml-ref"/>
        </xsl:variable>
        <xsl:for-each select="$classIds">
            <xsl:choose>
                <xsl:when test="$type = 'mermaid'">
                    <xsl:value-of select="concat($nl,vf:doMermaidLink(current()))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($nl,vf:doPlantUMLLink(current()))"/>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:for-each>

    </xsl:template>
    <xsl:template name="doSubs">
        <xsl:param name="vodml-ref"/>
        <xsl:if test="count(//*[extends/vodml-ref = $vodml-ref]) > 0">
            <xsl:variable name="thisClass" as="element()">
                <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
            </xsl:variable>
            <xsl:for-each select="for $x in //*[extends/vodml-ref = $vodml-ref] return vf:asvodmlref($x) ">
                <xsl:value-of select="concat(vf:diagclassdef(current()),$nl,vf:nameFromVodmlref(current()),' -[#red]-|',$gt,' ',$thisClass/name,$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template name="doRefs">
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:if test="reference">
            <xsl:for-each select="reference">
                <xsl:value-of select="concat(vf:diagclassdef(current()/datatype/vodml-ref),$nl,$thisClass,' -[#green]-',$gt,' ',vf:multiplicityForDiagram(current()/multiplicity),' ',vf:nameFromVodmlref(current()/datatype/vodml-ref),' : ',current()/name,$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template name="doComposition">
        <xsl:variable name="thisClass" select="current()/name"/>
        <xsl:if test="composition">
            <xsl:for-each select="composition">

                <xsl:value-of select="concat(vf:diagclassdef(current()/datatype/vodml-ref),$nl,$thisClass,' *-[#blue]- ',vf:multiplicityForDiagram(current()/multiplicity),' ',vf:nameFromVodmlref(current()/datatype/vodml-ref),' : ',current()/name,$nl)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="/" mode="svg" priority="300">
        <div>
            <xsl:apply-templates select="@*|node()" mode="svg"/>
        </div>
    </xsl:template>
    <xsl:template match="comment()" mode="svg" priority="200"/>
    <xsl:template match="@*|node()" mode="svg" priority="100">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="svg"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="linkTo" as="xsd:string" > <!-- only works from top level overview -->
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:value-of select="concat('[',$vodml-id[2],'](',$vodml-id[1],'/',$vodml-id[2],'.md)')"/>
    </xsl:template>

    <xsl:template name="jsonNav" as="xsd:string" > <!-- only works from top level overview -->
        <xsl:variable name="vodml-id" select="tokenize(vf:asvodmlref(current()),':')" as="xsd:string*"/>
        <xsl:value-of select="concat('{',$dq,$vodml-id[2],$dq,' : ',$dq,$autoGenDirName,'/',$vodml-id[1],'/',$vodml-id[2],'.md',$dq,'}')"/>
    </xsl:template>

    <xsl:template name="tooltip">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="type" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:choose>
            <xsl:when test="name($type) = 'primitiveType'">
                <xsl:value-of select="concat(name($type),' ',$type/name,' - ',normalize-space($type/description))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="name($type)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:function name="vf:doLink" >
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="substring-before($vodml-ref,':') = $docmods">
                <xsl:variable name="tooltip">
                    <xsl:call-template name="tooltip">
                        <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="substring-before($vodml-ref,':')= $thisModelName">
                        <xsl:value-of select="concat('[',substring-after($vodml-ref,':'),'](',substring-after($vodml-ref,':'),'.md ',$dq,$tooltip,$dq,')')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('[',$vodml-ref,'](../',substring-before($vodml-ref,':'),'/',substring-after($vodml-ref,':'),'.md ',$dq,$tooltip,$dq,')')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$vodml-ref"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="vf:doPlantUMLLink" >
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="substring-before($vodml-ref,':') = $docmods">
                <xsl:choose>
                    <xsl:when test="substring-before($vodml-ref,':')= $thisModelName">
                        <xsl:value-of select="concat('url of ', vf:nameFromVodmlref($vodml-ref),' is [[../',substring-after($vodml-ref,':'),']]')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('url of ',vf:nameFromVodmlref($vodml-ref),' is [[../../',substring-before($vodml-ref,':'),'/',substring-after($vodml-ref,':'),']]')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- do nothing - TODO link to external? -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="vf:doMermaidLink" >
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="substring-before($vodml-ref,':') = $docmods">
                <xsl:choose>
                    <xsl:when test="substring-before($vodml-ref,':')= $thisModelName">
                        <xsl:value-of select="concat('link ', vf:nameFromVodmlref($vodml-ref),' ',$dq,'../',substring-after($vodml-ref,':'),$dq)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('link ',vf:nameFromVodmlref($vodml-ref),' ',$dq,'../../',substring-before($vodml-ref,':'),'/',substring-after($vodml-ref,':'),$dq)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- do nothing - TODO link to external? -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:multiplicityForDiagram" as="xsd:string*">
        <xsl:param name="m" as="element()"/>
        <xsl:variable name="r">
        <xsl:choose>
            <xsl:when test="not($m/minOccurs) and not($m/maxOccurs)">1</xsl:when>
            <xsl:when test="number($m/minOccurs) eq 1 and number($m/maxOccurs) eq 1">1</xsl:when>
            <xsl:when test="number($m/minOccurs) eq 0 and (number($m/maxOccurs) eq 1 or not($m/maxOccurs))">0..1</xsl:when>
            <xsl:when test="number($m/minOccurs) eq 0 and number($m/maxOccurs) lt 1">0..*</xsl:when>
            <xsl:when test="(not($m/minOccurs) or number($m/minOccurs) eq 1) and number($m/maxOccurs) lt 1">1..*</xsl:when>
            <xsl:when test="not($m/minOccurs) and $m/maxOccurs"><xsl:value-of select="concat('1..', $m/maxOccurs)"/></xsl:when>
            <xsl:when test="not($m/maxOccurs) and $m/minOccurs"><xsl:value-of select="concat($m/maxOccurs,'..', $m/maxOccurs)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($m/minOccurs,'..', $m/maxOccurs)"/></xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="concat($dq,$r,$dq)"/>

    </xsl:function>
</xsl:stylesheet>
