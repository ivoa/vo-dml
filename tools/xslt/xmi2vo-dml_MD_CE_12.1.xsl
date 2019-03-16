<!-- This style sheet transforms a UML model, expressed in XMI, into the basic VO-DML representation. That representation follows the schema in ./xsd/vo-dml.xsd, without the expansion fields. The document follows 
  the "basic" vo-dml representation, i.e. one directly representing the UML profile's concepts. It uses the XMI-Ids for utype. Using the generate_utypes.xsl script these can be replaced with UTYPE-s according 
  to any desired generaiton algorithm. 
  XSLT is tested to work on XMI generated with MagicDraw Community Edition v12.1. -->
<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xmi="http://schema.omg.org/spec/XMI/2.1" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:uml="http://schema.omg.org/spec/UML/2.0" 
  xmlns:IVOA_UML_Profile='http://www.magicdraw.com/schemas/IVOA_UML_Profile.xmi'
  xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1">

  <xsl:import href="common.xsl" />
  <xsl:import href="utype.xsl" />

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

  <xsl:param name="lastModified" />
  <xsl:param name="lastModifiedText" />
  <xsl:param name="lastModifiedXSDDatetime"/>


  <xsl:param name="vodmlSchemaNS" />
  <xsl:param name="vodmlSchemaLocation" />
  
  <!-- xml index on xml:id -->
  <!-- problem with match="*" is that MagicDraw creates a <proxy> for Resource (for example) when it uses a stereotype and Resource shows then up twice with the same xmi:id. -->
  <xsl:key name="classid" match="*/uml:Model//*" use="@xmi:id" />

  <xsl:variable name="xmi_namespace" select="'http://schema.omg.org/spec/XMI/2.1'" />
  <xsl:variable name="uml_namespace" select="'http://schema.omg.org/spec/UML/2.0'" />




  <!-- main -->
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="namespace-uri(/*) != 'http://schema.omg.org/spec/XMI/2.1'">
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
        <xsl:apply-templates select="xmi:XMI/uml:Model" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- filters uml:Model : process only uml:Package nodes -->
  <xsl:template match="uml:Model">
    <xsl:variable name="xmiid" select="@xmi:id" />
    <xsl:variable name="modeltags" select="/xmi:XMI/IVOA_UML_Profile:model[@base_Model = $xmiid]" />

    <xsl:element name="vo-dml:model">
      <xsl:namespace name="vo-dml" select="$vodmlSchemaNS"/>
      <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
      <xsl:attribute name="xsi:schemaLocation" select="concat($vodmlSchemaNS,' ',$vodmlSchemaLocation)" />
      <xsl:attribute name="version">
        <xsl:choose>
         <xsl:when test="$modeltags/@vodml-version">
          <xsl:value-of select="$modeltags/@vodml-version" />
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="'1.0'" />
         </xsl:otherwise>
       </xsl:choose>
      </xsl:attribute>
      <!-- 'http://www.ivoa.net/xml/VODML/v1.0 http://volute.g-vo.org/svn/trunk/projects/dm/vo-dml/xsd/vo-dml-v1.0.xsd'" -->

