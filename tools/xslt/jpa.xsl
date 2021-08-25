<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
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
    <xsl:variable name="xmiid" select="concat(ancestor::vo-dml:model/name,':',vodml-id)" />
    <xsl:variable name="hasChild" as="xsd:boolean"
                  select="vf:hasChildren($xmiid)"/>
    <xsl:variable name="extMod" as="xsd:boolean"
                   select="count(extends) = 1"/>
    <xsl:variable name="hasName" as="xsd:boolean" select ="count(attribute[name = 'name']) > 0"/>

  @javax.persistence.Entity
  @javax.persistence.Table( name = "<xsl:apply-templates select="." mode="tableName"/>" )
  <xsl:if test="@abstract or $hasChild" >
  @javax.persistence.Inheritance( strategy = javax.persistence.InheritanceType.JOINED )
  </xsl:if>
    <xsl:if test="count(vf:baseTypes($xmiid)) = 0 and(@abstract or $hasChild)">
    @javax.persistence.DiscriminatorColumn( name = "<xsl:value-of select="$discriminatorColumnName"/>", discriminatorType = javax.persistence.DiscriminatorType.STRING, length = <xsl:value-of select="$discriminatorColumnLength"/>)
    </xsl:if>
    <xsl:if test="$extMod">
  @javax.persistence.DiscriminatorValue( "<xsl:value-of select="$className"/>" ) <!-- TODO decide whether this should be a path - current is just default anyuway-->
  </xsl:if>
<!-- Once JPA 2.0 with nested embeddable mapping is supported in Eclipselink we may revisit the next code. 
For now it is commented out. -->
<!-- 
  <xsl:if test="attribute[$models/key('ellookup', datatype/vodml-ref)/name() = 'dataType']">
    @javax.persistence.AttributeOverrides ( {
        <xsl:variable name="columns">
          <xsl:apply-templates select="." mode="columns"/>
        </xsl:variable>
       <xsl:for-each select="exsl:node-set($columns)/column">
         @javax.persistence.AttributeOverride( name = "<xsl:value-of select="attroverride"/>", column = @javax.persistence.Column( name = "<xsl:value-of select="name"/>" ) )
         <xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
       </xsl:for-each>
         <xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
     </xsl:for-each>
    } )
  </xsl:if>
 -->
   @javax.persistence.NamedQueries( {
    @javax.persistence.NamedQuery( name = "<xsl:value-of select="$className"/>.findById", query = "SELECT o FROM <xsl:value-of select="$className"/> o WHERE o.id = :id")
  <xsl:if test="$hasName">
,     @javax.persistence.NamedQuery( name = "<xsl:value-of select="$className"/>.findByName", query = "SELECT o FROM <xsl:value-of select="$className"/> o WHERE o.name = :name")
  </xsl:if>
  } )
  </xsl:template>




  <xsl:template match="objectType|dataType" mode="JPASpecials">
    <xsl:param name="hasChild"/>
    <xsl:param name="hasExtends"/>

    <xsl:if test="name() = 'objectType' and $hasExtends and $hasChild">
    /** classType gives the discriminator value stored in the database for an inheritance hierarchy */
    @javax.persistence.Column( name = "<xsl:value-of select="$discriminatorColumnName"/>", insertable = false, updatable = false, nullable = false )
    protected String classType;
    </xsl:if>

    <xsl:if test="name() = 'objectType' and $hasExtends">
    /** jpaVersion gives the current version number for that entity (used by pessimistic / optimistic locking in JPA) */
    @javax.persistence.Version()
    @javax.persistence.Column( name = "OPTLOCK" )
    protected int jpaVersion;
    </xsl:if>

    <xsl:if test="container">
      <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="container/vodml-ref"/></xsl:call-template></xsl:variable>
    /** container gives the parent entity which owns a collection containing instances of this class */
    @javax.persistence.ManyToOne( cascade = { javax.persistence.CascadeType.PERSIST, javax.persistence.CascadeType.MERGE, javax.persistence.CascadeType.REFRESH } )
    @javax.persistence.JoinColumn( name = "containerId", referencedColumnName = "id", nullable = false )
    protected <xsl:value-of select="$type"/> container;

    /** rank : position in the container collection  */
    @javax.persistence.Basic( optional = false )
    @javax.persistence.Column( name = "rank", nullable = false )
    protected int rank = -1;
    </xsl:if>
  </xsl:template>




  <xsl:template match="dataType" mode="JPAAnnotation">
    <xsl:text>@javax.persistence.Embeddable</xsl:text>&cr;
