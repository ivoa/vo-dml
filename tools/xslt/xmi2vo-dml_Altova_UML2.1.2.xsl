<!-- This style sheet transforms a UML model, expressed in XMI, into the basic 
     VO-DML representation. That representation follows the schema in 
     ./xsd/vo-dml.xsd, without the expansion fields. The document follows 
     the "basic" vo-dml representation, i.e. one directly representing the 
     UML profile's concepts. It uses the XMI-Ids for utype. Using the 
     generate_utypes.xsl script these can be replaced with UTYPE-s according 
     to any desired generaiton algorithm. 

     XSLT is tested to work on XMI generated with Altova UModel 2.1.2. -->
<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
  xmlns:uml="http://schema.omg.org/spec/UML/2.1.2" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
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
  <xsl:variable name="uml_namespace" select="'http://schema.omg.org/spec/UML/2.1.2'" />

 <!-- Altova seems to only allow 'Root' as model name and has no way to add stereotypes/tags-->
 <xsl:param name="model_name"/>


  <!-- ============================================================
       Template: main                                              
         Verifies compatibility of XMI flavor and begins conversion
       ============================================================ -->
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="namespace-uri(/*) != $xmi_namespace">
        <xsl:message>
          ERROR Wrong namespace: this script only converts for <xsl:value-of select='$xmi_namespace'/>
          Not <xsl:value-of select="namespace-uri(/*)"/>
        </xsl:message>
      </xsl:when>
      <xsl:when test="not(*/uml:Model)">
        <xsl:message>
          ERROR No uml:Model found. Possibly wrong version of uml namespace?
          Should be <xsl:value-of select="$uml_namespace" />
        </xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="xmi:XMI/uml:Model[@name='Root']/packagedElement[@xmi:type='uml:Model']" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       Template:                                                   
         Process uml:Model                                         
       ============================================================ -->
  <xsl:template match="packagedElement[@xmi:type='uml:Model']">
    <xsl:comment>
      This XML document is generated without explicit xmlns specification
      as it complicates writing XSLT scripts against it.
      [TBD add a link to some web dicsussion about it]
      It is understood that the XML schema in
        http://volute.g-vo.org/svn/trunk/projects/theory/snapdm/specification/uml/intermediateModel.xsd
      is to be used for validating this generated document.
    </xsl:comment>&cr;
    <xsl:element name="vo-dml:model">
      <xsl:namespace name="vo-dml" select="$vodmlSchemaNS"/>
      <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
      <xsl:attribute name="xsi:schemaLocation" select="concat($vodmlSchemaNS,' ',$vodmlSchemaLocation)" />
    
      <!-- Write model specification elements -->
      <xsl:element name="name">
        <xsl:value-of select="@name" />
      </xsl:element>
      <xsl:call-template name="description">
        <xsl:with-param name="ownedComment" select="./ownedComment" />
      </xsl:call-template>

      <xsl:apply-templates select="." mode="model.tags" />
      <xsl:element name="lastModified">
        <xsl:value-of select="$lastModifiedXSDDatetime" />
      </xsl:element>
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:Model']" mode="modelimport"/>
      <!-- seems Altova always has a 'Component View' package -->
     
          <xsl:apply-templates select="./*[@xmi:type='uml:PrimitiveType']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:Enumeration']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:DataType']" />
          <xsl:apply-templates select="./*[@xmi:type='uml:Class']" />
      <xsl:apply-templates select="./*[@xmi:type='uml:Package' and @name !='Component View']" />
 
    </xsl:element>
  </xsl:template>

  <!-- ============================================================
       Template: modelspec                                         
         Generate Model specification elements                     
       ============================================================ -->
  <xsl:template match="packagedElement[@xmi:type='uml:Model']" mode="model.tags">
    <xsl:variable name="xmiid" select="@xmi:id" />
    <xsl:variable name="ast"   select="./xmi:Extension[@extender='UModel']/appliedStereotype[@xmi:type='uml:StereotypeApplication']"/>
    <xsl:if test="$ast">

      <xsl:element name="uri">
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'model'"/>
          <xsl:with-param name="slot" select="'uri'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:element>

      <xsl:element name="title">
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'model'"/>
          <xsl:with-param name="slot" select="'title'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:element>

      <xsl:variable name="authors">
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'model'"/>
          <xsl:with-param name="slot" select="'author'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:for-each select="$authors">
        <xsl:element name="author">
          <xsl:value-of select="." />
        </xsl:element>
      </xsl:for-each>

      <xsl:variable name="version">
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'model'"/>
          <xsl:with-param name="slot" select="'version'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:element name="version">
      <xsl:choose>
      <xsl:when test="$version != ''">
        <xsl:value-of select="$version" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'0.x'" />
      </xsl:otherwise>
      </xsl:choose>
        </xsl:element>

      <xsl:variable name="previousVersion">
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'model'"/>
          <xsl:with-param name="slot" select="'previousVersion'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:if test="$previousVersion != ''">
        <xsl:element name="previousVersion">
          <xsl:value-of select="$previousVersion" />
        </xsl:element>
      </xsl:if>
    </xsl:if>
  </xsl:template>


  <!-- ============================================================
       Template:                                                   
         Process uml:Package                                       
          uml:DataType, uml:Enumeration, uml:Class nodes           
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Package']">

    <!-- check if a name is defined -->
    <xsl:if test="count(@name) > 0 and not(starts-with(@name,'_'))">
      <xsl:message>Generating package <xsl:value-of select="@name"/></xsl:message>

      &cr;&cr;
      <xsl:element name="package">
        <xsl:apply-templates select="." mode="aselement" />

        &cr;<!-- explicitly process only datatypes, enumeration, class -->
        <xsl:apply-templates select="./*[@xmi:type='uml:PrimitiveType']" />
        <xsl:apply-templates select="./*[@xmi:type='uml:Enumeration']" />
        <xsl:apply-templates select="./*[@xmi:type='uml:DataType']" />
        <xsl:apply-templates select="./*[@xmi:type='uml:Class']" />
	
        <!-- process sub-packages -->
        <xsl:apply-templates select="./*[@xmi:type='uml:Package']" />
      </xsl:element>
      &cr;&cr;
    </xsl:if>
  </xsl:template>


  <!-- ============================================================
       Template:                                                   
         Process Class objects.                                    
       ============================================================ -->
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
    <!-- Check whether this class is in a tree that has a contained class
	 to do so, find first root base class, then find for it whether 
	 any of its children is contained, if so, this class is also NOT
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

      <!-- Constraints on this element-->
      <!-- <xsl:apply-templates select="./ownedRule[@xmi:type='uml:Constraint' and not(@name='Subset')]" mode="elemConstraint" /> -->
      <xsl:apply-templates select="./ownedRule[@xmi:type='uml:Constraint' and not(contains(@name,'Subset'))]" mode="elemConstraint" />
      <!-- Subsets -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property']" mode="roleConstraint"/>
      <!-- Attributes -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and not(association) and (not(@aggregation) or @aggregation='composite')]" mode="attributes" />
      <!-- Compositions -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and association and @aggregation='composite']" mode="compositions" />
      <!-- References -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and association and (not(@aggregation) or @aggregation='shared')]" mode="references" />

    </xsl:element>
    &cr;&cr;
  </xsl:template>


  <!-- ============================================================
       Template: 
         Process PrimitiveType objects.
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:PrimitiveType']">
    <xsl:element name="primitiveType">
      <xsl:apply-templates select="." mode="aselement"/>
      <xsl:if test="*[@xmi:type='uml:Generalization']">
        <xsl:apply-templates select="*[@xmi:type='uml:Generalization']" />
      </xsl:if>
    </xsl:element>
    &cr;&cr;
  </xsl:template>


  <!-- ============================================================
       Template: 
         Process DataType objects.
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:DataType']">
    <xsl:variable name="xmiid" select="@xmi:id" />

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
      

      <!-- Constraints on this element-->
      <!-- <xsl:apply-templates select="./ownedRule[@xmi:type='uml:Constraint' and not(@name='Subset')]" mode="elemConstraint" /> -->
      <xsl:apply-templates select="./ownedRule[@xmi:type='uml:Constraint' and not(contains(@name,'Subset'))]" mode="elemConstraint" />
      <!-- Subsets     -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property']" mode="roleConstraint"/>
      <!-- Attributes -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and not(association) and (not(@aggregation) or @aggregation='composite')]" mode="attributes" />
      <!-- References -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and association and (not(@aggregation) or @aggregation='shared')]" mode="references" />

      <!-- Compositions - NOT ALLOWED -->
      <xsl:if test=".//*[@xmi:type='uml:Property' and association and @aggregation='composite']">
        <xsl:message>
          ERROR: VO-DML violation - Composition found in DataType <xsl:value-of select="@name"/>
        </xsl:message>
      </xsl:if>

    </xsl:element>
    &cr;&cr;
  </xsl:template>


  <!-- ============================================================
       Template: 
         Process Generalization Element.
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Generalization']">
    <xsl:element name="extends">
      <xsl:call-template name="asElementRef">
        <xsl:with-param name="xmiidref" select="@general"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>


  <!-- ============================================================
       Template: 
         Process Enumeration Object.
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Enumeration']">
    <xsl:element name="enumeration">
      <xsl:apply-templates select="." mode="aselement"/>
      <xsl:apply-templates select="*[@xmi:type='uml:EnumerationLiteral']" />
    </xsl:element>
    &cr;&cr;
  </xsl:template>


  <!-- ============================================================
       Template: 
         Process EnumerationLiteral Element.
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:EnumerationLiteral']">
    <xsl:element name="literal">
      <xsl:apply-templates select="." mode="aselement"/>
     </xsl:element>
  </xsl:template>


  <!-- ============================================================
       Template: 
         Process Description Element.
       ============================================================ -->
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


  <!-- ============================================================
       Template: 
         Process Attribute Element.
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Property']" mode="attributes">

    <!-- check if the property is subsetted -->
    <xsl:variable name="isSubsetted">
      <xsl:call-template name="checkSubsetted">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$isSubsetted = 'False'">
      <xsl:element name="attribute">
	<xsl:apply-templates select="." mode="properties" />
	<xsl:call-template name="attributestereotype">
          <xsl:with-param name="xmiid" select="@xmi:id" />
	</xsl:call-template>
	<xsl:call-template name="semanticconceptstereotype">
          <xsl:with-param name="xmiid" select="@xmi:id" />
	</xsl:call-template>
      </xsl:element>
    </xsl:if>

  </xsl:template>


  <!-- ============================================================
       Template: elemConstraint                                    
         Generate a 'constraint' node for a model element.         
       ============================================================ -->
  <xsl:template match="ownedRule[@xmi:type='uml:Constraint']"  mode="elemConstraint" >
    <xsl:element name="constraint" >
      <xsl:element name="description">
        <xsl:value-of select="./specification/@value"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <!-- ============================================================
       Template: roleConstraint                                    
         Generates 'constraint' node for SubsettedRole.            
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Property']" mode="roleConstraint">

    <!-- check if the property is subsetted -->
    <xsl:variable name="subsets">
      <xsl:call-template name="checkSubsets">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="string-length($subsets)!=0" >
      <xsl:element name="constraint">
	  <xsl:attribute name="xsi:type" select="'vo-dml:SubsettedRole'"/>
	  <xsl:element name="role">
            <xsl:element name="vodml-ref">
              <xsl:value-of select="$subsets"/>
	    </xsl:element>
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


  <!-- ============================================================
       Template: references                                        
         Generate a reference node for a model element.            
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Property']" mode="references">

    <!-- check if the property is subsetted -->
    <xsl:variable name="isSubsetted">
      <xsl:call-template name="checkSubsetted">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$isSubsetted='False'">
      <xsl:element name="reference">
	<xsl:apply-templates select="." mode="properties" />
      </xsl:element>
    </xsl:if>

  </xsl:template>


  <!-- ============================================================
       Template: compositions                                      
         Generate a composition node for a model element.          
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Property']" mode="compositions">
    
    <!-- check if the property is subsetted -->
    <xsl:variable name="isSubsetted">
      <xsl:call-template name="checkSubsetted">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$isSubsetted='False'">
      <xsl:element name="composition">
	<xsl:apply-templates select="." mode="properties" />
	<!-- check for isOrdered -->
	<xsl:if test="./@isOrdered = 'true'">
	  <xsl:element name="isOrdered">
            <xsl:value-of select="'true'"/>
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


  <!-- ============================================================
       Template: semanticconceptstereotype                         
         Generates 'semanticconcept' node with the contents of     
         the <<semanticconcept>> stereotype associated with        
         an element:                                               
           .topconcept    = Top concept                            
           .vocabularyURI = Vocabulary defintion                   
       ============================================================ -->
  <xsl:template name="semanticconceptstereotype">
    <xsl:param name="xmiid" />
    
    <xsl:variable name="ast"
      select="/xmi:XMI//ownedAttribute[@xmi:id = $xmiid]/xmi:Extension[@extender='UModel']/appliedStereotype[@xmi:type='uml:StereotypeApplication']"/>
    <xsl:if test="$ast" >
    <xsl:variable name="b">
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'semanticconcept'"/>
          <xsl:with-param name="slot" select="'topConcept'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:variable>
    <xsl:variable name="v">
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'semanticconcept'"/>
          <xsl:with-param name="slot" select="'vocabularyURI'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:variable>
    
    <xsl:if test="$v !='' or $b != ''">
      <xsl:element name="semanticconcept">
        <xsl:if test="$b != ''" >
          <xsl:element name="topConcept">
            <xsl:value-of select="$b" />
          </xsl:element>
        </xsl:if>
        <xsl:if test="$v != ''">
          <xsl:element name="vocabularyURI">
            <xsl:value-of select="$v" />
          </xsl:element>
        </xsl:if>
      </xsl:element>
    </xsl:if>
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
        <xsl:when test="$lower='*'">
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


  <!-- ============================================================
       Template: get-class-from-id
         resolve class type for both data types (primitive or specific) and classes
         Generates 'datatype' tag.
       ============================================================ -->
  <xsl:template name="get-class-from-id">
    <xsl:param name="id" />
    <xsl:element name="datatype">
    <xsl:call-template name="asElementRef">
    <xsl:with-param name="xmiidref" select="$id" />
    </xsl:call-template>
    </xsl:element>
  </xsl:template>


  <!-- ============================================================
       Template: get-package-from-id
         gets name of package with provided id.
       ============================================================ -->
  <xsl:template name="get-package-from-id">
    <xsl:param name="id" />
    <xsl:variable name="p" select="key('classid',$id)" />
    <xsl:value-of select="$p/@name" />
  </xsl:template>


  <!-- ============================================================
       Template: full-path                                         
         print the full path up to the specified package and       
         append the specified suffix                               
       ============================================================ -->
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


  <!-- ============================================================
       Template: checkSubsetted                                    
         Check if a Property is subsetted                          
       ============================================================ -->
  <xsl:template name="checkSubsetted">
    <xsl:param name="xmiid"/>

    <!-- find constraint with associated with this ID -->
    <!-- <xsl:variable name="constrained" select="/xmi:XMI//ownedRule[@xmi:type='uml:Constraint' and @name='Subset']/constrainedElement[@xmi:idref=$xmiid]" /> -->
    <xsl:variable name="constrained" select="/xmi:XMI//ownedRule[@xmi:type='uml:Constraint' and contains(@name,'Subset')]/constrainedElement[@xmi:idref=$xmiid]" />
    <xsl:choose>
      <xsl:when test="$constrained">
	<xsl:value-of select="'True'" />
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="'False'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ============================================================
       Template: checkSubsets                                      
         Check if a Property is subsetted                          
         Returns the subsetted property vodml-id                   
       ============================================================ -->
  <xsl:template name="checkSubsets">
    <xsl:param name="xmiid"/>

    <!-- find constraint associated with this ID -->
    <xsl:variable name="constraint" select="/xmi:XMI//ownedRule[@xmi:type='uml:Constraint' and contains(@name,'Subset') and ./constrainedElement[@xmi:idref=$xmiid]]" />
    <xsl:choose>
      <xsl:when test="$constraint">
	<xsl:call-template name="split_subset_string">
          <xsl:with-param name="input" select="$constraint/specification/@value"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="''" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ===== tempates treating match as a ReferencableElement ==== -->


  <!-- ============================================================
       Template: aselement                                         
         Generates 'vodml-id' tag.                                 
       ============================================================ -->
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


  <!-- ============================================================
       Template: asElementRef
         Generate a proper utype element. Note, an element can have
         a declared vodml-id, even when defined in current model
       ============================================================ -->
  <xsl:template name="asElementRef">
    <xsl:param name="xmiidref"/>
    <xsl:if test="not($xmiidref)">
    <xsl:message>asElementRef MUST be called with a non-null xmiidref</xsl:message>
    </xsl:if>

    <!--  check whether referenced element has a declared vodml-id -->
    <xsl:variable name="modelimport" select="/xmi:XMI/uml:Model[@name='Root']/packagedElement[@xmi:type='uml:Model']/packagedElement[@xmi:type='uml:Model' and .//*[@xmi:id = $xmiidref]]" />

    <xsl:variable name="ast"
      select="/xmi:XMI//packagedElement[@xmi:id = $xmiidref]/xmi:Extension[@extender='UModel']/appliedStereotype[@xmi:type='uml:StereotypeApplication']"/>
    <xsl:variable name="vodml-id">
    <xsl:choose>
      <xsl:when test="$ast" >
        <xsl:call-template name="slotvalue">
          <xsl:with-param name="stereotype" select="'modelelement'"/>
          <xsl:with-param name="slot" select="'vodml-id'"/>
          <xsl:with-param name="ast" select="$ast"/>
        </xsl:call-template>
      </xsl:when>    
    </xsl:choose>
    </xsl:variable>

    <xsl:variable name="vodmlref">
      <xsl:choose>
	<xsl:when test="$modelimport">
	  <xsl:value-of select="concat($modelimport/@name,':',$vodml-id)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="$xmiidref"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- check whether a model prefix should be added to the declared vodml-id, this is only case if a vodml-id is declared -->
    <xsl:choose>
      <xsl:when test="$modelimport">
      <xsl:element name="vodml-ref">
        <xsl:value-of select="$vodmlref"/>
      </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="vodml-ref">
	  <!-- add the original xmiidref as attribute to indicate that the
	       id still must be generated-->
          <xsl:attribute name="idref" select="$xmiidref"></xsl:attribute>
          <xsl:value-of select="$xmiidref" />
        </xsl:element>
      </xsl:otherwise>
      </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       Template: modelimport
         Generate 'import' tag for imported model, identified by
         an associated modelimport stereotype.
       ============================================================ -->
  <xsl:template match="packagedElement[@xmi:type='uml:Model']" mode="modelimport">
    <xsl:variable name="xmiid" select="@xmi:id"/>
    <xsl:variable name="ast" select="./xmi:Extension[@extender='UModel']/appliedStereotype[@xmi:type='uml:StereotypeApplication']"/>
    <xsl:choose>
      <xsl:when test="$ast">
	<xsl:element name="import">
	  <xsl:element name="name"><xsl:value-of select="@name"/></xsl:element>
        
	  <xsl:element name="url">
            <xsl:call-template name="slotvalue">
              <xsl:with-param name="stereotype" select="'modelimport'"/>
              <xsl:with-param name="slot" select="'url'"/>
              <xsl:with-param name="ast" select="$ast"/>
            </xsl:call-template>
	  </xsl:element>
	  <xsl:variable name="ivoId ">
            <xsl:call-template name="slotvalue">
              <xsl:with-param name="stereotype" select="'modelimport'"/>
              <xsl:with-param name="slot" select="'ivoId'"/>
              <xsl:with-param name="ast" select="$ast"/>
            </xsl:call-template>
	  </xsl:variable>
	  <xsl:if test="$ivoId != ''">
	    <xsl:element name="ivoId"><xsl:value-of select="$ivoId"/>
	    </xsl:element>
	  </xsl:if>
	  <xsl:element name="documentationURL">
            <xsl:call-template name="slotvalue">
              <xsl:with-param name="stereotype" select="'modelimport'"/>
              <xsl:with-param name="slot" select="'documentationURL'"/>
              <xsl:with-param name="ast" select="$ast"/>
            </xsl:call-template>
	  </xsl:element>
	</xsl:element>      
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>Model found inside of root model, but no corresponding modelimport stereotype is used.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       Template: stereotype                                        
       ============================================================ -->
  <xsl:template name="stereotype">
    <xsl:param name="name"/>
    <xsl:value-of
       select="*/packagedElement[@xmi:type='uml:Profile' and @name='IVOA_UML_Profile']/packagedElement[@xmi:type='uml:Stereotype' and name=$name]"/>
  </xsl:template>
  
  <xsl:template match="*" mode="appliedstereotype" >
    <xsl:param name="name"/>
    <xsl:variable name="stid"
		  select="//packagedElement[@xmi:type='uml:Profile' and @name='IVOA_UML_Profile']/packagedElement[@xmi:type='uml:Stereotype' and @name=$name]/@xmi:id"/> 
    <xsl:if test="./xmi:Extension[@extender='UModel']/appliedStereotype[@xmi:type='uml:StereotypeApplication' and @classifier=$stid]">
      <xsl:value-of select="./xmi:Extension[@extender='UModel']/appliedStereotype[@xmi:type='uml:StereotypeApplication' and @classifier=$stid]/@xmi:id"/>
    </xsl:if>
  </xsl:template>

  <!-- ============================================================
       Template: split_subset_string                               
       ============================================================ -->
  <xsl:template match="text()" name="split_subset_string">
    <xsl:param name="input"/>
    <xsl:param name="delimeter" select="'\s'"/>
    <xsl:variable name="parts" select="tokenize($input,$delimeter)"/>

    <xsl:value-of select="$parts[2]"/>
  </xsl:template>
  

  <!-- ============================================================
       Template: slotvalue                                         
         Matches stereotype slot with the corresponding attribute  
       ============================================================ -->
  <xsl:template name="slotvalue" >
    <xsl:param name="slot"/>
    <xsl:param name="stereotype"/>
    <xsl:param name="ast"/>
    <xsl:variable name="slotid"
		  select="//packagedElement[@xmi:type='uml:Profile' and @name='IVOA_UML_Profile']/packagedElement[@xmi:type='uml:Stereotype' and @name=$stereotype]/ownedAttribute[@name=$slot]/@xmi:id"/>
    <xsl:if test="$ast/slot[@definingFeature=$slotid]">
      <xsl:value-of select="$ast/slot[@definingFeature=$slotid]/value/@value"/>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>
