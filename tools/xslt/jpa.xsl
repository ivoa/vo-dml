<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:exsl="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                extension-element-prefixes="exsl">

<!-- 
  This XSLT is used by intermediate2java.xsl to generate JPA annotations and JPA specific java code.
  
  Java 1.8+ is required by JPA 2.2.
-->

  <!-- common DDL templates used -->
  <xsl:include href="common-ddl.xsl"/>

  <xsl:output name="persistenceInfo" method="xml" encoding="UTF-8" indent="yes"  />

  <xsl:template match="objectType[vf:noTableInComposition(vf:asvodmlref(.))]" mode="JPAAnnotation">
     <xsl:if test="$models//composition[datatype/vodml-ref = vf:asvodmlref(current())]/multiplicity/maxOccurs != 1">
        <xsl:message terminate="yes">ObjectType <xsl:value-of select="vf:asvodmlref(current())"/> exists in a composition with maxOccurs &gt; 1 therefore must have separate table - check binding.</xsl:message>
     </xsl:if>
      <xsl:text>@jakarta.persistence.Embeddable</xsl:text>&cr;
  </xsl:template>

  <xsl:template match="objectType" mode="JPAAnnotation">
    <xsl:variable name="className" select="vf:upperFirst(name)" /> <!-- IMPL has been javaified -->
    <xsl:variable name="vodml-ref" select="concat(ancestor::vo-dml:model/name,':',vodml-id)" />
    <xsl:variable name="hasChild" as="xsd:boolean"
                  select="vf:hasSubTypes($vodml-ref)"/>
    <xsl:variable name="extMod" as="xsd:boolean"
                   select="count(extends) = 1"/>
    <xsl:variable name="hasName" as="xsd:boolean" select ="count(attribute[name = 'name']) > 0"/>
    <xsl:variable name="idname">
        <xsl:variable name="supers" select="(.,vf:baseTypes($vodml-ref))"/>
      <xsl:choose>
        <xsl:when test=" $supers/attribute/constraint[ends-with(@xsi:type,':NaturalKey')]">
            <xsl:value-of select=" $supers/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]/name"/>
        </xsl:when>
        <xsl:otherwise>_id</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

  @jakarta.persistence.Entity
  <xsl:if test="not($isRdbSingleInheritance) or ($isRdbSingleInheritance and not(extends))">
  @jakarta.persistence.Table( name = "<xsl:value-of select="vf:rdbTableName($vodml-ref)"/>" )
  </xsl:if>
  <xsl:if test="@abstract or $hasChild" >
      <xsl:choose>
          <xsl:when test="$isRdbSingleInheritance">
  @jakarta.persistence.Inheritance( strategy = jakarta.persistence.InheritanceType.SINGLE_TABLE )
          </xsl:when>
          <xsl:otherwise>
  @jakarta.persistence.Inheritance( strategy = jakarta.persistence.InheritanceType.JOINED )
          </xsl:otherwise>
      </xsl:choose>
  </xsl:if>
    <xsl:if test="count(vf:baseTypes($vodml-ref) )= 0 and(@abstract or $hasChild)">
    @jakarta.persistence.DiscriminatorColumn( name = "<xsl:value-of select="vf:rdbODiscriminatorName($vodml-ref)"/>", discriminatorType = jakarta.persistence.DiscriminatorType.STRING, length = <xsl:value-of select="$discriminatorColumnLength"/>)
    </xsl:if>
    <xsl:if test="$extMod or $hasChild and not(@abstract)">
  @jakarta.persistence.DiscriminatorValue( "<xsl:value-of select="vf:utype(vf:asvodmlref(.))"/>" )
  </xsl:if>
  @jakarta.persistence.NamedQueries( {
    @jakarta.persistence.NamedQuery( name = "<xsl:value-of select="$className"/>.findById", query = "SELECT o FROM <xsl:value-of select="$className"/> o WHERE o.<xsl:value-of select="$idname"/> = :id")
  <xsl:if test="$hasName">
,     @jakarta.persistence.NamedQuery( name = "<xsl:value-of select="$className"/>.findByName", query = "SELECT o FROM <xsl:value-of select="$className"/> o WHERE o.name = :name")
  </xsl:if>
  } )
      <xsl:if test="reference[multiplicity/maxOccurs != 1]|composition[multiplicity/maxOccurs != 1]">
          @jakarta.persistence.NamedEntityGraph(
             name="<xsl:value-of select="concat($className,'_loadAll')"/>",
             attributeNodes = {
               <xsl:for-each select="reference[multiplicity/maxOccurs != 1]|composition[multiplicity/maxOccurs != 1]">
                   @jakarta.persistence.NamedAttributeNode(value="<xsl:value-of select='name'/>")<xsl:if test="position() != last()">,</xsl:if>
               </xsl:for-each>
            }
          <!-- TODO need to think about subgraphs -->
          )
      </xsl:if>
     <xsl:apply-templates select="current()[attribute[vf:isDataType(.)]]" mode="doEmbeddedRefs"/>

 </xsl:template>



  <xsl:template match="primitiveType" mode="JPAAnnotation">
    <xsl:text>@jakarta.persistence.Embeddable</xsl:text>&cr;
  </xsl:template>


  <xsl:template match="dataType" mode="JPAAnnotation">
       <xsl:text>@jakarta.persistence.Embeddable</xsl:text>&cr;
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
    <xsl:if test="vf:hasSubTypes($vodml-ref)"  >
        <xsl:text>@jakarta.persistence.MappedSuperclass</xsl:text>&cr;<!-- this works for hibernate but seem to need at every level not just top in multi-level hierarchy-->
    </xsl:if>