<!-- see comment for similar code concerning nested embeddables in the objectType template -->    
<!-- 
  <xsl:if test="attribute[$models/key('ellookup', datatype/vodml-ref)/name() = 'dataType']">
    @javax.persistence.AttributeOverrides ( {
      <xsl:for-each select="attribute[$models/key('ellookup', datatype/vodml-ref)/name() = 'dataType']">
        <xsl:variable name="columns">
          <xsl:apply-templates select="." mode="columns"/>
        </xsl:variable>
       <xsl:for-each select="exsl:node-set($columns)/column">
         @javax.persistence.AttributeOverride( name = "<xsl:value-of select="attroverride"/>", column = @javax.persistence.Column( name = "<xsl:value-of select="name"/>" ) )
         <xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
       </xsl:for-each>
         <xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
     </xsl:for-each>
    } )
  </xsl:if>
 -->
   </xsl:template>

<xsl:template match="primitiveType" mode="JPAAnnotation">
  <xsl:text>@javax.persistence.Embeddable</xsl:text>&cr;
</xsl:template>


  <!-- template attribute : adds JPA annotations for primitive types, data types & enumerations -->
  <!-- Note: this template uses field access and should be used by objectType-s.
  For dataType attributes we (attempt to) use property based access, as that allows a level of nesting. -->
  <xsl:template match="attribute" mode="JPAAnnotation">
<!-- currently the choose element never gets to first element
enable that again if we want (and are able) to use property access using get/set methods.
Currently only for JPA 2.0 impementation of eclipselink it seems as if nested attributeoverride-s at least comppile and weave-->
    <xsl:choose>
      <xsl:when test="../name() = 'dataType' and 0 = 1">
        <xsl:text>@javax.persistence.Basic</xsl:text>
      </xsl:when>
      <xsl:otherwise>
    <xsl:variable name="ref" select="datatype/vodml-ref"/>  <!--  first mystery - need to create this variable to use in key below - even string(datatype/vodml-ref) does not work  -->
    <xsl:variable name="type" select="$models/key('ellookup',$ref)"/>
       
<!--     <xsl:message>****jpa attr  ref=<xsl:value-of select="datatype/vodml-ref"/> type="<xsl:value-of select="name($type)"/>" </xsl:message> -->
    <xsl:choose>
      <xsl:when test="name($type) = 'primitiveType'">
        <xsl:choose>
          <xsl:when test="number(constraints/maxLength) = -1">
    @javax.persistence.Basic( fetch = javax.persistence.FetchType.EAGER, optional = <xsl:apply-templates select="." mode="nullable"/> )
    @javax.persistence.Lob
    @javax.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
          </xsl:when>
          <xsl:when test="number(constraints/maxLength) > 0">
    @javax.persistence.Basic( optional = <xsl:apply-templates select="." mode="nullable"/> )
    @javax.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/>, length = <xsl:value-of select="constraints/maxLength"/> )
          </xsl:when>
          <xsl:when test="$type/name = 'datetime'">
    @javax.persistence.Basic( optional = <xsl:apply-templates select="." mode="nullable"/> )
    @javax.persistence.Temporal( javax.persistence.TemporalType.TIMESTAMP )
    @javax.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
          </xsl:when>
          <xsl:otherwise>
    @javax.persistence.Basic( optional = <xsl:apply-templates select="." mode="nullable"/> )
    @javax.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
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
          <xsl:when test="../name() = 'dataType'">
          @javax.persistence.Embedded
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." mode="attroverride"/>
          </xsl:otherwise>
        </xsl:choose>
     </xsl:when>
      <xsl:otherwise>
      <xsl:message> ++++++++  ERROR  +++++++ on attribute=<xsl:value-of select="name"/> type=<xsl:value-of select="name($type)"/> is not supported.</xsl:message>
