<?xml version="1.0" encoding="UTF-8"?>
<!-- create standard latex description of data model that is suitable for inclusion in documentation -->

<!-- TODO
see https://tex.stackexchange.com/questions/115400/tikz-image-with-hyperlinks-gif-png-image-html-image-map
https://dot2tex.readthedocs.io/en/latest/index.html
for possible ways to make images with links
-->
<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	            xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1">
  
  <xsl:import href="common.xsl"/>
  <xsl:import href="utype.xsl"/>
  
  <xsl:output method="text" encoding="UTF-8" indent="no" />

  <xsl:strip-space elements="*" />

  <xsl:variable name="packages" select="//package/vodml-id"/>
  <xsl:variable name="sq"><xsl:text>'</xsl:text></xsl:variable>
  <xsl:variable name="dq"><xsl:text>"</xsl:text></xsl:variable>
  <xsl:variable name='nl'><xsl:text>
</xsl:text></xsl:variable>
  <xsl:variable name='lt'><xsl:text disable-output-escaping="yes">&lt;</xsl:text></xsl:variable>
  <xsl:variable name='gt'><xsl:text disable-output-escaping="yes">&gt;</xsl:text></xsl:variable>


  <xsl:variable name="modname">
    <xsl:choose>
      <xsl:when test="/vo-dml:model/vodml-id"><xsl:value-of select="/vo-dml:model/vodml-id"  /></xsl:when>
      <xsl:otherwise><xsl:value-of select="/vo-dml:model/name"  /></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:param name="modelsToDocument" select="$modname"/>

  <xsl:variable name="docmods" as="xsd:string*">
    <xsl:sequence select="tokenize($modelsToDocument,',')"/>
  </xsl:variable>


  <xsl:template match="/">
    <xsl:message>Starting LaTeX description</xsl:message>
    <xsl:apply-templates select="vo-dml:model"/>
  </xsl:template>

  <xsl:template match="vo-dml:model">
    <xsl:message>Found model <xsl:value-of select="$modname"/> - linking <xsl:value-of select="$docmods"/> </xsl:message>
    \section {Automated description of model `<xsl:value-of select="$modname"/>'}

    <xsl:apply-templates select="description"/>

    \subsection {Imported models}

    The following models are used by this model
    \begin{description}
    <xsl:apply-templates select="import"/>
    \end{description}

    \subsection{Model structure index}

    This is an alphabetical index of the types grouped by package.

    <xsl:apply-templates select="." mode="index"/>
    <xsl:apply-templates select="//package" mode="index"/>

    \subsection{Type descriptions for model `<xsl:value-of select="$modname"/>'}
    <xsl:apply-templates select="* except (import|version|description|vodml-id|identifier|lastModified|name|title|author|previousVersion)"/>
  </xsl:template>

  <xsl:template match="vo-dml:model" mode="index">

    \begin{tabular}{ll}
    package &amp; \textit{root} \tabularnewline
    <xsl:call-template name="indexcontent"/>
    \end{tabular}
  </xsl:template>

  <xsl:template match="vodml-id" mode="index">
    <xsl:value-of select="concat('\hyperref[',ancestor::vo-dml:model/name,':',.,']{\mbox{',replace(following-sibling::name,'_','\\_'),'}} ')"/>
  </xsl:template>




  <xsl:template match="package" mode="index">

    \begin{tabular}{ll}
    package &amp; \label{<xsl:value-of select="concat(ancestor::vo-dml:model/name,':',vodml-id)"/>} <xsl:value-of select="vodml-id"/> \tabularnewline
    <xsl:call-template name="indexcontent"/>
     \end{tabular}
  </xsl:template>
  <xsl:template match="package">
    <!-- do not add any document structure for nested packages - not enough subsubsections in LaTeX! -->
    <xsl:apply-templates select="*"/>
  </xsl:template>
  <xsl:template name="indexcontent">
    <xsl:if test="count(objectType) > 0">
    Object types &amp; \parbox[t]{0.6\textwidth}{\raggedright <xsl:apply-templates select="objectType/vodml-id" mode="index" ><xsl:sort select="." order="ascending"/></xsl:apply-templates> }   \tabularnewline
    </xsl:if>
    <xsl:if test="count(dataType) > 0">
    Data types &amp;   \parbox[t]{0.6\textwidth}{\raggedright <xsl:apply-templates select="dataType/vodml-id" mode="index" ><xsl:sort select="." order="ascending"/></xsl:apply-templates> } \tabularnewline
    </xsl:if>
    <xsl:if test="count(enumeration) > 0">
    Enumerations &amp; \parbox[t]{0.6\textwidth}{\raggedright <xsl:apply-templates select="enumeration/vodml-id" mode="index" ><xsl:sort select="." order="ascending"/></xsl:apply-templates>  }  \tabularnewline
    </xsl:if>
    <xsl:if test="count(package) > 0">
    child packages &amp; \parbox[t]{0.6\textwidth}{\raggedright <xsl:apply-templates select="package/vodml-id" mode="index" ><xsl:sort select="." order="ascending"/></xsl:apply-templates>  }   \tabularnewline
    </xsl:if>
  </xsl:template>

  <xsl:template match="import">
     \item[<xsl:value-of select="document(url)/vo-dml:model/name"/>] <xsl:apply-templates select="document(url)/vo-dml:model/description"/>
  </xsl:template>


  <xsl:template match="author">
    <xsl:value-of select="concat($nl,' author ',$dq,.,$dq)"/>
  </xsl:template>

  <xsl:template match="identifier">
    <xsl:value-of select="concat($nl,$lt,.,$gt)"/>
  </xsl:template>



  <xsl:template match="primitiveType">
    \subsubsection*{primitive <xsl:value-of select="name"/>} <xsl:apply-templates select="description"/>
  </xsl:template>

  <!-- remove the local namespace -->
  <xsl:template match='vodml-ref'>

    <xsl:choose>
      <xsl:when test="substring-before(.,':') = $docmods">
        \hyperref[<xsl:value-of select="."/>]{<xsl:value-of select="replace(substring-after(.,':'),'_','\\_')"/>}
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="replace(.,'_','\\_')"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="typeintro">
    \subsubsection*{<xsl:if test="@abstract">abstract </xsl:if> <xsl:value-of select="concat(name(.),' ', replace(name,'_','\\_'))"/>}
    \label{<xsl:value-of select="concat(ancestor::vo-dml:model/name,':',vodml-id)"/>}

    <xsl:apply-templates select= "extends"/>

    <xsl:apply-templates select="description"/>
  </xsl:template>

  <xsl:template match="objectType|dataType">
    <xsl:call-template name="typeintro"/>
    <xsl:if test="count(attribute)> 0">

    attributes:

    \begin{tabular}{lllp{0.5\textwidth}}
    name &amp; type &amp; mult &amp; description \\
    \hline
    <xsl:apply-templates select="attribute"/>
    \end{tabular}
    </xsl:if>

    <xsl:if test="count(composition)> 0">

    compositions:

    \begin{tabular}{lllp{0.5\textwidth}}
    name &amp; type &amp; mult &amp; description \\
    \hline
    <xsl:apply-templates select="composition"/>
    \end{tabular}

    </xsl:if>
    <xsl:if test="count(reference)> 0">

    references:

    \begin{tabular}{lllp{0.5\textwidth}}
    name &amp; type &amp; mult &amp; description \\
    \hline
    <xsl:apply-templates select="reference"/>
    \end{tabular}
    </xsl:if>
  </xsl:template>

  <xsl:template match ="description">
    <xsl:if test="not(matches(text(),'^\s*TODO'))"><xsl:value-of select='translate(.,$dq,$sq)'/></xsl:if><xsl:text></xsl:text>
  </xsl:template>

  <xsl:template match="attribute|reference|composition">
    <xsl:value-of select="replace(name, '_','\\_')"/>
    <xsl:text> &amp; </xsl:text>
    <xsl:apply-templates select="datatype/vodml-ref"/>
    <xsl:text> &amp; </xsl:text>
    <xsl:apply-templates select="multiplicity"/><xsl:if test="@isOrdered"><xsl:text> ordered</xsl:text></xsl:if>
    <xsl:text> &amp; </xsl:text>
    <xsl:apply-templates select="description"/>
    <xsl:value-of select="concat('\\',$cr)"/>
  </xsl:template>


  <xsl:template match="utype">
    <xsl:choose>
      <xsl:when test="starts-with(text(),'ivoa:')"><xsl:value-of select="substring-after(text(),'ivoa:')"/></xsl:when> <!-- assume the ivoa namespace as default -->
      <xsl:when test="starts-with(text(),concat(/vo-dml:model/vodml-id,':')) or starts-with(text(),concat(/vo-dml:model/name,':'))">
        <!-- TODO should deal with nested packages -->
        <xsl:variable name="pname" select="ancestor::package/name/text()"/>
        <xsl:for-each select="tokenize(substring-after(text(),':'), '\.')">
          <xsl:if test=". ne $pname or position() eq last()"><xsl:sequence select="."/>
          </xsl:if>

        </xsl:for-each>

      </xsl:when>
      <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
    </xsl:choose>
    <xsl:text> /* utype=</xsl:text><xsl:value-of select="."/><xsl:text>*/</xsl:text>
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

  <xsl:template match="enumeration">
    <xsl:call-template name="typeintro"/>

    values:

    \begin{description}
    <xsl:apply-templates select="literal"/>
    \end{description}
  </xsl:template>

  <xsl:template match="literal">
    \item[<xsl:value-of select="name"/>] <xsl:text> </xsl:text><xsl:apply-templates select="description"/>
  </xsl:template>

  <xsl:template match="extends">
    <xsl:text>\par extends </xsl:text><xsl:apply-templates/><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="semanticconcept">
    <xsl:text>\par semantic "</xsl:text><xsl:value-of select="topConcept"/><xsl:text>" in "</xsl:text><xsl:value-of select="vocabularyURI"/><xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']"><!-- FIXME these apply to attributes...I think.... -->
    <xsl:text>
   \par  subset </xsl:text> <xsl:value-of select="role/vodml-ref"/><xsl:text> as </xsl:text><xsl:value-of select="datatype/vodml-ref"/><xsl:text>;</xsl:text>
  </xsl:template>


  <xsl:template match="constraint">
    <xsl:text>\par constraint  </xsl:text><xsl:apply-templates select="description"/>
  </xsl:template>



  <xsl:template match="text()|*">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- catchall to indicate where there might be missed element to highlight when VODML might have changed
 <xsl:template match="*">
   <xsl:value-of select="concat('***',name(.),'*** ')"/>
    <xsl:apply-templates/>
 </xsl:template>

 -->


</xsl:stylesheet>