<!--    <xsl:if test="vf:hasSubTypes($vodml-ref) or count(vf:baseTypes($vodml-ref))>0">-->
<!--      @org.eclipse.persistence.annotations.Customizer(<xsl:value-of select="vf:upperFirst(name)"/>.DescConv.class)-->
<!--    </xsl:if>-->
  </xsl:template>


  <!--TODO not used IMPL this strategy for dataType hierarchies will not work if the whole hierarchy is not present in the code generation - e.g. if the ivoa model is to be a fixed library, then
  things derived from quantity cannot be embedded in the final using model -->
  <xsl:template match="dataType" mode="JPAConverter">
      <!-- https://wiki.eclipse.org/EclipseLink/UserGuide/JPA/Basic_JPA_Development/Entities/Embeddable#Inheritance
      https://www.eclipse.org/forums/index.php/t/239667/
      claims it is possible to do embeddable inheritance - causes NPE
      hibernate does https://stackoverflow.com/questions/29278249/hibernate-embeddable-class-which-extends-another-embeddable-class-properties-->
    <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
    <xsl:if test="vf:hasSubTypes($vodml-ref) or count(vf:baseTypes($vodml-ref))>0">
      public static class DescConv implements org.eclipse.persistence.config.DescriptorCustomizer {
         @Override
         public void customize(org.eclipse.persistence.descriptors.ClassDescriptor descriptor) throws Exception {
         <xsl:variable name="bases" select="vf:baseTypes($vodml-ref)"/>
         <xsl:choose>
           <xsl:when test="count($bases) > 0">
             descriptor.getInheritancePolicy().setParentClass(<xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref($bases[1]))"/>.class);
           </xsl:when>
           <xsl:otherwise>
             descriptor.getInheritancePolicy().setClassIndicatorFieldName("<xsl:value-of select="name"/>_TYPE");
             <xsl:for-each select="vf:subTypes(vf:asvodmlref(.))">
               descriptor.getInheritancePolicy().addClassIndicator(<xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/>.class, "<xsl:value-of select="name"/>");
             </xsl:for-each>
           </xsl:otherwise>
         </xsl:choose>

      }
     }
    </xsl:if>
  </xsl:template>


  <!-- template attribute : adds JPA annotations for primitive types, data types & enumerations -->
  <!-- Note: this template uses field access and should be used by objectType-s.
  For dataType attributes we (attempt to) use embedded types. -->
    <xsl:template match="attribute" mode="JPAAnnotation">
        <xsl:if test="constraint[ends-with(@xsi:type,':NaturalKey')]"><!-- TODO deal with compound keys -->
            @jakarta.persistence.Id
        </xsl:if>
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
        <xsl:variable name="name" select="name"/>
        <xsl:variable name="type" select="$models/key('ellookup',current()/datatype/vodml-ref)"/>
        <xsl:variable name="thisattr"  select="."/>
        <xsl:choose>
            <!--     <xsl:message>****jpa attr  ref=<xsl:value-of select="datatype/vodml-ref"/> type="<xsl:value-of select="name($type)"/>" </xsl:message> -->
            <xsl:when test="name($type) = 'primitiveType'">
                <xsl:choose>
                    <xsl:when test="xsd:int(multiplicity/maxOccurs) = -1">
                        <xsl:variable name="tableName">
                            <xsl:apply-templates select=".." mode="tableName"/><xsl:text>_</xsl:text><xsl:value-of select="$name"/>
                        </xsl:variable>
                <xsl:variable name="converterClass">
                    <xsl:variable name="jt" select="vf:findmapping(datatype/vodml-ref,'java')"/>
                    <xsl:choose><!--TODO this is rather hard wired - perhaps do something else in mapping-->
                        <xsl:when test="$jt = 'Integer'"><xsl:sequence select="'IntListConverter'"/></xsl:when>
                        <xsl:when test="$jt = 'Double'"><xsl:sequence select="'DoubleListConverter'"/></xsl:when>
                        <xsl:when test="$jt = 'Boolean'"><xsl:sequence select="'IntListConverter'"/></xsl:when>
                        <xsl:otherwise><xsl:sequence select="'StringListConverter'"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                @jakarta.persistence.Convert(converter=org.ivoa.vodml.jpa.AttributeConverters.<xsl:value-of select="$converterClass"/>.class)
                @jakarta.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
                    </xsl:when>
                    <xsl:when test="xsd:int(multiplicity/maxOccurs) gt 1">
        //FIXME - how to do arrays for JPA.
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$type/name = 'datetime'">
        @jakarta.persistence.Basic( optional = <xsl:apply-templates select="." mode="nullable"/> )
        @jakarta.persistence.Temporal( jakarta.persistence.TemporalType.TIMESTAMP )
        @jakarta.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
                            </xsl:when>
                            <xsl:when test="vf:findmapping(datatype/vodml-ref,'java')/@jpa-atomic">
        @jakarta.persistence.Basic( optional = <xsl:apply-templates select="." mode="nullable"/> )
        @jakarta.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/>
                                <xsl:if test="vf:findTypeDetail($vodml-ref)/length">
                                    , length=<xsl:value-of select="vf:findTypeDetail($vodml-ref)/length"/>
                                </xsl:if>)
                            </xsl:when>
                            <xsl:otherwise>
        @jakarta.persistence.Embedded
        @jakarta.persistence.AttributeOverrides ({@jakarta.persistence.AttributeOverride(name = "value", column =@jakarta.persistence.Column(name="<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/>))})
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:when>
            <xsl:when test="name($type) = 'enumeration'">
                <xsl:call-template name="enumPattern">
                   <xsl:with-param name="columnName"><xsl:apply-templates select="." mode="columnName"/></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name($type) = 'dataType'">
            <xsl:choose>
              <xsl:when test="xsd:int(multiplicity/maxOccurs) = -1"> <!--TODO IMPL multiplicity > 1 being supported - but it really should not be modelled this way -->
                  <xsl:variable name="tableName">
                      <xsl:apply-templates select=".." mode="tableName"/><xsl:text>_</xsl:text><xsl:value-of select="$name"/>
                  </xsl:variable>
      @jakarta.persistence.ElementCollection
      @jakarta.persistence.CollectionTable(name = "<xsl:value-of select="$tableName"/>", joinColumns = @jakarta.persistence.JoinColumn(name="containerId") )
      @jakarta.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
              </xsl:when>
              <xsl:otherwise>
                      <xsl:call-template name="doEmbeddedJPA">
                      <xsl:with-param name="nillable" >
                          <xsl:choose>
                              <xsl:when test="$isRdbSingleInheritance">true</xsl:when><!--IMPL perhaps this is too simplistic -->
                              <xsl:otherwise>
                                  <xsl:apply-templates select="$thisattr" mode="nullable"/> <!-- but anyway this does not cope with the case where parts of the dataType are not nullable -->
                              </xsl:otherwise>
                          </xsl:choose>
                      </xsl:with-param>
                  </xsl:call-template>
              </xsl:otherwise>
          </xsl:choose>
          </xsl:when>
            <xsl:otherwise>
                <xsl:message> ++++++++  ERROR  +++++++ on attribute=<xsl:value-of select="name"/> type=<xsl:value-of select="name($type)"/> is not supported.</xsl:message>
        // TODO    [NOT_SUPPORTED_ATTRIBUTE]
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="doEmbeddedJPA">
        <xsl:param name="nillable"/>
        @jakarta.persistence.Embedded
        <xsl:if test="current()/parent::objectType">
        <xsl:variable name="attovers" as="xsd:string*">

            <xsl:variable name="atv">
                <xsl:apply-templates select="current()" mode="attrovercols2"/>
            </xsl:variable>
<!--                <xsl:message>***D <xsl:value-of select="vf:asvodmlref(current())"/> -&#45;&#45; <xsl:copy-of select="$atv" copy-namespaces="no"/></xsl:message>-->
                <xsl:apply-templates select="$atv" mode="doAttributeOverride">
                    <xsl:with-param name="nillable" select="$nillable"/>
                </xsl:apply-templates>
        </xsl:variable>
        @jakarta.persistence.AttributeOverrides( {
        <xsl:value-of select="string-join($attovers,concat(',',$cr))"/>
        })
        </xsl:if>
    </xsl:template>
    <xsl:template match="att[not(*)]" mode="doAttributeOverride">
        <xsl:param name="nillable"/>

  <xsl:sequence select="concat('@jakarta.persistence.AttributeOverride(name=',$dq, string-join(current()/ancestor-or-self::att/@f,'.'),$dq,
        ', column = @jakarta.persistence.Column(name=',$dq,string-join(current()/ancestor-or-self::att/@c,'_'),$dq,
        ',nullable = ',$nillable,' ))')"/>
    </xsl:template>

    <xsl:template match="ref" mode="doAssocOverride">
        <xsl:value-of select="concat('@jakarta.persistence.AssociationOverride(name=',$dq,string-join((current()/@f,current()/ancestor::att/@f),'.'),$dq,
        ',joinColumns = { @jakarta.persistence.JoinColumn(name=',$dq,string-join((current()/@c,current()/ancestor::att/@c),'_'),$dq,  ',nullable =',true(),')})')"/><!--IMPL have to allow null - too difficult to work out when not allowed - see proposalDM ObservingPlatform -->
    </xsl:template>

    <!-- do the embedded refs -->
    <xsl:template match="objectType[attribute[vf:isDataType(.)]]" mode="doEmbeddedRefs">
        <xsl:variable name="attovers" as="xsd:string*">
            <xsl:for-each select="attribute[vf:isDataType(.)]">
               <xsl:apply-templates select="current()" mode="doEmbeddedRefs"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="not(empty($attovers))">
            @jakarta.persistence.AssociationOverrides( {
            <xsl:value-of select="string-join($attovers,concat(',',$cr))"/>
            })
        </xsl:if>
    </xsl:template>

    <xsl:template match="attribute" mode="doEmbeddedRefs" as="xsd:string*">
        <xsl:variable name="thisname" select="name"/>
        <xsl:for-each select="($models/key('ellookup',current()/datatype/vodml-ref)/reference,vf:baseTypes(current()/datatype/vodml-ref)/reference)">
            <xsl:value-of select="concat('@jakarta.persistence.AssociationOverride(name=',$dq,$thisname,'.',name,$dq,',joinColumns = { @jakarta.persistence.JoinColumn(name=',$dq,$thisname,'_',name,$dq,  ',nullable =',true(),')})')"/><!--IMPL have to allow null - too difficult to work out when not allowed - see proposalDM ObservingPlatform -->
        </xsl:for-each>
    </xsl:template>


    <xsl:template match="attribute|reference|composition" mode="nullable">
<!--      <xsl:message>nullability - <xsl:value-of select="concat(name,' parent=',./parent::*/name, ' type=',./parent::*/name())"/> </xsl:message>-->
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(./parent::*)"/>
      <xsl:choose>
          <xsl:when test="./parent::*/name()='dataType'">
              <xsl:text>true</xsl:text> <!-- TODO could be less restrictive - non-inherited datatypes not in type hierarchies could still have restrictions-->
          </xsl:when>
          <xsl:otherwise>
              <xsl:choose>
                  <xsl:when test="$isRdbSingleInheritance">
                      <xsl:choose>
                          <xsl:when test="count(current()/parent::*/extends) > 0 ">
                              <!--and count($models/key('ellookup',current()/parent::*/extends/vodml-ref)[@abstract='true']) = 0 -->
                              <xsl:text>true</xsl:text>
                          </xsl:when>
                          <xsl:otherwise>
                              <xsl:choose>
                                  <xsl:when test="starts-with(multiplicity, '0')">true</xsl:when>
                                  <xsl:otherwise>false</xsl:otherwise>
                              </xsl:choose>
                          </xsl:otherwise>
                      </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:choose>
                          <xsl:when test="starts-with(multiplicity, '0')">true</xsl:when>
                          <xsl:otherwise>false</xsl:otherwise>
                      </xsl:choose>
                  </xsl:otherwise>
              </xsl:choose>

          </xsl:otherwise>
      </xsl:choose>
 </xsl:template>




  <xsl:template match="reference" mode="JPAAnnotation">
    <xsl:variable name="type" select="$models/key('ellookup', datatype/vodml-ref)"/>

    <xsl:choose>
      <xsl:when test="name($type) = 'primitiveType' or name($type) = 'enumeration'">
      <xsl:message> ++++++++  ERROR  +++++++ on reference=<xsl:value-of select="name"/> type=<xsl:value-of select="name($type)"/> is not supported.</xsl:message>
      
// TODO    [NOT_SUPPORTED_REFERENCE]
      </xsl:when>
      <xsl:otherwise>
          <xsl:choose>
              <xsl:when test="xsd:int(multiplicity/maxOccurs) != 1">
                  <!-- TODO should not really leave join table naming to JPA - should be explicit-->
                  <!-- require manual management of references - do not remove referenced entity : do not cascade delete -->
@jakarta.persistence.ManyToMany( cascade = {  jakarta.persistence.CascadeType.REFRESH } )
              </xsl:when>
              <xsl:otherwise>
              <xsl:variable name="colname" select="vf:rdbRefColumnName(vf:asvodmlref(current()))"/>

                  <!-- require manual management of references - do not remove referenced entity : do not cascade delete -->
@jakarta.persistence.ManyToOne( cascade = {  jakarta.persistence.CascadeType.REFRESH } )
@jakarta.persistence.JoinColumn( name="<xsl:value-of select="$colname"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
              </xsl:otherwise>
          </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="composition[multiplicity/maxOccurs != 1]" mode="JPAAnnotation">
    <xsl:variable name="type" select="$models/key('ellookup', current()/datatype/vodml-ref)"/>
    <xsl:variable name="parent" select="current()/parent::*"/>
    <xsl:choose>
      <xsl:when test="name($type) = 'primitiveType'">
          
      <xsl:variable name="tableName">
        <xsl:value-of select="vf:rdbTableName(vf:asvodmlref(..))"/><xsl:text>_</xsl:text><xsl:value-of select="name"/>
      </xsl:variable>
      <xsl:variable name="columns">
        <xsl:apply-templates select="." mode="columns"/>
      </xsl:variable> 
     <xsl:for-each select="$columns/column">
    @jakarta.persistence.ElementCollection
    @jakarta.persistence.CollectionTable( name = "<xsl:value-of select="$tableName"/>", joinColumns = @jakarta.persistence.JoinColumn(name="containerId") )
    @jakarta.persistence.Column( name = "<xsl:value-of select="name"/>" )
     </xsl:for-each>   
      </xsl:when>
      <xsl:when test="name($type) = 'enumeration' or name($type) = 'dataType'">
/* TODO: [NOT_SUPPORTED_COLLECTION = <xsl:value-of select="name($type)"/>] */
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="isOrdered">
@jakarta.persistence.OrderColumn
        </xsl:if>
@jakarta.persistence.OneToMany(  cascade = jakarta.persistence.CascadeType.ALL, fetch = <xsl:value-of select="$jpafetch"/>, targetEntity=<xsl:value-of select="concat(vf:JavaType(datatype/vodml-ref),'.class')" />)
@jakarta.persistence.JoinColumn( name="<xsl:value-of select="vf:rdbCompositionJoinName($parent)"/>")
@org.hibernate.annotations.Fetch(org.hibernate.annotations.FetchMode.SUBSELECT)
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

    <xsl:template match="composition[multiplicity/maxOccurs =1]" mode="JPAAnnotation">
        <xsl:choose>
            <xsl:when test="vf:noTableInComposition(datatype/vodml-ref)">
                @jakarta.persistence.Embedded
                <xsl:variable name="atv">
                    <xsl:apply-templates select="current()" mode="attrovercols2"/>
                </xsl:variable>
                <xsl:variable name="attovers" as="xsd:string*">


                    <xsl:variable name="nillable" >
                        <xsl:choose>
                            <xsl:when test="$isRdbSingleInheritance">true</xsl:when><!--IMPL perhaps this is too simplistic -->
                            <xsl:otherwise>
                                <xsl:apply-templates select="current()" mode="nullable"/> <!-- but anyway this does not cope with the case where parts of the dataType are not nullable -->
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

<!--                    <xsl:message>***O <xsl:value-of select="current()/datatype/vodml-ref"/> -&#45;&#45; <xsl:copy-of select="$atv" copy-namespaces="no"/></xsl:message>-->
                    <xsl:apply-templates select="$atv" mode="doAttributeOverride">
                        <xsl:with-param name="nillable" select="$nillable"/>
                    </xsl:apply-templates>
                </xsl:variable>
                @jakarta.persistence.AttributeOverrides( {
                <xsl:value-of select="string-join($attovers,concat(',',$cr))"/>
                })
                <xsl:variable name="assocovers" as="xsd:string*">
                     <xsl:apply-templates select="$atv" mode="doAssocOverride"/>
                </xsl:variable>
                @jakarta.persistence.AssociationOverrides( {
                <xsl:value-of select="string-join($assocovers,concat(',',$cr))"/>
                })
            </xsl:when>

            <xsl:otherwise>
                @jakarta.persistence.OneToOne(cascade = jakarta.persistence.CascadeType.ALL)
            </xsl:otherwise>
        </xsl:choose>   

  </xsl:template>



    <xsl:template name="enumPattern">
    <xsl:param name="columnName"/>

    @jakarta.persistence.Basic( optional=<xsl:apply-templates select="." mode="nullable"/> )
    @jakarta.persistence.Enumerated( jakarta.persistence.EnumType.STRING )
    @jakarta.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
  </xsl:template>








  <!-- persistence.xml configuration file -->  
  <xsl:template name="persistence_xml">
    <xsl:param name="doit"/>
    <xsl:variable name="file" select="'META-INF/persistence.xml'"/>

    <!-- open file for jpa configuration -->
   <xsl:if test="$doit">
    <xsl:result-document href="{$file}" format="persistenceInfo">
    <xsl:element name="persistence" namespace="http://java.sun.com/xml/ns/persistence">
      <xsl:attribute name="version" select="'2.0'"/>
      <xsl:for-each select="$models/vo-dml:model">
      <xsl:element name="persistence-unit" namespace="http://java.sun.com/xml/ns/persistence">
        <xsl:attribute name="name" select="name"/>
        <xsl:comment>we rely on hibernate extensions</xsl:comment>
        <xsl:element name="provider" namespace="http://java.sun.com/xml/ns/persistence">org.hibernate.jpa.HibernatePersistenceProvider<!--org.eclipse.persistence.jpa.PersistenceProvider--></xsl:element>
        <xsl:apply-templates select="*" mode="jpaConfig"/>
        <xsl:for-each select="import/name">
            <xsl:apply-templates select="$models/vo-dml:model[name=current()]/*" mode="jpaConfig"/>
        </xsl:for-each>
        <xsl:element name="exclude-unlisted-classes" namespace="http://java.sun.com/xml/ns/persistence">true</xsl:element>
      </xsl:element>
      </xsl:for-each>
    </xsl:element>
    </xsl:result-document>
   </xsl:if>
      <!-- add beans.xml - for quarkus https://quarkus.io/guides/hibernate-orm#defining-entities-in-external-projects-or-jars - hopefully benign-->
      <xsl:result-document href="META-INF/beans.xml" format="persistenceInfo">
          <xsl:comment>this has been put here for quarkus</xsl:comment>
      </xsl:result-document>

  </xsl:template>

  <xsl:template match="package" mode="jpaConfig" >
    <xsl:apply-templates select="*" mode="jpaConfig"/>
  </xsl:template>

  <xsl:template name="jpaclassdecl">
    <xsl:param name="vodml-ref"/>
    <xsl:element name="class" namespace="http://java.sun.com/xml/ns/persistence">

      <xsl:value-of select="vf:QualifiedJavaType($vodml-ref)"/>
    </xsl:element>

  </xsl:template>
  <xsl:template match="objectType|dataType|primitiveType" mode="jpaConfig">
     <xsl:variable name="vodml-ref" select="concat(./ancestor::vo-dml:model/name,':',vodml-id)"/>
<!--      <xsl:message>JPA persistence.xml <xsl:value-of select="concat($vodml-ref, ' ', $mapping/key('maplookup',$vodml-ref)/java-type)"/> </xsl:message>-->
     <xsl:if test="not($mapping/key('maplookup',$vodml-ref)/java-type/@jpa-atomic)">
     <xsl:call-template name="jpaclassdecl">
       <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
     </xsl:call-template>
     </xsl:if>
  </xsl:template>
  <xsl:template match="*" mode="jpaConfig"><!-- do nothing --></xsl:template>

  <!-- template to do smart deletion in the case of contained references
  TODO could also do something better in the case of bulk deletion.-->
  <xsl:template match="objectType" mode="jpadeleter">
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
      <xsl:if test="not(@abstract)">
    /**
      * {@inheritDoc}
      */
      @Override
      public void delete(jakarta.persistence.EntityManager em) {
      <xsl:variable name="crefs" select="distinct-values(vf:containedReferencesInContainmentHierarchy($vodml-ref))"/>

      <xsl:choose>
          <xsl:when test="count($crefs)> 0">
              //has contained references <xsl:value-of select="string-join($crefs,',')"/>
              <xsl:variable name="by" select="distinct-values(for $i in $crefs return vf:referredBy($i))"/>
              //referred to by <xsl:value-of select="concat(string-join($by,','),$nl)"/>
              <!-- TODO this only deals with referrers same level of containment.... -->
              <xsl:for-each select="for $v in (vf:baseTypes($vodml-ref),$models/key('ellookup',$vodml-ref)) return $v/(composition)[datatype/vodml-ref= $by]"> <!--assume JPA will deal with attributes OK... -->
                  <xsl:choose>
                      <xsl:when test="vf:multiple(current())">
                          <!-- IMPL perhaps we could do bulk delete to speed things up -->
                          <xsl:value-of select="vf:javaMemberName(current()/name)"/>.stream().forEach(i -> em.remove(i));
                      </xsl:when>
                      <xsl:otherwise>
                          em.remove(<xsl:value-of select="vf:javaMemberName(current()/name)"/>);
                      </xsl:otherwise>
                  </xsl:choose>

              </xsl:for-each>
              em.remove(this); // finish up with itself.
          </xsl:when>
          <xsl:otherwise>
              em.remove(this); // nothing special to do
          </xsl:otherwise>
      </xsl:choose>

      }
      </xsl:if>
  </xsl:template>


</xsl:stylesheet>