<!-- This style sheet transforms a UML model, expressed in XMI, into the basic  
     VO-DML representation. That representation follows the schema in 
     ./xsd/vo-dml.xsd, without the expansion fields. The document follows 
     the "basic" vo-dml representation, i.e. one directly representing the 
     UML profile's concepts. It uses the XMI-Ids for utype. Using the 
     generate_utypes.xsl script these can be replaced with UTYPE-s according 
     to any desired generaiton algorithm. 
     
     XSLT is tested to work on XMI generated with Modelio v3.0 -->
<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:uml="http://www.omg.org/spec/UML/20100901" 
  xmlns:IVOA_UML_Profile="http:///schemas/IVOA_UML_Profile/_XgC-YAfeEeahgduW7MgheA/0"
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
  <xsl:variable name="uml_namespace" select="'http://www.omg.org/spec/UML/20100901'" />

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
      <xsl:when test="not(/xmi:XMI/uml:Model)">
        <xsl:message>
          ERROR No uml:Model found. Possibly wrong version of uml namespace?
          Should be <xsl:value-of select="$uml_namespace" />
        </xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/xmi:XMI/uml:Model" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       Template:                                                   
         Process uml:Model                                         
       ============================================================ -->
  <xsl:template match="uml:Model">
    <xsl:comment>
      This XML document is generated without explicit xmlns specification
      as it complicates writing XSLT scripts against it.
      [TBD add a link to some web dicsussions about it]
      It is understood that the XML schema in
      http://volute.googlecode.com/svn/trunk/projects/theory/snapdm/specification/uml/intermediateModel.xsd
      is to be used for validating this generated document.
    </xsl:comment>&cr;
    <xsl:element name="vo-dml:model">
      <xsl:namespace name="vo-dml" select="$vodmlSchemaNS"/>
      <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
      <xsl:attribute name="xsi:schemaLocation" select="concat($vodmlSchemaNS,' ',$vodmlSchemaLocation)" />

      <!-- Write model specification elements -->
      <xsl:apply-templates select="." mode="modelspec" />

      <!-- Write imported model package specs -->
      <xsl:apply-templates select="./*[@xmi:type='uml:Package']" mode="modelimport"/>

      <!-- Write model elements by Type -->
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:PrimitiveType']" />
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:Enumeration']" />
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:DataType']"/>
      <xsl:apply-templates select="./packagedElement[@xmi:type='uml:Class']"/>

      <!-- Process local model packages -->
      <xsl:apply-templates select="./*[@xmi:type='uml:Package']"/>

    </xsl:element>
  </xsl:template>


  <!-- ============================================================
       Template: modelspec                                         
         Generate Model specification elements                     
       ============================================================ -->
  <xsl:template match="uml:Model" mode="modelspec">
    <xsl:variable name="xmiid" select="@xmi:id" />
    <xsl:variable name="modeltags" select="/xmi:XMI/*[local-name()='model' and @base_Package = $xmiid]" />

    <xsl:element name="name">
      <xsl:value-of select="@name" />
    </xsl:element>

    <xsl:apply-templates select="." mode="description"/>

    <xsl:element name="uri">
      <xsl:value-of select="$modeltags/@uri" />
    </xsl:element>

    <xsl:element name="title">
      <xsl:value-of select="$modeltags/@title" />
    </xsl:element>

    <xsl:if test="$modeltags/@authors">
      <xsl:element name="author">
        <xsl:value-of select="$modeltags/@authors" />
      </xsl:element>
    </xsl:if>

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

    <xsl:if test="$modeltags/@previousVersion">
      <xsl:element name="previousVersion">
        <xsl:value-of select="$modeltags/@previousVersion" />
      </xsl:element>
    </xsl:if>

    <xsl:element name="lastModified">
      <xsl:value-of select="$lastModifiedXSDDatetime" />
    </xsl:element>

  </xsl:template>


  <!-- ============================================================
       Template:                                                   
         Process uml:Package                                       
          uml:DataType, uml:Enumeration, uml:Class nodes           
       ============================================================ -->
  <xsl:template match="*[@xmi:type='uml:Package']">
    <xsl:variable name="xmiid" select="@xmi:id"/>

    <!-- test that the Package is not a modelimport -->
    <xsl:choose>
      <xsl:when test="not(/xmi:XMI/*[local-name()='modelimport' and @base_Package = $xmiid])">
        <xsl:message>found no modelimport for package <xsl:value-of select="@name"/></xsl:message>

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
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>found modelimport for package <xsl:value-of select="@name"/>, not creating Package</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       Template:                                                   
         Process Class objects.                                    
       ============================================================ -->
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

      <!-- Constraints - Modelio stores these at the Model level -->
      <xsl:apply-templates select="/xmi:XMI/uml:Model/ownedRule[@xmi:type='uml:Constraint' and @constrainedElement=$xmiid]" mode="elemConstraint"  />
      <!-- Subsets -->
      <!-- <xsl:apply-templates select=".//*[@xmi:type='uml:Property']" mode="roleConstraint"/> -->
      <xsl:apply-templates select="/xmi:XMI/uml:Model/ownedRule[@xmi:type='uml:Constraint' and @constrainedElement=$xmiid]" mode="roleConstraint"  />
      <!-- Attributes -->
      <xsl:apply-templates select="ownedAttribute[@xmi:type='uml:Property' and not(@association) and not(@aggregation) ]" mode="attributes" />
      <!-- Compositions -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and @aggregation='composite']" mode="compositions" />
      <!-- References -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and (not(@aggregation) or @aggregation='shared')]" mode="references" />

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
    <xsl:element name="dataType">
      <xsl:variable name="xmiid" select="@xmi:id" />
      <xsl:if test="@isAbstract">
        <xsl:attribute name="abstract">
          <xsl:text>true</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="." mode="aselement" />

      <xsl:if test="*[@xmi:type='uml:Generalization']">
        <xsl:apply-templates select="*[@xmi:type='uml:Generalization']" />
      </xsl:if>

      <!-- Constraints - Modelio stores these at the Model level -->
      <xsl:apply-templates select="/xmi:XMI/uml:Model/ownedRule[@xmi:type='uml:Constraint' and @constrainedElement=$xmiid]" mode="elemConstraint"  />
      <!-- Subsets -->
      <xsl:apply-templates select="/xmi:XMI/uml:Model/ownedRule[@xmi:type='uml:Constraint' and @constrainedElement=$xmiid]" mode="roleConstraint"  />
      <!-- Attributes -->
      <xsl:apply-templates select="ownedAttribute[@xmi:type='uml:Property' and not(@association)]" mode="attributes" />
      <!-- References -->
      <xsl:apply-templates select=".//*[@xmi:type='uml:Property' and @association and (not(@aggregation) or @aggregation='shared')]" mode="references" />

      <!-- Compositions - NOT ALLOWED -->
      <xsl:if test=".//*[@xmi:type='uml:Property' and @association and @aggregation='composite']">
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
  <xsl:template match="*" mode="description">
    <xsl:element name="description">
      <xsl:choose>
        <xsl:when test="ownedComment[@xmi:type='uml:Comment']">
          <xsl:for-each select="ownedComment[@xmi:type='uml:Comment']">
            <xsl:value-of select="body" />
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          TODO : Missing description : please, update your UML model asap.
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>


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
  <xsl:template match="ownedRule[@xmi:type='uml:Constraint']"  mode="elemConstraint">

    <!-- check if this is a subset constraint -->
    <xsl:variable name="isSubset">
      <xsl:call-template name="checkIfSubset">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:variable>

    <!-- write Normal constraint node -->
    <xsl:if test="$isSubset='False'">
      <xsl:element name="constraint" >
	<xsl:element name="description">
          <xsl:value-of select="./specification/@value"/>
	</xsl:element>
      </xsl:element>
    </xsl:if>

  </xsl:template>

  <!-- ============================================================
       Template: roleConstraint                                    
         Generates 'constraint' node for SubsettedRole.            
                                                                   
         For Modelio,                                              
           There are 2 elements which define a 'subset' constraint.
           a) 'Constraint' associated with the object holding 
              the constrained element in a super type.
           b) a 'subset' stereotype refering to the Constraint as its 'base_constraint'

           The SubsettedRole content is on the Constraint as:
             + 'name' - holds the vodml-id of the subsetted role
             + 'specification/value' - holds the vodml-id of the constrained type
       ============================================================ -->
  <xsl:template match="ownedRule[@xmi:type='uml:Constraint']"  mode="roleConstraint">

    <!-- check if this is a subset constraint -->
    <xsl:variable name="isSubset">
      <xsl:call-template name="checkIfSubset">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$isSubset='True'">
      <xsl:element name="constraint">
        <xsl:attribute name="xsi:type" select="'vo-dml:SubsettedRole'"/>
        <xsl:element name="role">
          <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="@name"/>
          </xsl:call-template>
        </xsl:element>
        <xsl:element name="datatype">
          <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="specification/@value"/>
          </xsl:call-template>
        </xsl:element>
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
    <xsl:variable name="xmiid" select="@xmi:id"/>

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
    <xsl:variable name="xmiid" select="@xmi:id"/>

    <!-- check if the property is subsetted -->
    <xsl:variable name="isSubsetted">
      <xsl:call-template name="checkSubsetted">
        <xsl:with-param name="xmiid" select="@xmi:id" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:element name="composition">
      <xsl:apply-templates select="." mode="properties" />
      <xsl:if test="isSubsetted='True'">
        <xsl:element name="subsets">
          <xsl:call-template name="asElementRef">
            <xsl:with-param name="xmiidref" select="subsettedProperty/@xmi:idref"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
      <!-- check for isOrdered -->
      <xsl:if test="./@isOrdered = 'true'">
	<xsl:element name="isOrdered">
          <xsl:value-of select="'true'"/>
	</xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>


  <xsl:template match="ownedAttribute[@xmi:type='uml:Property']" mode="properties">
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
    
    <xsl:variable name="minOccurs">
      <xsl:choose>
        <xsl:when test="lowerValue">         <!-- check element exists -->
          <xsl:choose>          
          <xsl:when test="lowerValue/@value"><xsl:value-of select="lowerValue/@value"/></xsl:when> <!-- check element has value field -->
          <xsl:otherwise>0</xsl:otherwise> <!-- no value field.. default=0 -->
          </xsl:choose>
	</xsl:when>
        <xsl:otherwise>1</xsl:otherwise>  <!--  no lowerValue element.. default=1 -->
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="maxOccurs">
      <xsl:choose>
        <xsl:when test="upperValue/@value">
        <xsl:choose>
        <xsl:when test="upperValue/@value = '*'">-1</xsl:when>
        <xsl:otherwise><xsl:value-of select="upperValue/@value"/></xsl:otherwise>
        </xsl:choose>
        </xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      <xsl:element name="multiplicity">
      <xsl:call-template name="multiplicity">
        <xsl:with-param name="lower" select="$minOccurs" />
        <xsl:with-param name="upper" select="$maxOccurs" />
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
    <xsl:variable name="attribute" select="/xmi:XMI/*[local-name()='semanticconcept' and @base_NamedElement=$xmiid]" />
    <xsl:if test="$attribute">
      <xsl:element name="semanticconcept">
        <xsl:if test="$attribute/@topconcept">
          <xsl:element name="topConcept">
            <xsl:value-of select="$attribute/@topconcept" />
          </xsl:element>
        </xsl:if>
        <xsl:if test="$attribute/@vocabularyURI">
          <xsl:element name="vocabularyURI">
            <xsl:value-of select="$attribute/@vocabularyURI" />
          </xsl:element>
        </xsl:if>
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
          <xsl:choose>
            <xsl:when test="$upper='*'">
              <xsl:value-of select="'-1'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$upper" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>


  <!-- ============================================================
       Template: print-modelelements                               
         display of IVOA_UML_Profile modelelement records          
         NOTE: If none shown, check IVOA_UML_Profile namespace     
               definition at top of this script against what       
               is in the file.                                     
       ============================================================ -->
  <xsl:template name="print-profile-elements">
    <xsl:message>IVOA_UML_Profile</xsl:message>
    <xsl:message>..modelelements:</xsl:message>
    <xsl:for-each select="/xmi:XMI/IVOA_UML_Profile:modelelement">
      <xsl:message>....<xsl:value-of select="@xmi:id"/>..<xsl:value-of select="@vodmlid"/></xsl:message>
    </xsl:for-each>
  </xsl:template>


  <!-- ============================================================
       Template: get-class-from-id
         resolve class type for both data types (primitive or specific) and classes
         Generates 'datatype' tag.
       ============================================================ -->
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
    
    <!-- determine whether parent is a Package or not. If not, 
	 this is the root package which should be ignored. --> 
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
       Template: checkIfSubset                                    
         Check if a constraint is a 'Subset' constraint           

         Is there a 'subset' element referring to this element
         as its base_constraint?
       ============================================================ -->
  <xsl:template name="checkIfSubset">
    <xsl:param name="xmiid"/>

    <xsl:variable name="subset" select="/xmi:XMI/*[local-name()='subset' and @base_Constraint=$xmiid]" />
    <xsl:choose>
      <xsl:when test="$subset">
	<xsl:value-of select="'True'" />
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="'False'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ============================================================
       Template: checkSubsetted                                    
         Check if a Property is subsetted                          
       ============================================================ -->
  <xsl:template name="checkSubsetted">
    <xsl:param name="xmiid"/>

    <xsl:variable name="constraint" select="/xmi:XMI/uml:Model/ownedRule[@xmi:type='uml:Constraint' and @constrainedElement=$xmiid]" />
    <xsl:choose>
      <xsl:when test="$constraint">
        <xsl:variable name="constraintid" select="$constraint/@xmi:id"/>
        <xsl:variable name="subset" select="/xmi:XMI/*[local-name()='subset' and @base_Constraint=$constraintid]" />
        <xsl:choose>
          <xsl:when test="$subset">
	    <xsl:value-of select="'True'" />
          </xsl:when>
          <xsl:otherwise>
	    <xsl:value-of select="'False'" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="'False'" />
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
    <xsl:variable name="vodml-id" select="/xmi:XMI/*:modelelement[@base_NamedElement = $xmiid]/@vodmlid" />
    <xsl:variable name="modelimport" select="/xmi:XMI/uml:Model/packagedElement[@xmi:type='uml:Model' 
    and .//packagedElement[@xmi:id = $xmiid]]" />
    
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
      <xsl:apply-templates select="." mode="description"/>
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
    <!-- get referenced element, check for modelelement stereotype defining vodml-id  -->
    <xsl:variable name="element" select="/xmi:XMI//*[@xmi:id = $xmiidref]"/>
    <xsl:variable name="vodml-id" select="/xmi:XMI/*:modelelement[@base_NamedElement = $xmiidref]/@vodmlid" />
    
    <!-- get Package containing the referenced element -->
    <xsl:variable name="package" select="/xmi:XMI//*[@xmi:id = $xmiidref]/..[@xmi:type='uml:Package']"/>
    
    <!-- get root Package containing referenced element, check for modelimport stereotype.
	 imported elements must have vodml-id resolved here. -->
    <xsl:variable name="rootpackage" select="/xmi:XMI/uml:Model/packagedElement[@xmi:type='uml:Package' and .//*[@xmi:id = $xmiidref]]" />
    <xsl:variable name="modelimport" select="/xmi:XMI/*[local-name()='modelimport' and @base_Package=$rootpackage/@xmi:id]"/>
    
    <!-- report imported elements with no specified vodml-id. -->
    <xsl:if test="$modelimport and not($vodml-id)">
      <xsl:message> WARNING, vodml-ref reference <xsl:value-of select="$xmiidref"/> to element in imported model, but element has no declared vodml-id</xsl:message>
    </xsl:if>
   
    <!-- set model prefix, either current model, or imported model name -->
    <xsl:variable name="modelprefix">
      <xsl:choose>
        <xsl:when test="$modelimport">
          <xsl:value-of select="$modelimport/@name"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of  select="/xmi:XMI/uml:Model/@name" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Generate 'vodml-ref' tag -->
    <xsl:choose>
      <xsl:when test="$vodml-id">
        <!-- with specified vodml-id -->
        <xsl:element name="vodml-ref">
          <xsl:value-of select="concat($modelprefix,':',$vodml-id)"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <!-- without specified vodml-id -->
        <xsl:element name="vodml-ref">
        <xsl:choose>
          <xsl:when test="$modelimport"> 
            <!-- imported element with no specified vodml-id, fall back to element name -->
            <!-- eg: no modelelement stereotype assigned, or stereotype has no value. -->
            <xsl:value-of select="concat($modelprefix,':',$element/@name)"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- add the original xmiidref as attribute to indicate that the 
		 id still must be generated -->
            <xsl:attribute name="idref" select="$xmiidref"></xsl:attribute>
            <xsl:value-of select="$xmiidref" />
          </xsl:otherwise>
        </xsl:choose>
        </xsl:element>
      </xsl:otherwise>
      </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       Template: modelimport
         Generate 'import' tag for imported model, identified by
         an associated modelimport stereotype.
       ============================================================ -->
  <xsl:template match="packagedElement[@xmi:type='uml:Package']" mode="modelimport">
    <xsl:variable name="xmiid" select="@xmi:id"/>
    <xsl:variable name="modelimport" select="/xmi:XMI/*[local-name()='modelimport' and @base_Package = $xmiid]" />
    <xsl:if test="$modelimport">
    <xsl:element  name="import">
      <xsl:variable name="vodml-id" select="@name"/>
      <xsl:element name="name">
        <xsl:value-of select="$vodml-id"/>
      </xsl:element>
      <xsl:if test="$modelimport/@ivoId">
      <xsl:element name="ivoId"><xsl:value-of select="$modelimport/@ivoId"/>
      </xsl:element>
      </xsl:if>
      <xsl:element name="url"><xsl:value-of select="$modelimport/@url"/></xsl:element>
      <xsl:element name="documentationURL"><xsl:value-of select="$modelimport/@documentationURL"/></xsl:element>
    </xsl:element>
</xsl:if>
  </xsl:template>
  
  
</xsl:stylesheet>