// TODO    [NOT_SUPPORTED_ATTRIBUTE]
      </xsl:otherwise>
    </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
  </xsl:template>



  <xsl:template match="attribute" mode="attroverride">
        <!-- NB see comment at the common-ddl template called here for the treatment of the
        attroverride element. This currently contains the name of this attribute as a prefix, whihc therefore
        must be removed here. IF the attributeoverride were defined at the class level this would be the correct value.
         -->
        <xsl:variable name="columns">
          <xsl:apply-templates select="." mode="nested"/>
        </xsl:variable>
        <xsl:variable name="attrname" select="name"/>
    @javax.persistence.Embedded
    @javax.persistence.AttributeOverrides ( {
       <xsl:for-each select="exsl:node-set($columns)/nested">
         <xsl:variable name="attroverride" select="substring(attroverride,string-length(string($attrname))+2)"/>
         @javax.persistence.AttributeOverride( name = "<xsl:value-of select="$attroverride"/>", column = @javax.persistence.Column( name = "<xsl:value-of select="name"/>" ) )
         <xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
       </xsl:for-each>
    } )
  </xsl:template>







  <xsl:template match="attribute|reference|composition" mode="nullable">
    <xsl:choose>
      <xsl:when test="starts-with(multiplicity, '0')">true</xsl:when>
      <xsl:otherwise>false</xsl:otherwise>
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
    <!-- do not remove referenced entity : do not cascade delete -->
    @javax.persistence.ManyToOne( cascade = { javax.persistence.CascadeType.PERSIST, javax.persistence.CascadeType.MERGE, javax.persistence.CascadeType.REFRESH } )
    @javax.persistence.JoinColumn( name = "<xsl:apply-templates select="." mode="columnName"/>", referencedColumnName = "id", nullable = <xsl:apply-templates select="." mode="nullable"/> )
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




  <xsl:template match="reference" mode="JPAAnnotation_reference">
  @javax.persistence.Transient
  </xsl:template>




  <xsl:template match="composition" mode="JPAAnnotation">
    <xsl:variable name="type" select="$models/key('ellookup', datatype/vodml-ref)"/>

    <xsl:choose>
      <xsl:when test="name($type) = 'primitiveType'">
          
      <xsl:variable name="tableName">
        <xsl:apply-templates select=".." mode="tableName"/><xsl:text>_</xsl:text><xsl:value-of select="name"/>
      </xsl:variable>
      <xsl:variable name="columns">
        <xsl:apply-templates select="." mode="columns"/>
      </xsl:variable> 
     <xsl:for-each select="exsl:node-set($columns)/column">
    @javax.persistence.ElementCollection
    @javax.persistence.CollectionTable( name = "<xsl:value-of select="$tableName"/>", joinColumns = @javax.persistence.JoinColumn(name="containerId") )
    @javax.persistence.Column( name = "<xsl:value-of select="name"/>" )
     </xsl:for-each>   
      </xsl:when>
      <xsl:when test="name($type) = 'enumeration' or name($type) = 'dataType'">
