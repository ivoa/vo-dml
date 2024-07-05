<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
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

  <xsl:template match="objectType" mode="JPAAnnotation">
    <xsl:variable name="className" select="name" /> <!-- might need to be javaified -->
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
  @jakarta.persistence.Table( name = "<xsl:apply-templates select="." mode="tableName"/>" )
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
    @jakarta.persistence.DiscriminatorColumn( name = "<xsl:value-of select="$discriminatorColumnName"/>", discriminatorType = jakarta.persistence.DiscriminatorType.STRING, length = <xsl:value-of select="$discriminatorColumnLength"/>)
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
        @jakarta.persistence.ElementCollection
        @jakarta.persistence.CollectionTable(name = "<xsl:value-of select="$tableName"/>", joinColumns = @jakarta.persistence.JoinColumn(name="containerId") )
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
              <xsl:when test="xsd:int(multiplicity/maxOccurs) = -1">
                  <xsl:variable name="tableName">
                      <xsl:apply-templates select=".." mode="tableName"/><xsl:text>_</xsl:text><xsl:value-of select="$name"/>
                  </xsl:variable>
      @jakarta.persistence.ElementCollection
      @jakarta.persistence.CollectionTable(name = "<xsl:value-of select="$tableName"/>", joinColumns = @jakarta.persistence.JoinColumn(name="containerId") )
      @jakarta.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
              </xsl:when>
              <xsl:otherwise>
                      <xsl:call-template name="doEmbeddedJPA">
                      <xsl:with-param name="name" select="$name"/>
                      <xsl:with-param name="type" select="$type"/>
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
        <xsl:param name="name"/>
        <xsl:param name="type"/>
        <xsl:param name="nillable"/>
        @jakarta.persistence.Embedded
        <xsl:variable name="attovers" as="xsd:string*">

                <xsl:variable name="atv" as="xsd:string*">
                    <xsl:apply-templates select="$models/key('ellookup',current()/datatype/vodml-ref)" mode="attrovercols"><xsl:with-param name="prefix" select="$name"/></xsl:apply-templates>
                </xsl:variable>
<!--                <xsl:message><xsl:value-of select="concat('***',$name,'-',$type/name, ' ', name,' overrides -&#45;&#45; ',string-join($atv, ' %%%* '))" /></xsl:message>-->
                <xsl:for-each select="$atv">
                    <xsl:variable name="tmp"> <!-- just to make formatting easier  (otherwise each bit is a string seqmnent, and a lot of quotes!) -->
                        <xsl:variable name="attsubst">
                            <xsl:value-of select="string-join(tokenize(.,'_|\+')[position() != 1],'.')"/>
                        </xsl:variable>
                        <xsl:variable name="colsubs">
                            <xsl:choose>
                                <xsl:when test="contains(.,'+')">
                                    <xsl:value-of select="substring-before(.,'+')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>

                        </xsl:variable>
                        @jakarta.persistence.AttributeOverride(name="<xsl:value-of select='$attsubst'/>", column = @jakarta.persistence.Column(name="<xsl:value-of select='$colsubs'/>",  nullable = <xsl:value-of select='$nillable'/> ))
                    </xsl:variable>
                    <xsl:value-of select="$tmp"/>
                </xsl:for-each>
        </xsl:variable>
        @jakarta.persistence.AttributeOverrides( {
        <xsl:value-of select="string-join($attovers,concat(',',$cr))"/>
        })

    </xsl:template>

    <xsl:template match="dataType" mode="attrovercols" as="xsd:string*">
        <xsl:param name="prefix" as="xsd:string"/>
<!--        <xsl:message>** attrovercolsD <xsl:value-of select="concat(name(),' ',name,' *** ',$prefix, ' refs=', string-join(vf:baseTypes(vf:asvodmlref(current()))/reference/name,','))"/></xsl:message>-->
        <xsl:for-each select="(attribute, vf:baseTypes(vf:asvodmlref(current()))/attribute)"> <!-- this takes care of dataType inheritance should work https://hibernate.atlassian.net/browse/HHH-12790 -->
            <xsl:variable name="type" select="$models/key('ellookup',current()/datatype/vodml-ref)"/>
            <xsl:apply-templates select="$type" mode="attrovercols">
                <xsl:with-param name="prefix" select="concat($prefix,'_',name)"/>
            </xsl:apply-templates>
        </xsl:for-each>
        <xsl:for-each select="(reference, vf:baseTypes(vf:asvodmlref(current()))/reference)">
                <xsl:sequence select="concat($prefix,'_',name)"/>
        </xsl:for-each>
    </xsl:template>

    <!--produces _ separated string with possible last + separated
    for the type access all _ and + should be changed to .
    for the column name just drop the + separated if present.
     -->
    <xsl:template match="primitiveType" mode="attrovercols" as="xsd:string*">
        <xsl:param name="prefix" as="xsd:string"/>
        <xsl:variable name="type" select="$models/key('ellookup',current()/datatype/vodml-ref)"/>