<!-- Note, in the MD CE 12.1 profile the name of the UML model is to be used as vodml-id, its title tag as name ! -->
      <xsl:element name="name">
        <xsl:value-of select="@name" />
      </xsl:element>
      <xsl:apply-templates select="." mode="description"/>
      <xsl:if test="$modeltags/@identifier">
        <xsl:element name="identifier">
          <xsl:value-of select="$modeltags/@identifier" />
        </xsl:element>
      </xsl:if>
      <xsl:element name="uri">
        <xsl:value-of select="$modeltags/@uri" />
      </xsl:element>
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
      <xsl:element name="lastModified">
        <xsl:value-of select="$lastModifiedXSDDatetime" />
      </xsl:element>
      <xsl:apply-templates select="./*[@xmi:type='uml:Model']" mode="modelimport"/>
      <xsl:apply-templates select="./ownedMember[@xmi:type='uml:PrimitiveType']" >
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./ownedMember[@xmi:type='uml:Enumeration']" >
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./ownedMember[@xmi:type='uml:DataType']">
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./ownedMember[@xmi:type='uml:Class']">
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./*[@xmi:type='uml:Package']" >
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <!-- 
    <xsl:element name="XMIID2VODMLID">
      <xsl:apply-templates select="//IVOA_UML_Profile:modelelement[@vodml_id]" mode="XMI-ID-Mapping"/>
    </xsl:element>
 -->
     </xsl:element>
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
       <xsl:apply-templates select="./ownedMember[@xmi:type='uml:PrimitiveType']" >
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./ownedMember[@xmi:type='uml:Enumeration']" >
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./ownedMember[@xmi:type='uml:DataType']">
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./ownedMember[@xmi:type='uml:Class']">
        <xsl:sort select="@name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="./*[@xmi:type='uml:Package']" >
        <xsl:sort select="@name"/>
      </xsl:apply-templates>         
      
<!--       <xsl:apply-templates select="./*[@xmi:type='uml:Class']" />
       <xsl:apply-templates select="./*[@xmi:type='uml:DataType']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:Enumeration']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:PrimitiveType']" />

        <xsl:apply-templates select="./*[@xmi:type='uml:Package']" />
 -->
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



  <xsl:template name="findRootId">
    <xsl:param name="xmiid"/>
    <xsl:variable name="class" select="key('classid',$xmiid)"/>
    <xsl:choose>
      <xsl:when test="$class/generalization">
        <xsl:call-template name="findRootId">
          <xsl:with-param name="xmiid" select="$class/generalization/@general"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$xmiid"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




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
      <xsl:if test="@isAbstract = 'true'">
        <xsl:attribute name="abstract">
          <xsl:text>true</xsl:text>
        </xsl:attribute>
      </xsl:if>

      <!--  ReferencableElement -->
      <xsl:apply-templates select="." mode="aselement" />
  
      <!-- Type -->
      <xsl:if test="*[@xmi:type='uml:Generalization']">
        <xsl:apply-templates select="*[@xmi:type='uml:Generalization']" />
      </xsl:if>
      <!-- ObjectType -->
      <xsl:apply-templates select="./ownedRule[@xmi:type='uml:Constraint']"  />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property']" mode="roleConstraint"/>
      
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and not(@association)]" mode="attributes" />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and @aggregation='composite']" mode="compositions" />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and (not(@aggregation) or @aggregation='shared' or @aggregation='none')]" mode="references" />

    </xsl:element>
    &cr;&cr;
  </xsl:template>

  <xsl:template match="ownedRule[@xmi:type='uml:Constraint']" >
    <xsl:element name="constraint" >
<!-- 
      <xsl:apply-templates select="." mode="aselement" /> 
 -->
      <xsl:element name="description">
        <xsl:value-of select="./specification/@body"/>
      </xsl:element>
    </xsl:element>
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
      <xsl:if test="@isAbstract = 'true'">
        <xsl:attribute name="abstract">
          <xsl:text>true</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="." mode="aselement" />

      <!-- Type -->
      <xsl:if test="*[@xmi:type='uml:Generalization']">
        <xsl:apply-templates select="*[@xmi:type='uml:Generalization']" />
      </xsl:if>
       <!-- DataType -->
      <xsl:apply-templates select="./ownedRule[@xmi:type='uml:Constraint']"  />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and not(@association)]" mode="attributes" />
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and (not(@aggregation) or @aggregation='shared' or @aggregation='none')]" mode="references" />

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




  <xsl:template match="*" mode="description">
    <xsl:variable name="ownedComment" select="./ownedComment"/>
    <xsl:element name="description">
      <xsl:choose>
        <xsl:when test="$ownedComment/@body">
      <xsl:attribute name="xmi-id" select="$ownedComment/@xmi:id"/>
          <xsl:value-of select="$ownedComment/@body" />
        </xsl:when>
        <xsl:otherwise>
      <xsl:attribute name="owner-id" select="@xmi:id"/>
          <xsl:text>TODO : Missing description : please, update your UML model asap.</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>


  <xsl:template match="*[@xmi:type='uml:Property']" mode="roleConstraint">
    <!-- TODO test that role is constrained -->
    <xsl:if test="subsettedProperty">
    <xsl:element name="constraint">
      <xsl:attribute name="xsi:type" select="'vo-dml:SubsettedRole'"/>
        <xsl:element name="role">
          <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="subsettedProperty/@xmi:idref"/>
          </xsl:call-template>
        </xsl:element>
        <xsl:if test="@type">
        <xsl:element name="datatype">
        <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="@type"/>
        </xsl:call-template>
        </xsl:element>
        </xsl:if>
        <xsl:call-template name="semanticconceptstereotype">
          <xsl:with-param name="xmiid" select="@xmi:id" />
        </xsl:call-template>
      </xsl:element>
      </xsl:if>
  </xsl:template>

  <xsl:template match="*[@xmi:type='uml:Property']" mode="attributes">
    <xsl:if test="not(subsettedProperty)">
      <xsl:element name="attribute">
        <xsl:apply-templates select="." mode="properties" />
        <xsl:call-template name="semanticconceptstereotype">
          <xsl:with-param name="xmiid" select="@xmi:id" />
        </xsl:call-template>
      </xsl:element>
    </xsl:if>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Property']" mode="references">
      <xsl:if test="not(subsettedProperty)">
    <xsl:element name="reference">
      <xsl:apply-templates select="." mode="properties" />
    </xsl:element>
      </xsl:if>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Property']" mode="compositions">
      <xsl:if test="not(subsettedProperty)">
    <xsl:variable name="xmiid" select="@xmi:id"/>
    <xsl:element name="composition">
      <xsl:apply-templates select="." mode="properties" />
      <!-- check for isOrdered -->
      <xsl:if test="/xmi:XMI/IVOA_UML_Profile:composition[@base_Property=$xmiid]/@isOrdered">
      <xsl:element name="isOrdered">
        <xsl:value-of select="/xmi:XMI/IVOA_UML_Profile:composition[@base_Property=$xmiid]/@isOrdered"/>
      </xsl:element>
      </xsl:if>
      </xsl:element>
      </xsl:if>
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


  <xsl:template name="semanticconceptstereotype">
    <xsl:param name="xmiid" />
    <xsl:variable name="attribute" select="/xmi:XMI/IVOA_UML_Profile:semanticconcept[@base_Property = $xmiid]" />
    <xsl:if test="$attribute">
      <xsl:element name="semanticconcept">
        <xsl:if test="$attribute/@topConcept">
          <xsl:element name="topConcept">
            <xsl:value-of select="$attribute/@topConcept" />
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
        <xsl:when test="not($lower)"> <!-- UML/XMI default is 0! -->
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
    <xsl:variable name="model" select="/xmi:XMI/uml:Model/ownedMember[@xmi:type='uml:Model' and .//ownedMember[@xmi:id = $xmiid]]" />

      <xsl:choose>
        <xsl:when test="$vodml-id">
          <xsl:element name="vodml-id">
            <xsl:attribute name="id" select="@xmi:id"/>
            <xsl:attribute name="vodmlid" select="$vodml-id"/>
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
      <xsl:if test="name() != 'ownedRule'">
      <xsl:apply-templates select="." mode="description"/>
      </xsl:if>
  </xsl:template>

<!-- Generate a proper vodml-ref element. Note, an element can have a declared vodml-id, even when defined in current model -->
  <xsl:template name="asElementRef">
    <xsl:param name="xmiidref"/>
    <!--  check whether referenced element has a declared vodml-id -->
    <xsl:variable name="vodml-id" select="/xmi:XMI/IVOA_UML_Profile:modelelement[@base_Element = $xmiidref]/@vodml_id" />
    <!-- check whether referenced type is in a imported model -->
    <xsl:variable name="modelimport" select="/xmi:XMI/uml:Model/ownedMember[@xmi:type='uml:Model' and .//*[@xmi:id = $xmiidref]]" />

    <xsl:if test="$modelimport and not($vodml-id)">
      <xsl:message> ERROR, vodml-ref reference <xsl:value-of select="$xmiidref"/> to element in imported model, but element has no declared vodml-id</xsl:message>
    </xsl:if>
 <!-- check whether a model prefix should be added to the declared vodml-id, this is only case if a vodml-id is declared -->
    <xsl:variable name="modelprefix">
    <xsl:if test="$modelimport">
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
<!-- add the original xmiidref as attribute to indicate that utype still must be generated-->
          <xsl:attribute name="idref" select="$xmiidref"></xsl:attribute>
          <xsl:value-of select="$xmiidref" />
        </xsl:element>
      </xsl:otherwise>
      </xsl:choose>
  </xsl:template>

  <xsl:template match="ownedMember[@xmi:type='uml:Model']" mode="modelimport">
    <xsl:variable name="xmiid" select="@xmi:id"/>
    <xsl:variable name="modelimport" select="/xmi:XMI/IVOA_UML_Profile:modelimport[@base_Element = $xmiid]" />
    <xsl:choose>
      <xsl:when test="$modelimport">
    <xsl:element name="import" >
    <!-- 
      <xsl:apply-templates select="." mode="aselement"/>
    -->
      <xsl:element name="name">
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
<!-- 
   xmi:id='_12_1_58601f2_1521666461202_172741_239' base_Element='_12_1_58601f2_1521666444607_35353_218' vodml_id='Coordinate'/>
"
 -->  
  <xsl:template match="IVOA_UML_Profile:modelelement" mode="XMI-ID-Mapping">
    <xsl:element name="TEMP-ID-Mapping">
    <xsl:attribute name="vodml_id" select="@vodml_id"/>
    <xsl:attribute name="xmi_id" select="@xmi:id"/>
    <xsl:attribute name="base_element" select="@base_Element"/>
    </xsl:element>
  </xsl:template>
  
  
</xsl:stylesheet>