/* TODO: [NOT_SUPPORTED_COLLECTION = <xsl:value-of select="name($type)"/>] */
      </xsl:when>
      <xsl:otherwise>
    @javax.persistence.OrderBy( value = "rank" )
    @javax.persistence.OneToMany( cascade = javax.persistence.CascadeType.ALL, fetch = javax.persistence.FetchType.LAZY, mappedBy="id" )
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




  <xsl:template name="enumPattern">
    <xsl:param name="columnName"/>

    @javax.persistence.Basic( optional=<xsl:apply-templates select="." mode="nullable"/> )
    @javax.persistence.Enumerated( javax.persistence.EnumType.STRING )
    @javax.persistence.Column( name = "<xsl:apply-templates select="." mode="columnName"/>", nullable = <xsl:apply-templates select="." mode="nullable"/> )
  </xsl:template>




  <xsl:template match="objectType|dataType" mode="hashcode_equals">
    <xsl:variable name="name" select="name"/>

  /**
   * Returns equals from id attribute here. Child classes can override this method to allow deep equals with
   * attributes / references / collections
   *
   * @param object the reference object with which to compare.
   * @param isDeep true means to call hashCode(sb, true) for all attributes / references / collections which are
   *        MetadataElement implementations
   *
   * @return &lt;code&gt;true&lt;/code&gt; if this object is the same as the obj argument; &lt;code&gt;false&lt;/code&gt; otherwise.
   */
  @Override
  public boolean equals(final Object object, final boolean isDeep) {
    /* identity, nullable, class and identifiers checks */
    if( !(super.equals(object, isDeep))) {
		  return false;
		}

    /* do check values (attributes / references / collections) */  
    <xsl:choose>
      <xsl:when test="name() = 'dataType'">
    if (true) {
      </xsl:when>
      <xsl:otherwise>
    if (isDeep) {
      </xsl:otherwise>
    </xsl:choose>

      final <xsl:value-of select="$name"/> other = (<xsl:value-of select="$name"/>) object;
      <xsl:for-each select="attribute">
        if (! areEquals(this.<xsl:value-of select="name"/>, other.<xsl:value-of select="name"/>)) {
           return false;
        }
		  </xsl:for-each>
    }
		return true;
	}
  </xsl:template>




  <!-- persistence.xml configuration file -->  
  <xsl:template match="vo-dml:model" mode="jpaConfig">
    <xsl:variable name="file" select="'META-INF/persistence.xml'"/>

    <!-- open file for jpa configuration -->
    <xsl:message >Opening file <xsl:value-of select="$file"/></xsl:message>
    <xsl:result-document href="{$file}" format="persistenceInfo">
    <xsl:element name="persistence" namespace="http://java.sun.com/xml/ns/persistence">
      <xsl:attribute name="version" select="'2.0'"/>
      <xsl:element name="persistence-unit" namespace="http://java.sun.com/xml/ns/persistence">
        <xsl:attribute name="name" select="concat('vodml_',name)"/>
        <!-- we rely on eclipselink extensions -->
        <xsl:element name="provider" namespace="http://java.sun.com/xml/ns/persistence">org.eclipse.persistence.jpa.PersistenceProvider</xsl:element>
        <xsl:apply-templates select="*" mode="jpaConfig"/>
        <!--do the other models -->
        <xsl:apply-templates select="$models/vo-dml:model[name != current()/name]/*" mode="jpaConfig"/>
        <xsl:element name="exclude-unlisted-classes" namespace="http://java.sun.com/xml/ns/persistence">true</xsl:element>
      </xsl:element>
    </xsl:element>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="package" mode="jpaConfig" >
    <xsl:apply-templates select="*" mode="jpaConfig"/>
  </xsl:template>

  <xsl:template name="jpaclassdecl">
    <xsl:param name="vodml-ref"/>
    <xsl:element name="class" namespace="http://java.sun.com/xml/ns/persistence">
      <xsl:call-template name="JavaType">
        <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
        <xsl:with-param name="fullpath" select="true()"/>
      </xsl:call-template>
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

  <!-- to deal wth nested datatypes there are various approaches.
  "Simple" nested embeddables/embeddeds are formally nor supported in JPA,
  though some implementors MAY support them. -->


  <!-- Create get/set methods for leaf-attributes in a nested dataType hierarchy.
       This allows mapping such patterns as long as "nested embeddables" are not yet well treated by JPA and/or its implementations. 
   -->
  <xsl:template match="attribute" mode="nestedgetset">
    <xsl:variable name="nested">
      <xsl:apply-templates select="." mode="nested"/>
    </xsl:variable>
    <xsl:for-each select="exsl:node-set($nested)/nested">
      <xsl:variable name="get_prefix">
        <xsl:choose>
          <xsl:when test="nestedMethod_get">
            <xsl:value-of select="concat(nestedMethod_get,'.')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="''"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      @javax.persistence.Column( name = "<xsl:value-of select="name"/>", nullable = <xsl:value-of select="nullable"/> )
      public <xsl:value-of select="javaType"/> get<xsl:value-of select="nestedMethod"/>() {
        return <xsl:value-of select="$get_prefix"/>get<xsl:value-of select="leafName"/>();
      }
      public void set<xsl:value-of select="nestedMethod"/>(<xsl:value-of select="javaType"/> _pValue) {
        <xsl:value-of select="$get_prefix"/>set<xsl:value-of select="leafName"/>(_pValue);
      }
    </xsl:for-each>
  
  </xsl:template>

<!-- 
Return a node-set of columns for a single attribute, which may be structured.
when multiple columns, provide the JPA attribute override information and info for the JPA get/set methods.

NB this implementation does not do the whole work.
It adds the name of the primary attribute to the attriverride variable.
This therefore has to be removed in the jpa.xsl usage of this template.
Should be possible to do thi differently, but TBD.
Note, IF we'd want to add attribute overrides at the start of the class iso at the attribute level,
this would be the appropriate value though!  
!!!!!!!
NOTE this template must be kept in synch with the <match="attribute" mode="columns">
template in common-ddl.xsl 
!!!!!!!
 -->
  <xsl:template match="attribute" mode="nested">
    <xsl:param name="attroverrideprefix"/>
    <xsl:param name="nestedMethodPrefix"/>
    <xsl:param name="nestedMethodPrefix_get"/>
    <xsl:param name="leafName"/>
    <xsl:param name="prefix"/>
    <xsl:param name="utypeprefix"/>
    <xsl:param name="nullable" select="'false'" />

<!--     <xsl:message>Entering attribute/nested, for <xsl:value-of select="name"/></xsl:message> -->


    <xsl:variable name="utype">
      <xsl:value-of select="concat($utypeprefix,'.',name)"/>
    </xsl:variable>

    <xsl:variable name="nameUpper">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="columnname">
      <xsl:choose>
        <xsl:when test="$prefix">
          <xsl:value-of select="concat($prefix,'_',name)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="attroverride">
      <xsl:choose>
        <xsl:when test="$attroverrideprefix">
          <xsl:value-of select="concat($attroverrideprefix,'.',name)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="nestedMethod">
      <xsl:choose>
        <xsl:when test="$nestedMethodPrefix">
          <xsl:value-of select="concat($nestedMethodPrefix,$nameUpper)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$nameUpper"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="nestedMethod_get">
      <xsl:choose>
        <xsl:when test="$nestedMethodPrefix_get">
          <xsl:value-of select="concat($nestedMethodPrefix_get,'.get',$nameUpper,'()')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('get',$nameUpper,'()')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>


    <xsl:variable name="isnullable">
      <xsl:choose>
        <xsl:when test="$nullable='true'">true</xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="multiplicity = '1'">false</xsl:when>
            <xsl:otherwise>true</xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="typeid">
  	  <xsl:value-of select="datatype/vodml-ref" />
  	</xsl:variable>	
    <xsl:variable name="type" select="$models/key('ellookup',$typeid)"/>
<!--        <xsl:message>dataype = <xsl:value-of select="name($type)"/></xsl:message> -->
    <xsl:choose>
      <xsl:when test="name($type) = 'primitiveType' or name($type) = 'enumeration'">
        <xsl:variable name="sqltype">
          <xsl:call-template name="sqltype">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="constraints" select="constraints"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="javaType">
        	<xsl:call-template name="JavaType">
        	  <xsl:with-param name="vodml-ref" select="$typeid"/>
        	</xsl:call-template>
        </xsl:variable>
    
        <nested>
          <attroverride><xsl:value-of select="$attroverride"/></attroverride>
          <nestedMethod><xsl:value-of select="$nestedMethod"/></nestedMethod>
          <nestedMethod_get><xsl:value-of select="$nestedMethodPrefix_get"/></nestedMethod_get>
          <name><xsl:value-of select="$columnname"/></name>
          <type><xsl:value-of select="$type/name"/></type>
          <sqltype><xsl:value-of select="$sqltype"/></sqltype>
          <xsl:copy-of select="constraints"/>
          <xsl:copy-of select="multiplicity"/>
          <description><xsl:value-of select="description"/></description>
          <utype><xsl:value-of select="$utype"/></utype>
          <javaType><xsl:value-of select="$javaType"/></javaType>
          <leafName><xsl:value-of select="$nameUpper"/></leafName>
          <nullable><xsl:value-of select="$isnullable"/></nullable>
        </nested> 
      </xsl:when>
      
      <xsl:when test="name($type) = 'dataType'">
        <xsl:for-each select="$type/attribute">
          <xsl:apply-templates select="." mode="nested">
            <xsl:with-param name="prefix" select="$columnname"/>
            <xsl:with-param name="attroverrideprefix" select="$attroverride"/>
            <xsl:with-param name="nestedMethodPrefix" select="$nestedMethod"/>
            <xsl:with-param name="nestedMethodPrefix_get" select="$nestedMethod_get"/>
            <xsl:with-param name="utypeprefix" select="$utype"/>
            <xsl:with-param name="nullable" select="$isnullable"/>
          </xsl:apply-templates>
        </xsl:for-each>
        
    		<xsl:if test="$models/key('ellookup',//extends[vodml-ref = $typeid]/../vodml-id)">
		      <xsl:message>**** WARNING *** Found subclasses of datatype <xsl:value-of select="name"/>. VO-URP does currently not properly support such patterns properly.</xsl:message>
		    </xsl:if>

      </xsl:when>
      <xsl:otherwise>
        <xsl:message>ERROR in attribute/nested, datatype=<xsl:value-of select="name($type)"/></xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>



</xsl:stylesheet>