<!--        <xsl:message>** attrovercolsP <xsl:value-of select="concat(name(),' ',name,' *** ',$prefix, ' extends=',extends)"/></xsl:message>-->
            <xsl:choose>
                <xsl:when test="vf:hasMapping(vf:asvodmlref(current()),'java')">
                    <xsl:variable name="pmap" select="vf:findmapping(vf:asvodmlref(current()),'java')"/>
                    <xsl:choose>
                        <xsl:when test="$pmap/@jpa-atomic">
                            <xsl:value-of select="$prefix"/>
                        </xsl:when>
                        <xsl:when test="$pmap/@primitive-value-field">
                            <xsl:value-of select="concat($prefix,'+',$pmap/@primitive-value-field)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($prefix,'+value')"/>
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:when>
                <xsl:when test="extends">
                    <xsl:apply-templates select="$models/key('ellookup',current()/extends/vodml-ref)" mode="attrovercols">
                        <xsl:with-param name="prefix" select="concat($prefix,'_value')"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$prefix"/> <!--this is the old primitive case -->
                </xsl:otherwise>
            </xsl:choose>
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
<!-- require manual management of references - do not remove referenced entity : do not cascade delete -->
@jakarta.persistence.ManyToOne( cascade = {  jakarta.persistence.CascadeType.REFRESH } )
@jakarta.persistence.JoinColumn( nullable = <xsl:apply-templates select="." mode="nullable"/> )

              </xsl:otherwise>
          </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="composition[multiplicity/maxOccurs != 1]" mode="JPAAnnotation">
    <xsl:variable name="type" select="$models/key('ellookup', current()/datatype/vodml-ref)"/>

    <xsl:choose>
      <xsl:when test="name($type) = 'primitiveType'">
          
      <xsl:variable name="tableName">
        <xsl:apply-templates select=".." mode="tableName"/><xsl:text>_</xsl:text><xsl:value-of select="name"/>
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
@jakarta.persistence.OneToMany(  cascade = jakarta.persistence.CascadeType.ALL, fetch = jakarta.persistence.FetchType.LAZY, targetEntity=<xsl:value-of select="concat(vf:JavaType(datatype/vodml-ref),'.class')" />)
@jakarta.persistence.JoinColumn( name="<xsl:value-of select="concat(upper-case(current()/parent::*/name),'_ID')"/>")
@org.hibernate.annotations.Fetch(org.hibernate.annotations.FetchMode.SUBSELECT)
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

    <xsl:template match="composition[multiplicity/maxOccurs =1]" mode="JPAAnnotation">
     @jakarta.persistence.OneToOne(cascade = jakarta.persistence.CascadeType.ALL)
  </xsl:template>



    <xsl:template name="enumPattern">
    <xsl:param name="columnName"/>

    @jakarta.persistence.Basic( optional=<xsl:apply-templates select="." mode="nullable"/> )
    @jakarta.persistence.Enumerated( jakarta.persistence.EnumType.STRING )
    @jakarta.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
  </xsl:template>








  <!-- persistence.xml configuration file -->  
  <xsl:template name="persistence_xml">
    <xsl:param name="puname"/>
    <xsl:param name="doit"/>
    <xsl:variable name="file" select="'META-INF/persistence.xml'"/>

    <!-- open file for jpa configuration -->
   <xsl:if test="$doit">
    <xsl:result-document href="{$file}" format="persistenceInfo">
    <xsl:element name="persistence" namespace="http://java.sun.com/xml/ns/persistence">
      <xsl:attribute name="version" select="'2.0'"/>
      <xsl:element name="persistence-unit" namespace="http://java.sun.com/xml/ns/persistence">
        <xsl:attribute name="name" select="$puname"/>
        <xsl:comment>we rely on hibernate extensions</xsl:comment>
        <xsl:element name="provider" namespace="http://java.sun.com/xml/ns/persistence">org.hibernate.jpa.HibernatePersistenceProvider<!--org.eclipse.persistence.jpa.PersistenceProvider--></xsl:element>
        <xsl:apply-templates select="$models/vo-dml:model/*" mode="jpaConfig"/>
        <xsl:element name="exclude-unlisted-classes" namespace="http://java.sun.com/xml/ns/persistence">true</xsl:element>
      </xsl:element>
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




</xsl:stylesheet>