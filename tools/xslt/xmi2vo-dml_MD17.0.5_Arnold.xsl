<!-- This style sheet transforms a UML model, expressed in XMI, into the basic VO-DML representation. That representation follows the schema in ./xsd/vo-dml.xsd, without the expansion fields. The document follows 
  the "basic" vo-dml representation, i.e. one directly representing the UML profile's concepts. It uses the XMI-Ids for utype. Using the generate_utypes.xsl script these can be replaced with UTYPE-s according 
  to any desired generaiton algorithm. 
  XSLT is tested to work on XMI generated with MagicDraw Community Edition v12.1. -->
<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:xmi="http://www.omg.org/spec/XMI/20110701"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:uml="http://www.omg.org/spec/UML/20110701" 
  xmlns:IVOA_UML_Profile='http://www.magicdraw.com/schemas/IVOA_UML_Profile.xmi'
  xmlns:vo-dml="http://volute.googlecode.com/dm/vo-dml/v0.9">

  <xsl:import href="common.xsl" />
  <xsl:import href="utype.xsl" />

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

  <xsl:param name="lastModified" />
  <xsl:param name="lastModifiedText" />
  <xsl:param name="lastModifiedXSDDatetime"/>
  
  <!-- xml index on xml:id -->
  <!-- problem with match="*" is that MagicDraw creates a <proxy> for Resource (for example) when it uses a stereotype and Resource shows then up twice with the same xmi:id. -->
  <xsl:key name="classid" match="*/uml:Model//*" use="@xmi:id" />

  <xsl:variable name="xmi_namespace" select="'http://schema.omg.org/spec/XMI/2.1'" />
  <xsl:variable name="uml_namespace" select="'http://schema.omg.org/spec/UML/2.0'" />



  <!-- main -->
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="namespace-uri(/*) != 'http://www.omg.org/spec/XMI/20110701'">
        <xsl:message>
          ERROR Wrong namespace: this script can convert only XMI v2.1
        </xsl:message>
      </xsl:when>
      <xsl:when test="not(*/uml:Model)">
        <xsl:message>
          ERROR No uml:Model found. Possibly wrong version of uml namespace?
          Should be
          <xsl:value-of select="$uml_namespace" />
        </xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="xmi:XMI/uml:Model/packagedElement[@xmi:type='uml:Model']" mode="model"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- filters uml:Model : process only uml:Package nodes -->
  <xsl:template match="packagedElement" mode="model">
    <xsl:comment>
      This XML document is generated without explicit xmlns specification
      as it complicates
      writing XSLT scripts against it [TBD add a link to some web dicsussions
      about it].
      It is understood that the XML
      schema in
      http://volute.googlecode.com/svn/trunk/projects/theory/snapdm/specification/uml/intermediateModel.xsd
      is to be used for validating this generated document.
    </xsl:comment>&cr;
    <xsl:element name="vo-dml:model">
    <xsl:namespace name="vo-dml">http://volute.googlecode.com/dm/vo-dml/v0.9</xsl:namespace>
    
<!-- 
      <xsl:attribute name="id"><xsl:value-of select="@xmi:id"></xsl:value-of></xsl:attribute>
 -->
      <xsl:element name="vodml-id">
        <xsl:value-of select="@name" />
      </xsl:element>
      <xsl:element name="name">
        <xsl:value-of select="@name" />
      </xsl:element>
      <xsl:call-template name="description">
        <xsl:with-param name="ownedComment" select="./ownedComment" />
      </xsl:call-template>

      <xsl:apply-templates select="." mode="model.tags" />

      
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:Class']"/>
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:DataType']"/>
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:Enumeration']" />
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:PrimitiveType']" />
      <!-- seems Altova always has a 'Component View' package -->
      <xsl:apply-templates select="./*[@xmi:type='uml:Package' and @name !='Component View']" />
      <xsl:element name="lastModified">
        <xsl:value-of select="$lastModifiedXSDDatetime" />
      </xsl:element>
      <xsl:apply-templates select="./*[@xmi:type='uml:Model']" mode="modelimport"/>
    </xsl:element>
  </xsl:template>

