<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:schold="http://www.ascc.net/xml/schematron"
                xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1.0"
                xmlns:fct="localFunctions"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                version="2.0"><!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. -->
<xsl:param name="archiveDirParameter"/>
  <xsl:param name="archiveNameParameter"/>
  <xsl:param name="fileNameParameter"/>
  <xsl:param name="fileDirParameter"/>
  <xsl:variable name="document-uri">
    <xsl:value-of select="document-uri(/)"/>
  </xsl:variable>

  <!--PHASES-->


<!--PROLOG-->
<xsl:output xmlns:svrl="http://purl.oclc.org/dsdl/svrl" method="xml"
              omit-xml-declaration="no"
              standalone="yes"
              indent="yes"/>

  <!--XSD TYPES FOR XSLT2-->


<!--KEYS AND FUNCTIONS-->
<xsl:function xmlns:sch="http://purl.oclc.org/dsdl/schematron" name="fct:vo-dml_element"
                as="xs:string">
    <!--  returns name of element containing the vodml-id identified by the vodml-ref -->
        <xsl:param name="vodml-ref"/>
        <xsl:param name="model"/>

		  <xsl:variable name="prefix" select="substring-before($vodml-ref,':')"/>
    <xsl:variable name="targetvodml-ref" select="substring-after($vodml-ref,concat($prefix,':'))"/>
        <xsl:choose>
            <xsl:when test="$prefix = $model/name">
                <xsl:value-of select="$model//*[vodml-id = $targetvodml-ref]/name()"/>
            </xsl:when>
            <xsl:otherwise>
            	<xsl:variable name="import" select="$model/import[name = $prefix]/url"/>
            	<xsl:choose>
            	<xsl:when test="$import">
            	  <xsl:variable name="doc" select="document($import)"/>
                  <xsl:value-of select="$doc//*[vodml-id = $targetvodml-ref]/name()"/>
            	</xsl:when>
            	<xsl:otherwise>
            	<xsl:value-of select="'ERROR'"/>
            	</xsl:otherwise>
            	</xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

  <!--DEFAULT RULES-->