<!-- +++++++++++++++++++++++++
      add the model element attributes from the model stereotype
     +++++++++++++++++++++++++ -->
  <xsl:template match="packagedElement[@xmi:type='uml:Model']" mode="model.tags">
    <xsl:variable name="xmiid" select="@xmi:id" />

    <xsl:variable name="modeltags" select="/xmi:XMI/IVOA_UML_Profile:model[@base_Model = $xmiid]" />

    <xsl:if test="$modeltags">
      <xsl:element name="title">
        <xsl:value-of select="$modeltags/@title" />
      </xsl:element>
      <xsl:for-each select="$modeltags/author">
        <xsl:element name="author">
          <xsl:value-of select="." />
        </xsl:element>
      </xsl:for-each>
        <xsl:element name="version">
      <xsl:choose>
      <xsl:when test="$modeltags/@version">
        <xsl:value-of select="$modeltags/@version" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'0.x'" />
      </xsl:otherwise>
      </xsl:choose>
        </xsl:element>
      <xsl:if test="$modeltags/previousVersion">
        <xsl:element name="previousVersion">
          <xsl:value-of select="$modeltags/previousVersion" />
        </xsl:element>
      </xsl:if>
    </xsl:if>

  </xsl:template>



  <!-- filters uml:Package : process uml:DataType, uml:Enumeration, uml:Class nodes -->
  <xsl:template match="*[@xmi:type='uml:Package']">

    <!-- check if a name is defined -->
    <xsl:if test="count(@name) > 0 and not(starts-with(@name,'_'))">
      <!-- explicitly process only datatypes, enumeration, class -->
      &cr;&cr;
      <xsl:element name="package">
<!-- 
        <xsl:attribute name="id"><xsl:value-of select="@xmi:id"></xsl:value-of></xsl:attribute>
-->
        <xsl:apply-templates select="." mode="aselement" />
<!-- 
      <xsl:element name="name">
        <xsl:value-of select="name" />
      </xsl:element>
      <xsl:call-template name="description">
        <xsl:with-param name="ownedComment" select="./ownedComment" />
      </xsl:call-template>
 -->
     &cr;
<!-- 
        <xsl:if test="count(./*[@xmi:type='uml:Dependency']) > 0">
          &cr;
          <xsl:comment>
            Dependencies
          </xsl:comment>&cr;&cr;
          <xsl:apply-templates select="./*[@xmi:type='uml:Dependency']" />
        </xsl:if>
 -->
          <xsl:apply-templates select="./*[@xmi:type='uml:Class']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:DataType']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:Enumeration']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:PrimitiveType']" />

        <xsl:apply-templates select="./*[@xmi:type='uml:Package']" />

      </xsl:element>
      &cr;&cr;
    </xsl:if>
  </xsl:template>



<!-- 
  <xsl:template match="*[@xmi:type='uml:Dependency']">
    <xsl:element name="depends">
    <xsl:call-template name="asElementRef">
    <xsl:with-param name="xmiidref" select="supplier/@xmi:idref" />
    </xsl:call-template>
    </xsl:element>
  </xsl:template>
 -->



  <xsl:template match="*[@xmi:type='uml:Class']">
    <xsl:variable name="xmiid" select="@xmi:id" />

    <!-- Check whether this class is in a tree that has a contained class to do so, find first root base class, then find for it whether anay of its children is contained, if so, this class is also NOT 
      a root element -->
    <xsl:variable name="rootid">
      <xsl:call-template name="findRootId">
        <xsl:with-param name="xmiid" select="$xmiid" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="isContained">
      <xsl:apply-templates select="key('classid',$rootid)" mode="testrootelements">
        <xsl:with-param name="count" select="'0'" />
      </xsl:apply-templates>
    </xsl:variable>



    <xsl:element name="objectType">
      <xsl:if test="@isAbstract">
        <xsl:attribute name="abstract">
          <xsl:text>true</xsl:text>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates select="." mode="aselement" />

      <xsl:if test="*[@xmi:type='uml:Generalization']">
        <xsl:apply-templates select="*[@xmi:type='uml:Generalization']" />
      </xsl:if>

      <!-- define "referrers" in post-processing of vo-dml.xml -->
      <!-- <xsl:for-each select="//packagedElement/ownedAttribute[@xmi:type='uml:Property' and @association and (not(@aggregation) or @aggregation='shared') and @type = $xmiid]"> <xsl:variable name="idref" 
        select="../@xmi:id" /> <xsl:variable name="relation" select="@name" /> <xsl:element name="referrer"> <xsl:attribute name="name" select="key('classid',$idref)/@name" /> <xsl:attribute name="xmiidref" select="$idref" 
        /> <xsl:attribute name="relation" select="$relation" /> </xsl:element> </xsl:for-each> -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and not(@association) and not(@aggregation) ]" mode="attributes" />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and @aggregation='composite']" mode="collections" />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and (not(@aggregation) or @aggregation='shared')]" mode="references" />

    </xsl:element>
    &cr;&cr;
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:PrimitiveType']">
    <xsl:element name="primitiveType">
      <xsl:apply-templates select="." mode="aselement"/>
      <xsl:if test="*[@xmi:type='uml:Generalization']">
        <xsl:apply-templates select="*[@xmi:type='uml:Generalization']" />
      </xsl:if>
    </xsl:element>
    &cr;&cr;
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:DataType']">
    <xsl:element name="dataType">
      <xsl:if test="@isAbstract">
        <xsl:attribute name="abstract">
          <xsl:text>true</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="." mode="aselement" />

      <xsl:if test="*[@xmi:type='uml:Generalization']">
        <xsl:apply-templates select="*[@xmi:type='uml:Generalization']" />
      </xsl:if>
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and not(@association)]" mode="attributes" />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and (not(@aggregation) or @aggregation='shared')]" mode="references" />

    </xsl:element>
    &cr;&cr;
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Generalization']">
    <xsl:element name="extends">
      <xsl:call-template name="asElementRef">
        <xsl:with-param name="xmiidref" select="@general"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Enumeration']">
    <xsl:element name="enumeration">
      <xsl:apply-templates select="." mode="aselement"/>
      <xsl:apply-templates select="*[@xmi:type='uml:EnumerationLiteral']" />
    </xsl:element>
    &cr;&cr;
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:EnumerationLiteral']">
    <xsl:element name="literal">
      <xsl:apply-templates select="." mode="aselement"/>
<!-- 
      <xsl:element name="value" >
        <xsl:value-of select="@name" />
      </xsl:element>
 -->
     </xsl:element>
  </xsl:template>




  <xsl:template name="description">
    <xsl:param name="ownedComment" />
    <xsl:element name="description">
      <xsl:choose>
        <xsl:when test="$ownedComment/@body">
          <xsl:value-of select="$ownedComment/@body" />
        </xsl:when>
        <xsl:otherwise>
          TODO : Missing description : please, update your UML model asap.
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Property']" mode="attributes">
    <xsl:element name="attribute">
      <xsl:apply-templates select="." mode="properties" />
      <xsl:if test="subsettedProperty">
        <xsl:message >finding subsets for <xsl:value-of select="@name"/></xsl:message>
        <xsl:element name="subsets">
          <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="subsettedProperty/@xmi:idref"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
      
      <xsl:call-template name="attributestereotype">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
      <xsl:call-template name="skosconceptstereotype">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:element>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Property']" mode="references">
    <xsl:element name="reference">
      <xsl:apply-templates select="." mode="properties" />
      <xsl:if test="subsettedProperty">
        <xsl:element name="subsets">
          <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="subsettedProperty/@xmi:idref"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Property']" mode="collections">
    <xsl:variable name="xmiid" select="@xmi:id"/>
    <xsl:element name="collection">
      <xsl:apply-templates select="." mode="properties" />
      <xsl:if test="subsettedProperty">
        <xsl:element name="subsets">
          <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="subsettedProperty/@xmi:idref"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
      <!-- check for isOrdered -->
      <xsl:if test="/xmi:XMI/IVOA_UML_Profile:composition[@base_Property=$xmiid]/@isOrdered">
      <xsl:element name="isOrdered">
        <xsl:value-of select="/xmi:XMI/IVOA_UML_Profile:composition[@base_Property=$xmiid]/@isOrdered"/>
      </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Property']" mode="properties">
    <xsl:apply-templates select="." mode="aselement"/>
    <xsl:variable name="id" select="key('classid',@type)" />
    <xsl:choose>
    <xsl:when test="@type">
      <xsl:call-template name="get-class-from-id">
      <xsl:with-param name="id" select="@type" />
    </xsl:call-template>
    </xsl:when>
      <xsl:otherwise>
      <xsl:message>NO type assigned to Property '<xsl:value-of select="../@name"/>::<xsl:value-of select="@name"/>'</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
      <xsl:element name="multiplicity">
      <xsl:call-template name="multiplicity">
        <xsl:with-param name="lower" select="lowerValue/@value" />
        <xsl:with-param name="upper" select="upperValue/@value" />
      </xsl:call-template>
    </xsl:element>
  </xsl:template>



  <xsl:template name="attributestereotype">
    <xsl:param name="xmiid" />
    <xsl:variable name="attribute" select="/xmi:XMI/IVOA_UML_Profile:attribute[@base_Property = $xmiid]" />
    <xsl:if test="$attribute">
      <xsl:element name="constraints">
        <xsl:if test="$attribute/@maxLength">
          <xsl:element name="maxLength">
            <xsl:value-of select="$attribute/@maxLength" />
          </xsl:element>
        </xsl:if>
        <xsl:if test="$attribute/@length">
          <xsl:element name="length">
            <xsl:value-of select="$attribute/@length" />
          </xsl:element>
        </xsl:if>
        <xsl:if test="$attribute[@uniqueGlobally = 'true']">
          <xsl:element name="uniqueGlobally">
            true
          </xsl:element>
        </xsl:if>
        <xsl:if test="$attribute[@uniqueInCollection = 'true']">
          <xsl:element name="uniqueInCollection">
            true
          </xsl:element>
        </xsl:if>
      </xsl:element>
    </xsl:if>
  </xsl:template>




  <xsl:template name="skosconceptstereotype">
    <xsl:param name="xmiid" />
    <xsl:variable name="attribute" select="/xmi:XMI/IVOA_UML_Profile:skosconcept[@base_Property = $xmiid]" />
    <xsl:if test="$attribute">
      <xsl:element name="skosconcept">
        <xsl:if test="$attribute/@broadestSKOSConcept">
          <xsl:element name="broadestSKOSConcept">
            <xsl:value-of select="$attribute/@broadestSKOSConcept" />
          </xsl:element>
        </xsl:if>
        <xsl:if test="$attribute/@vocabularyURI">
          <xsl:element name="vocabularyURI">
            <xsl:value-of select="$attribute/@vocabularyURI" />
          </xsl:element>
        </xsl:if>
        <xsl:for-each select="$attribute/vocabularyURI">
          <xsl:element name="vocabularyURI">
            <xsl:value-of select="." />
          </xsl:element>
        </xsl:for-each>
      </xsl:element>
    </xsl:if>
  </xsl:template>






  <!-- only legal values: 0..1 1 0..* 1..* If no multiplicity is defined (no upper and no lower): 0..1 -->

  <xsl:template name="multiplicity">
    <xsl:param name="lower" />
    <xsl:param name="upper" />
    <xsl:element name="minOccurs">
      <xsl:choose>
        <xsl:when test="not($lower) or $lower='*'"> <!-- UML/XMI default is 0! -->
          <xsl:value-of select="'0'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$lower" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
    <xsl:element name="maxOccurs">
      <xsl:choose>
        <xsl:when test="not($upper)">
          <xsl:value-of select="'1'" />
        </xsl:when>
        <xsl:when test="$upper='*'">
          <xsl:value-of select="'-1'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$upper" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>




  <!-- resolve class type for both data types (primitive or specific) and classes -->
  <xsl:template name="get-class-from-id">
    <xsl:param name="id" />