<!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<xsl:template match="*" mode="schematron-select-full-path">
    <xsl:apply-templates select="." mode="schematron-get-full-path"/>
  </xsl:template>

  <!--MODE: SCHEMATRON-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<xsl:template match="*" mode="schematron-get-full-path">
    <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
    <xsl:text>/</xsl:text>
    <xsl:choose>
      <xsl:when test="namespace-uri()=''">
        <xsl:value-of select="name()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>*:</xsl:text>
        <xsl:value-of select="local-name()"/>
        <xsl:text>[namespace-uri()='</xsl:text>
        <xsl:value-of select="namespace-uri()"/>
        <xsl:text>']</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:variable name="preceding"
                  select="count(preceding-sibling::*[local-name()=local-name(current())                                   and namespace-uri() = namespace-uri(current())])"/>
    <xsl:text>[</xsl:text>
    <xsl:value-of select="1+ $preceding"/>
    <xsl:text>]</xsl:text>
  </xsl:template>
  <xsl:template match="@*" mode="schematron-get-full-path">
    <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
    <xsl:text>/</xsl:text>
    <xsl:choose>
      <xsl:when test="namespace-uri()=''">@<xsl:value-of select="name()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>@*[local-name()='</xsl:text>
        <xsl:value-of select="local-name()"/>
        <xsl:text>' and namespace-uri()='</xsl:text>
        <xsl:value-of select="namespace-uri()"/>
        <xsl:text>']</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--MODE: SCHEMATRON-FULL-PATH-2-->
<!--This mode can be used to generate prefixed XPath for humans-->
<xsl:template match="node() | @*" mode="schematron-get-full-path-2">
    <xsl:for-each select="ancestor-or-self::*">
      <xsl:text>/</xsl:text>
      <xsl:value-of select="name(.)"/>
      <xsl:if test="preceding-sibling::*[name(.)=name(current())]">
        <xsl:text>[</xsl:text>
        <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="not(self::*)">
      <xsl:text/>/@<xsl:value-of select="name(.)"/>
    </xsl:if>
  </xsl:template>
  <!--MODE: SCHEMATRON-FULL-PATH-3-->
<!--This mode can be used to generate prefixed XPath for humans 
	(Top-level element has index)-->
<xsl:template match="node() | @*" mode="schematron-get-full-path-3">
    <xsl:for-each select="ancestor-or-self::*">
      <xsl:text>/</xsl:text>
      <xsl:value-of select="name(.)"/>
      <xsl:if test="parent::*">
        <xsl:text>[</xsl:text>
        <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="not(self::*)">
      <xsl:text/>/@<xsl:value-of select="name(.)"/>
    </xsl:if>
  </xsl:template>

  <!--MODE: GENERATE-ID-FROM-PATH -->
<xsl:template match="/" mode="generate-id-from-path"/>
  <xsl:template match="text()" mode="generate-id-from-path">
    <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
    <xsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
  </xsl:template>
  <xsl:template match="comment()" mode="generate-id-from-path">
    <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
    <xsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
  </xsl:template>
  <xsl:template match="processing-instruction()" mode="generate-id-from-path">
    <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
    <xsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/>
  </xsl:template>
  <xsl:template match="@*" mode="generate-id-from-path">
    <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
    <xsl:value-of select="concat('.@', name())"/>
  </xsl:template>
  <xsl:template match="*" mode="generate-id-from-path" priority="-0.5">
    <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
    <xsl:text>.</xsl:text>
    <xsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/>
  </xsl:template>

  <!--MODE: GENERATE-ID-2 -->
<xsl:template match="/" mode="generate-id-2">U</xsl:template>
  <xsl:template match="*" mode="generate-id-2" priority="2">
    <xsl:text>U</xsl:text>
    <xsl:number level="multiple" count="*"/>
  </xsl:template>
  <xsl:template match="node()" mode="generate-id-2">
    <xsl:text>U.</xsl:text>
    <xsl:number level="multiple" count="*"/>
    <xsl:text>n</xsl:text>
    <xsl:number count="node()"/>
  </xsl:template>
  <xsl:template match="@*" mode="generate-id-2">
    <xsl:text>U.</xsl:text>
    <xsl:number level="multiple" count="*"/>
    <xsl:text>_</xsl:text>
    <xsl:value-of select="string-length(local-name(.))"/>
    <xsl:text>_</xsl:text>
    <xsl:value-of select="translate(name(),':','.')"/>
  </xsl:template>
  <!--Strip characters--><xsl:template match="text()" priority="-1"/>

  <!--SCHEMA SETUP-->
<xsl:template match="/">
    <svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl" title="Schematron VO-DML Validator"
                            schemaVersion="">
      <xsl:comment>
        <xsl:value-of select="$archiveDirParameter"/>   
		 <xsl:value-of select="$archiveNameParameter"/>  
		 <xsl:value-of select="$fileNameParameter"/>  
		 <xsl:value-of select="$fileDirParameter"/>
      </xsl:comment>
      <svrl:ns-prefix-in-attribute-values uri="http://www.ivoa.net/xml/VODML/v1.0" prefix="vo-dml"/>
      <svrl:ns-prefix-in-attribute-values uri="localFunctions" prefix="fct"/>
      <svrl:ns-prefix-in-attribute-values uri="http://www.w3.org/2001/XMLSchema-instance" prefix="xsi"/>
      <svrl:active-pattern>
        <xsl:attribute name="document">
          <xsl:value-of select="document-uri(/)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </svrl:active-pattern>
      <xsl:apply-templates select="/" mode="M4"/>
      <svrl:active-pattern>
        <xsl:attribute name="document">
          <xsl:value-of select="document-uri(/)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </svrl:active-pattern>
      <xsl:apply-templates select="/" mode="M5"/>
      <svrl:active-pattern>
        <xsl:attribute name="document">
          <xsl:value-of select="document-uri(/)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </svrl:active-pattern>
      <xsl:apply-templates select="/" mode="M6"/>
      <svrl:active-pattern>
        <xsl:attribute name="document">
          <xsl:value-of select="document-uri(/)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </svrl:active-pattern>
      <xsl:apply-templates select="/" mode="M7"/>
      <svrl:active-pattern>
        <xsl:attribute name="document">
          <xsl:value-of select="document-uri(/)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </svrl:active-pattern>
      <xsl:apply-templates select="/" mode="M8"/>
    </svrl:schematron-output>
  </xsl:template>

  <!--SCHEMATRON PATTERNS-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Schematron VO-DML Validator</svrl:text>

  <!--PATTERN -->


	<!--RULE -->
<xsl:template match="vodml-id[not(../name() = 'vo-dml:model')]" priority="1000" mode="M4">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                     context="vodml-id[not(../name() = 'vo-dml:model')]"/>
    <xsl:variable name="count" select="count(./following::vodml-id[. = current()])"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$count = 0"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$count = 0">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
vodml-id '<xsl:text/>
            <xsl:value-of select="."/>
            <xsl:text/>' is not unique, there are <xsl:text/>
            <xsl:value-of select="$count"/>
            <xsl:text/> other elements with same vodml-id in this model.
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M4"/>
  </xsl:template>
  <xsl:template match="text()" priority="-1" mode="M4"/>
  <xsl:template match="@*|node()" priority="-2" mode="M4">
    <xsl:apply-templates select="*" mode="M4"/>
  </xsl:template>

  <!--PATTERN -->


	<!--RULE -->
<xsl:template match="objectType|dataType|enumeration|primitiveType" priority="1000" mode="M5">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                     context="objectType|dataType|enumeration|primitiveType"/>
    <xsl:variable name="count" select="count(extends)"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$count &lt; 2"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$count &lt; 2">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
            <xsl:text/>
            <xsl:value-of select="./vodml-id"/>
            <xsl:text/> has more than one extends relation.
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M5"/>
  </xsl:template>
  <xsl:template match="text()" priority="-1" mode="M5"/>
  <xsl:template match="@*|node()" priority="-2" mode="M5">
    <xsl:apply-templates select="*" mode="M5"/>
  </xsl:template>

  <!--PATTERN -->


	<!--RULE -->
<xsl:template match="composition/datatype/vodml-ref" priority="1000" mode="M6">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                     context="composition/datatype/vodml-ref"/>
    <xsl:variable name="count" select="count(//composition/datatype/vodml-ref[. = current()])"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$count = 1"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$count = 1">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
            <xsl:text/>
            <xsl:value-of select="."/>
            <xsl:text/> is used more than once, namely <xsl:text/>
            <xsl:value-of select="$count"/>
            <xsl:text/> times as target of composition relation.
 (this message will repeat itself <xsl:text/>
            <xsl:value-of select="$count"/>
            <xsl:text/> times!)
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M6"/>
  </xsl:template>
  <xsl:template match="text()" priority="-1" mode="M6"/>
  <xsl:template match="@*|node()" priority="-2" mode="M6">
    <xsl:apply-templates select="*" mode="M6"/>
  </xsl:template>

  <!--PATTERN -->


	<!--RULE -->
<xsl:template match="vodml-ref[substring-before(text(),':') != '' and substring-before(text(),':') != /vo-dml:model/vodml-id]"
                priority="1000"
                mode="M7">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                     context="vodml-ref[substring-before(text(),':') != '' and substring-before(text(),':') != /vo-dml:model/vodml-id]"/>
    <xsl:variable name="prefix" select="substring-before(text(),':')"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="/vo-dml:model/import/prefix = $prefix"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                            test="/vo-dml:model/import/prefix = $prefix">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
There is no imported model corresponding to model prefix '<xsl:text/>
            <xsl:value-of select="$prefix"/>
            <xsl:text/>' in this model.
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M7"/>
  </xsl:template>
  <xsl:template match="text()" priority="-1" mode="M7"/>
  <xsl:template match="@*|node()" priority="-2" mode="M7">
    <xsl:apply-templates select="*" mode="M7"/>
  </xsl:template>

  <!--PATTERN -->


	<!--RULE -->
<xsl:template match="objectType/attribute | dataType/attribute" priority="1006" mode="M8">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                     context="objectType/attribute | dataType/attribute"/>
    <xsl:variable name="owner" select="./vodml-id"/>
    <xsl:variable name="target" select="fct:vo-dml_element(datatype/vodml-ref,/vo-dml:model)"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$target = 'primitiveType' or $target = 'dataType' or $target='enumeration'"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                            test="$target = 'primitiveType' or $target = 'dataType' or $target='enumeration'">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
datatype <xsl:text/>
            <xsl:value-of select="datatype/vodml-ref"/>
            <xsl:text/> of <xsl:text/>
            <xsl:value-of select="$owner"/>
            <xsl:text/> is not a value type but a '<xsl:text/>
            <xsl:value-of select="$target"/>
            <xsl:text/>'
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>

	<!--RULE -->
<xsl:template match="reference" priority="1005" mode="M8">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="reference"/>
    <xsl:variable name="owner" select="./vodml-id"/>
    <xsl:variable name="target" select="fct:vo-dml_element(datatype/vodml-ref,/vo-dml:model)"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$target = 'objectType'"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$target = 'objectType'">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
datatype <xsl:text/>
            <xsl:value-of select="datatype/vodml-ref"/>
            <xsl:text/> of reference <xsl:text/>
            <xsl:value-of select="$owner"/>
            <xsl:text/> is not an object type but a '<xsl:text/>
            <xsl:value-of select="$target"/>
            <xsl:text/>'
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>

	<!--RULE -->
<xsl:template match="objectType/composition" priority="1004" mode="M8">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="objectType/composition"/>
    <xsl:variable name="owner" select="./vodml-id"/>
    <xsl:variable name="target" select="fct:vo-dml_element(datatype/vodml-ref,/vo-dml:model)"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$target = 'objectType'"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$target = 'objectType'">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
datatype <xsl:text/>
            <xsl:value-of select="datatype/vodml-ref"/>
            <xsl:text/> of composition <xsl:text/>
            <xsl:value-of select="$owner"/>
            <xsl:text/> is not an object type but a '<xsl:text/>
            <xsl:value-of select="$target"/>
            <xsl:text/>'
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>

	<!--RULE -->
<xsl:template match="objectType/extends" priority="1003" mode="M8">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="objectType/extends"/>
    <xsl:variable name="owner" select="../vodml-id"/>
    <xsl:variable name="target" select="fct:vo-dml_element(vodml-ref,/vo-dml:model)"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$target = 'objectType'"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$target = 'objectType'">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
Super type <xsl:text/>
            <xsl:value-of select="vodml-ref"/>
            <xsl:text/> of objectType <xsl:text/>
            <xsl:value-of select="$owner"/>
            <xsl:text/> is not an object type but a '<xsl:text/>
            <xsl:value-of select="$target"/>
            <xsl:text/>'
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>

	<!--RULE -->
<xsl:template match="dataType/extends" priority="1002" mode="M8">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="dataType/extends"/>
    <xsl:variable name="owner" select="./vodml-id"/>
    <xsl:variable name="target" select="fct:vo-dml_element(vodml-ref,/vo-dml:model)"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$target = 'dataType'"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$target = 'dataType'">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
Super type <xsl:text/>
            <xsl:value-of select="vodml-ref"/>
            <xsl:text/> of dataType/extends <xsl:text/>
            <xsl:value-of select="$owner"/>
            <xsl:text/> is not a data type but a '<xsl:text/>
            <xsl:value-of select="$target"/>
            <xsl:text/>'
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>

	<!--RULE -->
<xsl:template match="attribute/multiplicity" priority="1001" mode="M8">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="attribute/multiplicity"/>
    <xsl:variable name="owner" select="./../vodml-id"/>
    <xsl:variable name="minOccurs" select="./minOccurs"/>
    <xsl:variable name="maxOccurs" select="./maxOccurs"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="number($maxOccurs) &gt; 0 and ($minOccurs = '0' or $minOccurs = $maxOccurs)"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                            test="number($maxOccurs) &gt; 0 and ($minOccurs = '0' or $minOccurs = $maxOccurs)">
          <xsl:attribute name="flag">warning</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text> 
Attribute <xsl:text/>
            <xsl:value-of select="./../vodml-id"/>
            <xsl:text/> has multiplicity <xsl:text/>
            <xsl:value-of select="concat($minOccurs,'..',$maxOccurs)"/>
            <xsl:text/> which is STRONLY DISCOURAGED.
  </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>

	<!--RULE -->
<xsl:template match="constraint[@xsi:type='vo-dml:SubsettedRole']" priority="1000" mode="M8">
    <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                     context="constraint[@xsi:type='vo-dml:SubsettedRole']"/>
    <xsl:variable name="owner" select="../name()"/>
    <xsl:variable name="target" select="fct:vo-dml_element(./role/vodml-ref,/vo-dml:model)"/>

		  <!--ASSERT -->
<xsl:choose>
      <xsl:when test="$target"/>
      <xsl:otherwise>
        <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$target">
          <xsl:attribute name="flag">error</xsl:attribute>
          <xsl:attribute name="location">
            <xsl:apply-templates select="." mode="schematron-select-full-path"/>
          </xsl:attribute>
          <svrl:text>
Target of subsets constraint on '<xsl:text/>
            <xsl:value-of select="../vodml-id"/>
            <xsl:text/>' with vodml-ref <xsl:text/>
            <xsl:value-of select="./vodml-ref"/>
            <xsl:text/> can not be found
    </svrl:text>
        </svrl:failed-assert>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>
  <xsl:template match="text()" priority="-1" mode="M8"/>
  <xsl:template match="@*|node()" priority="-2" mode="M8">
    <xsl:apply-templates select="*" mode="M8"/>
  </xsl:template>
</xsl:stylesheet>