<!-- 
    <xsl:variable name="c" select="key('classid',$id)" />
 -->
    <xsl:element name="datatype">
    <xsl:call-template name="asElementRef">
    <xsl:with-param name="xmiidref" select="$id" />
    </xsl:call-template>
    </xsl:element>
  </xsl:template>




  <xsl:template name="get-package-from-id">
    <xsl:param name="id" />
    <xsl:variable name="p" select="key('classid',$id)" />
    <xsl:value-of select="$p/@name" />
  </xsl:template>


  <!-- ==================================================================================== -->
  <!-- print the full path up to the specified package and append the specified suffix -->
  <!-- ==================================================================================== -->
  <xsl:template name="full-path">
    <xsl:param name="id" />
    <xsl:param name="delimiter" />
    <xsl:param name="suffix" />

    <xsl:variable name="package" select="key('classid',$id)" />
    <xsl:variable name="path">
      <xsl:choose>
        <xsl:when test="$suffix">
          <xsl:value-of select="concat($package/@name,$delimiter,$suffix)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$package/@name" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- determine whether parent is a Package or not, if not, this is the root package which should be ignored. -->
    <xsl:variable name="parent" select="$package/..[@xmi:type='uml:Package']" />

    <xsl:choose>
      <xsl:when test="not($parent)">
        <xsl:value-of select="$path" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="full-path">
          <xsl:with-param name="id" select="$parent/@xmi:id" />
          <xsl:with-param name="delimiter" select="$delimiter" />
          <xsl:with-param name="suffix" select="$path" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <!-- ===== tempates treating match as a ReferencableElement ==== -->
  <xsl:template match="*[@xmi:id]" mode="aselement">
    <xsl:variable name="xmiid" select="@xmi:id"/>
    <xsl:variable name="vodml-id" select="/xmi:XMI/IVOA_UML_Profile:modelelement[@base_Element = $xmiid]/@vodml_id" />
    <xsl:variable name="model" select="/xmi:XMI/uml:Model/packagedElement[@xmi:type='uml:Model' and .//packagedElement[@xmi:id = $xmiid]]" />

      <xsl:choose>
        <xsl:when test="$vodml-id">
          <xsl:element name="vodml-id">
            <xsl:value-of select="$vodml-id" />
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="vodml-id">
            <xsl:attribute name="id" select="@xmi:id"/>
            <xsl:value-of select="$xmiid"/>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:element name="name">
        <xsl:value-of select="@name" />
      </xsl:element>
      <xsl:call-template name="description">
        <xsl:with-param name="ownedComment" select="./ownedComment" />
      </xsl:call-template>
  </xsl:template>

<!-- Generate a proper utype element. Note, an element can have a declared vodml-id, even when defined in current model -->
  <xsl:template name="asElementRef">
    <xsl:param name="xmiidref"/>
    <!--  check whether referenced element has a declared vodml-id -->
    <xsl:variable name="vodml-id" select="/xmi:XMI/IVOA_UML_Profile:modelelement[@base_Element = $xmiidref]/@vodml_id" />
<xsl:message>vodml-id for idref =  <xsl:value-of select="$xmiidref"/>  = <xsl:value-of select="$vodml-id"/></xsl:message>         
    <!-- check whether referenced type is in a imported model -->
    <xsl:variable name="modelimport" select="/xmi:XMI/uml:Model/packagedElement[@xmi:type='uml:Model' and .//*[@xmi:id = $xmiidref]]" />
<xsl:message>model import =  <xsl:value-of select="$modelimport/@name"/> </xsl:message>         

    <xsl:if test="$modelimport and not($vodml-id)">
      <xsl:message> ERROR, utype reference <xsl:value-of select="$xmiidref"/> to element in imported model, but element has no declared vodml-id</xsl:message>
    </xsl:if>
 <!-- check whether a model prefix should be added to the declared vodml-id, this is only case if a vodml-id is declared -->
    <xsl:variable name="modelprefix">
    <xsl:if test="$vodml-id">
      <xsl:choose>
        <xsl:when test="$modelimport">
          <xsl:value-of select="$modelimport/@name"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of  select="/xmi:XMI/uml:Model/@name" />
        </xsl:otherwise>
      </xsl:choose>
      </xsl:if>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$vodml-id">
      <xsl:element name="vodml-ref">
        <xsl:value-of select="concat($modelprefix,':',$vodml-id)"/>
      </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="vodml-ref">
<!-- add the original xmiidref as attribute to indicate that vodml-id still must be generated-->
          <xsl:attribute name="idref" select="$xmiidref"></xsl:attribute>
          <xsl:value-of select="$xmiidref" />
        </xsl:element>
      </xsl:otherwise>
      </xsl:choose>
  </xsl:template>

  <xsl:template match="packagedElement[@xmi:type='uml:Model']" mode="modelimport">
    <xsl:variable name="xmiid" select="@xmi:id"/>
    <xsl:variable name="modelimport" select="/xmi:XMI/IVOA_UML_Profile:modelimport[@base_Element = $xmiid]" />
    <xsl:choose>
      <xsl:when test="$modelimport">
    <xsl:element  name="import">
    <!-- 
      <xsl:apply-templates select="." mode="aselement"/>
    -->
      <xsl:element name="prefix">
        <xsl:value-of select="@name"/>
      </xsl:element>
      <xsl:if test="$modelimport/@ivoId">
      <xsl:element name="ivoId"><xsl:value-of select="$modelimport/@ivoId"/>
      </xsl:element>
      </xsl:if>
      <xsl:element name="url"><xsl:value-of select="$modelimport/@url"/></xsl:element>
      <xsl:element name="documentationURL"><xsl:value-of select="$modelimport/@documentationURL"/></xsl:element>
    </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message>Model found inside of root model, but no corresponding modelimport stereotype is used.</xsl:message>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
</xsl:stylesheet>