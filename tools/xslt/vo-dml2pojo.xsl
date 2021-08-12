<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:exsl="http://exslt.org/common"
                xmlns:map="http://www.ivoa.net/xml/vodml-binding/v0.9"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="map" 
                >

<!-- 
  This XSLT script transforms a data model in VO-DML/XML representation to 
  Purely Ordinary Java Classes.
  
  Only defines fields for components.
  Only argumentless constructor.
  
  Java 1.5+ is required by these two libraries.
-->


  <xsl:import href="common-mapping.xsl"/>
  <xsl:import href="jaxb.xsl"/>
  <xsl:import href="jpa.xsl"/>


  <xsl:output method="text" encoding="UTF-8" indent="yes" />
  <xsl:output name="packageInfo" method="html" encoding="UTF-8" doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"/>

  <xsl:strip-space elements="*" />


  <xsl:param name="lastModified"/>
  <xsl:param name="lastModifiedText"/>
  <xsl:param name="output_root" select="resolve-uri('../gradletooling/sample/src/generated/java/',static-base-uri())"/>
  <xsl:param name="vo-dml_package" select="'net .ivoa.vodml.model'"/>
  <xsl:variable name="mapping" select="." />
  
   
   
  
  
  <!-- next could be parameters -->


  <!-- main pattern : processes for root node model -->
  <xsl:template match="/">
  <xsl:message >Generating Java - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,',')" /></xsl:message>
  <xsl:for-each select="map:mappedModels/todo/model">
  <xsl:message >Model: <xsl:value-of select="."/></xsl:message>
  <xsl:variable name="prefix" select="."/>
  <xsl:choose>
    <xsl:when test="/map:mappedModels/model[name=$prefix]">
      <xsl:apply-templates select="$models/vo-dml:model[name=$prefix]"/>
    </xsl:when>
   <xsl:otherwise>
      <xsl:message>Model <xsl:value-of select="vodml-id"/> not in mapping, hence no Java classes are generated.</xsl:message>
    </xsl:otherwise>
  </xsl:choose>
  </xsl:for-each> 
</xsl:template>

  <!-- model pattern : generates gen-log and processes nodes package and generates the ModelVersion class and persistence.xml -->
  <xsl:template match="vo-dml:model">
    <xsl:message>
-------------------------------------------------------------------------------------------------------
-- Generating Java code for model <xsl:value-of select="name"/> [<xsl:value-of select="title"/>].
-- last modification date of the UML model <xsl:value-of select="$lastModifiedText"/>
-------------------------------------------------------------------------------------------------------
    </xsl:message>

    <xsl:variable name="prefix" select="name"/>
    <xsl:variable name="root_package" select="$mapping/map:mappedModels/model[name=$prefix]/java-package"/>
    <xsl:variable name="root_package_dir" select="replace($root_package,'[.]','/')"/>
<!-- 
    <xsl:message>root_package = <xsl:value-of select="$root_package"/></xsl:message>
    <xsl:message>root_package_dir = <xsl:value-of select="$root_package_dir"/></xsl:message>
 -->
    <xsl:apply-templates select="." mode="modelFactory">
      <xsl:with-param name="root_package" select="$root_package"/>
      <xsl:with-param name="root_package_dir" select="$root_package_dir"/>
    </xsl:apply-templates>

    <xsl:apply-templates select="." mode="content">
      <xsl:with-param name="dir" select="$root_package_dir"/>
      <xsl:with-param name="path" select="$root_package"/>
    </xsl:apply-templates>
    
  </xsl:template>  




  <xsl:template match="vo-dml:model|package" mode="content">
    <xsl:param name="dir"/>
    <xsl:param name="path"/>

    <xsl:variable name="newdir">
      <xsl:choose>
        <xsl:when test="$dir and ./name() = 'package'">
          <xsl:value-of select="concat($dir,'/',name)"/>
        </xsl:when>
        <xsl:when test="$dir and ./name() = 'vo-dml:model'">
          <xsl:value-of select="$dir"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
   
    <xsl:variable name="newpath">
      <xsl:choose>
        <xsl:when test="$path and ./name() = 'package'">
          <xsl:value-of select="concat($path,'.',name)"/>
        </xsl:when>
        <xsl:when test="$path and ./name() = 'vo-dml:model'">
          <xsl:value-of select="$path"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
   
    <xsl:message>package = <xsl:value-of select="$newpath"></xsl:value-of></xsl:message>
   
    <xsl:apply-templates select="." mode="packageDesc">
      <xsl:with-param name="dir" select="$newdir"/>
    </xsl:apply-templates>
   
    <xsl:apply-templates select="objectType|dataType|enumeration|primitiveType" mode="file">
      <xsl:with-param name="dir" select="$newdir"/>
      <xsl:with-param name="path" select="$newpath"/>
    </xsl:apply-templates>

    <xsl:apply-templates select="package" mode="content">
      <xsl:with-param name="dir" select="$newdir"/>
      <xsl:with-param name="path" select="$newpath"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="objectType|dataType|enumeration|primitiveType" mode="file">
    <xsl:param name="dir"/>
    <xsl:param name="path"/>

    <xsl:variable name="vodml-id" select="vodml-id" />
    <xsl:variable name="vodml-ref" select="concat(./ancestor::vo-dml:model/name,':',vodml-id)"/>
    <xsl:variable name="mappedtype">
      <xsl:call-template name="findmappingInThisModel">
        <xsl:with-param name="modelname" select="./ancestor::vo-dml:model/name"/>
        <xsl:with-param name="vodml-id" select="$vodml-id"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
    <xsl:when test="not($mappedtype) or $mappedtype = ''" >
      <xsl:variable name="file" select="concat($output_root, $dir, '/', name, '.java')"/>

    <!-- open file for this class -->
      <xsl:message >Opening Class file <xsl:value-of select="$file"/></xsl:message>
      
      <xsl:result-document href="{$file}">
        <xsl:apply-templates select="." mode="class">
          <xsl:with-param name="path" select="$path"/>
        </xsl:apply-templates>
      </xsl:result-document>
    </xsl:when>
      <xsl:otherwise>
       <xsl:message>1) Mapped type for <xsl:value-of select="$vodml-ref"/> = '<xsl:value-of select="$mappedtype"/>'</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="objectType|dataType|primitiveType|enumeration" mode="typeimports">
    <xsl:variable name="model" select="./ancestor::vo-dml:model"/>
    <xsl:for-each select="distinct-values(extends/vodml-ref|attribute/datatype/vodml-ref|reference/datatype/vodml-ref|composition/datatype/vodml-ref)" >
<!--  TODO filter out types in same package as this type -->    
      <xsl:call-template name="TypeImport">
        <xsl:with-param name="vodml-ref" select="."/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>



  <!-- template class creates a java class (JPA compliant) for UML object & data types -->
  <xsl:template match="objectType|dataType" mode="class">
    <xsl:param name="path"/>    
    <xsl:param name="model" select="./ancestor::vo-dml:model"/>
    
    <xsl:variable name="vodml-id" select="vodml-id"/>
    <xsl:variable name="vodml-ref"><xsl:apply-templates select="vodml-id" mode="asvodml-ref"/></xsl:variable>
    <xsl:variable name="vo-dml-type">
      <xsl:choose>
        <xsl:when test="name() = 'dataType'">DataType</xsl:when>
        <xsl:when test="name() = 'objectType'">ObjectType</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="baseclass">
      <xsl:choose>
        <xsl:when test="name() = 'dataType'"><xsl:value-of select="$vo-dml_package"/>.DataTypeInstance</xsl:when>
        <xsl:when test="name() = 'objectType'"><xsl:value-of select="$vo-dml_package"/>.ObjectTypeInstance</xsl:when>
      </xsl:choose>
    </xsl:variable>
package <xsl:value-of select="$path"/>;

    <!-- imports -->
    <xsl:if test="composition">
      import java.util.List;
      import java.util.ArrayList;
    </xsl:if>
    
    <xsl:if test="not(extends)">
      import <xsl:value-of select="$baseclass"/>;
    </xsl:if>
    <xsl:if test="reference">
      import <xsl:value-of select="$vo-dml_package"/>.ObjectID;
      import <xsl:value-of select="$vo-dml_package"/>.ReferenceObject;
    </xsl:if>
    <xsl:apply-templates select="." mode="typeimports"/>

    /**
    * UML <xsl:value-of select="$vo-dml-type"/>: &bl;<xsl:value-of select="name" />
    *
    * <xsl:apply-templates select="." mode="desc" />
    *
    * @author generated by VO-DML tools <a href="http://volute.g-vo.org/...">VO-DML Home</a>
    * @author Gerard Lemson (mpa)/Laurent Bourges (grenoble)
    */
    
    <xsl:apply-templates select="." mode="JPAAnnotation"/>    
    <xsl:apply-templates select="." mode="JAXBAnnotation"/>
    public&bl;<xsl:if test="@abstract='true'">abstract</xsl:if>&bl;class <xsl:value-of select="name"/>&bl;
    <xsl:choose>
      <xsl:when test="extends">extends <xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="extends/vodml-ref"/></xsl:call-template></xsl:when>
      <xsl:otherwise>extends <xsl:value-of select="$baseclass"/></xsl:otherwise>
    </xsl:choose>
    &bl;{

      /**
       * Return the vodml-id of the VO-DML type represented by this Class.
       */
       @Override
       public String vodmlId()
       {
         return "<xsl:value-of select="vodml-id"/>";
       }
      /**
       * Return the vodml-ref of the VO-DML type represented by this Class.
       */
       @Override
       public String vodmlRef()
       {
         return "<xsl:value-of select="$vodml-ref"/>";
       }
<!-- 
      /** serial uid = last modification date of the UML model */
      private static final long serialVersionUID = LAST_MODIFICATION_DATE;
 -->
      <xsl:apply-templates select="attribute" mode="declare" />
      <xsl:apply-templates select="composition" mode="declare" />
      <xsl:apply-templates select="reference" mode="declare" />
      /**
       * Creates a new <xsl:value-of select="name"/>
       */
      public <xsl:value-of select="name"/>() {
        super();
      }

      <xsl:apply-templates select="attribute|reference|composition" mode="getset"/>

      /**
       * Returns the property value given the property's vodml-ref.<br/>
       * Can be any property (internal, attribute, reference, composition) and all type must be supported (dataType,
       * objectType, enumeration)
       *
       * @param vodmlRef vodml-ref of the property
       *
       * @return property value or null if unknown or not defined
       */
      @Override
      public Object getProperty(final String vodmlRef) {
        // first : checks if vodmlRef is null or empty :
        if (vodmlRef == null) {
          return null;
        }
        // second : search in parent classes (maybe null) :
        Object res = super.getProperty(vodmlRef);
        if(res != null)
          return res;

        <xsl:apply-templates select="attribute|reference|composition"  mode="getProperty" />

        return res;
      }
      /**
       * Sets the property value for the property with the specified vodmlRef.<br/>
       * Can be any property (internal, attribute, reference, composition) and all type must be supported (dataType,
       * objectType, enumeration). Assumes the specified value can be cast to the type of the property!
       *
       * @param vodmlRef vodml-ref of the property (like in UML model)
       *
       * @return true if a property was set, false otherwise
       */
      @Override
      public boolean setProperty(final String vodmlRef, Object pValue) {
        // first : checks if vodmlRef is null or empty :
        if (vodmlRef == null) {
          return false;
        }
        if(super.setProperty(vodmlRef, pValue))
            return true;
        <xsl:apply-templates select="attribute|reference" mode="setProperty" />
<!-- Also set compositions? -->
<!-- 
        <xsl:apply-templates select="attribute|reference" mode="setProperty" />
 -->
        return false;
      }
      /**
       * Sets the property value for the property with the specified vodml-id.<br/>
       * Can be any property (internal, attribute, reference, composition) and all type must be supported (dataType,
       * objectType, enumeration). Assumes the type of the specified object has a constructor accepting a string!
       * Therefore only used for setting primitive attributes.
       *
       * @param vodmlRef fulle vodml-ref of the property
       *
       * @return true if a property was set, false otherwise
       */
      @Override
      public boolean setProperty(final String vodmlRef, String pValue) {
        // first : checks if vodmlRef is null or empty :
        if (vodmlRef == null) {
          return false;
        }

        if(super.setProperty(vodmlRef, pValue))
            return true;
        <xsl:apply-templates select="attribute" mode="setStringProperty" />
        return false;
      }
      
      <xsl:if test="composition">
      
      /**
       * Adds the specified ObjectTypeInstance to the composition with the specified vodmlRef.
       *
       * @param vodmlRef vodml-ref of the composition
       * @param object ObjectType instance to be added
       * @return true if object was added was set, false otherwise
       */
      @Override
      public boolean add2composition(final String vodmlRef, <xsl:value-of select="$vo-dml_package"/>.ObjectTypeInstance object) {
        // first : checks if vodmlRef is null or empty :
        if (vodmlRef == null) {
          return false;
        }

        if(super.add2composition(vodmlRef, object))
            return true;
        <xsl:apply-templates select="composition" mode="add2composition" />
        return false;
      }
      </xsl:if>
      
      <xsl:apply-templates select="." mode="toString"/>
}
  </xsl:template>




  <xsl:template match="enumeration" mode="class">
    <xsl:param name="dir"/>
    <xsl:param name="path"/>
package <xsl:value-of select="$path"/>;

      /**
      * UML Enumeration <xsl:value-of select="name"/> :
      *
      * <xsl:apply-templates select="." mode="desc" />
      *
      * @author generated by VO-DML tools <a href="http://code.google.com/p/vo-urp/">VO-URP Home</a>
      * @author Laurent Bourges (...) / Gerard Lemson (mpa)
      */
      public enum <xsl:value-of select="name"/>&bl;{

        <xsl:apply-templates select="literal"  />

        /** string representation */
        private final String value;

        /**
         * Creates a new <xsl:value-of select="name"/> Enumeration Literal
         *
         * @param v string representation
         */
        <xsl:value-of select="name"/>(final String v) {
            value = v;
        }

        /**
         * Return the string representation of this enum constant (value)
         * @return string representation of this enum constant (value)
         */
        public final String value() {
            return this.value;
        }

        /**
         * Return the string representation of this enum constant (value)
         * @see #value()
         * @return string representation of this enum constant (value)
         */
        @Override
        public final String toString() {
            return value();
        }

        /**
         * Return the <xsl:value-of select="name"/> enum constant corresponding to the given string representation (value)
         *
         * @param v string representation (value)
         *
         * @return <xsl:value-of select="name"/> enum constant
         *
         * @throws IllegalArgumentException if there is no matching enum constant
         */
        public final static <xsl:value-of select="name"/> fromValue(final String v) {
          for (<xsl:value-of select="name"/> c : <xsl:value-of select="name"/>.values()) {
              if (c.value.equals(v)) {
                  return c;
              }
          }
          throw new IllegalArgumentException("<xsl:value-of select="name"/>.fromValue : No enum const for the value : " + v);
        }
      /**
       * Return the vodmlId of the VO-DML type represented by this Class.
       */
       public String vodmlId()
       {
         return "<xsl:value-of select="vodml-id"/>";
       }
      /**
       * Return the uytpe of the VO-DML type represented by this Enumeration.
       */
       public String vodmlRef()
       {
         return "<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>";
       }

      }
  </xsl:template>

  <xsl:template match="primitiveType" mode="class">
    <xsl:param name="path"/>

    <xsl:variable name="valuetype">
      <xsl:choose>
        <xsl:when test="extends">
          <xsl:call-template name="JavaType">
            <xsl:with-param name="vodml-ref" select="extends/vodml-ref"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
        <xsl:value-of select="'Object'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
package <xsl:value-of select="$path"/>;
        <xsl:apply-templates select="." mode="typeimports" />


      /**
      * UML PrimitiveType <xsl:value-of select="name"/> :  
      * <xsl:apply-templates select="." mode="desc" />
      *
      * @author generated by VO-URP tools <a href="http://code.google.com/p/vo-urp/">VO-URP Home</a>
      * @author Laurent Bourges (voparis) / Gerard Lemson (mpe)
      */
      public class <xsl:value-of select="name"/>&bl;{

        /** string representation */
        private final <xsl:value-of select="$valuetype"/> value;

        /**
         * Creates a new <xsl:value-of select="name"/> Primitive Type instance, wrapping a base type.
         *
         * @param v 
         */
        public <xsl:value-of select="name"/>(final <xsl:value-of select="$valuetype"/> v) {
            this.value = v;
        }

        /**
         * Return the string representation of this enum constant (value)
         * @return string representation of this enum constant (value)
         */
        public final <xsl:value-of select="$valuetype"/> value() {
            return this.value;
        }

        /**
         * Return the string representation of this enum constant (value)
         * @see #value()
         * @return string representation of this enum constant (value)
         */
        @Override
        public final String toString() {
            return value().toString();
        }
              
      /**
       * Return the vodml-id of the VO-DML type represented by this Class.
       */
       public String vodmlId()
       {
         return "<xsl:value-of select="vodml-id"/>";
       }
      /**
       * Return the vodml-ref of the VO-DML type represented by this Class.
       */
       public String vodmlRef()
       {
         return "<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>";
       }
        
      }
  </xsl:template>


  <xsl:template match="attribute" mode="declare">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    /** 
    * Attribute <xsl:value-of select="name"/> :
    * <xsl:apply-templates select="." mode="desc" />
    */
    <xsl:apply-templates select="." mode="JPAAnnotation"/>
    <xsl:apply-templates select="." mode="JAXBAnnotation"/>
    private <xsl:value-of select="$type"/><xsl:if test="contains(multiplicity,'*')">[]</xsl:if>&bl;<xsl:value-of select="name"/>;
  </xsl:template>




  <xsl:template match="attribute" mode="getset">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    /**
    * Returns <xsl:value-of select="name"/> Attribute
    * @return <xsl:value-of select="name"/> Attribute
    */
    public <xsl:value-of select="$type"/><xsl:if test="contains(multiplicity,'*')">[]</xsl:if>&bl;get<xsl:value-of select="$name"/>() {
    return this.<xsl:value-of select="name"/>;
    }
    /**
    * Defines <xsl:value-of select="name"/> Attribute
    * @param p<xsl:value-of select="$name"/> value to set
    */
    public void set<xsl:value-of select="$name"/>(final <xsl:value-of select="$type"/><xsl:if test="contains(multiplicity,'*')">[]</xsl:if> p<xsl:value-of select="$name"/>) {
    this.<xsl:value-of select="name"/> = p<xsl:value-of select="$name"/>;
    }
<!-- uncomment next if we decide to try out property access for nested embeddables. -->
<!-- 
    <xsl:variable name="datatype" select="key('element',datatype/vodml-ref)"/>
    <xsl:if test="../name() = 'dataType' and name($datatype) = 'dataType'">
      <xsl:apply-templates select="." mode="nestedgetset"/>
    </xsl:if> 
 -->
   </xsl:template>

  <xsl:template match="attribute" mode="setProperty">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    if ("<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>".equals(vodmlRef)) {
      set<xsl:value-of select="$name"/>((<xsl:value-of select="$type"/><xsl:if test="contains(multiplicity,'*')">[]</xsl:if>)pValue);
      return true;
    }
  </xsl:template>

  <xsl:template match="attribute" mode="setStringProperty">
    <xsl:variable name="type"><xsl:call-template name="JavaType">
    <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
    </xsl:call-template></xsl:variable>
    <xsl:variable name="element" as="element()"><xsl:call-template name="Element4vodml-ref">
    <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
    </xsl:call-template></xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$element/name() = 'enumeration' or $element/name() = 'primitiveType'">
    if ("<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>".equals(vodmlRef)) {
     <xsl:choose>
       <xsl:when test="$element/name() = 'enumeration'">
             set<xsl:value-of select="$name"/>(<xsl:value-of select="$type"/>.fromValue(pValue));
       </xsl:when>
       <xsl:otherwise>
      set<xsl:value-of select="$name"/>(new <xsl:value-of select="$type"/>(pValue));
       </xsl:otherwise>
     </xsl:choose>
      return true;
    }
    </xsl:if>
  </xsl:template>



  <xsl:template match="composition" mode="declare">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    <xsl:if test="not(subsets)">
    /** 
    * composition <xsl:value-of select="name"/> :
    * <xsl:apply-templates select="." mode="desc" />
    * (
    * Multiplicity : <xsl:value-of select="multiplicity"/>
    * )
    */
    private List&lt;<xsl:value-of select="$type"/>&gt;&bl;<xsl:value-of select="name"/> = null;
    </xsl:if>
  </xsl:template>



<!-- define methods for getting/setting and adding to composition -->
  <xsl:template match="composition" mode="getset">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="datatype" select="substring-after(datatype/vodml-ref,':')"/>
    
    <xsl:if test="not(subsets)">
    /**
    * Returns <xsl:value-of select="name"/> composition
    * @return <xsl:value-of select="name"/> composition
    */
    public List&lt;<xsl:value-of select="$type"/>&gt;&bl;get<xsl:value-of select="$name"/>() {
    return this.<xsl:value-of select="name"/>;
    }
    /**
    * Defines <xsl:value-of select="name"/> composition
    * @param p<xsl:value-of select="$name"/> composition to set
    */
    public void set<xsl:value-of select="$name"/>(final List&lt;<xsl:value-of select="$type"/>&gt; p<xsl:value-of select="$name"/>) {
    this.<xsl:value-of select="name"/> = p<xsl:value-of select="$name"/>;
    }
    /**
    * Add a <xsl:value-of select="$type"/> to the composition
    * Note: if the composition is big, set the rank value before adding the item to the composition
    * @param p<xsl:value-of select="$type"/>&bl;<xsl:value-of select="$type"/> to add
    */
    public void add<xsl:value-of select="$name"/>(final <xsl:value-of select="$type"/> p<xsl:value-of select="$type"/>) {
      if(this.<xsl:value-of select="name"/> == null) {
        this.<xsl:value-of select="name"/> = new ArrayList&lt;<xsl:value-of select="$type"/>&gt;();
      }

    <xsl:if test="$datatype = 'objectType'"> <!-- FIXME ???-->
      /* define the rank value (composition ordering position) if undefined */
      if (p<xsl:value-of select="$type"/>.getRank() == -1) {
        /* the call to size() method on lazy composition has the side effect
         * to fetch the complete composition : it is a performance problem
         * if the composition is really big.
         * Workaround : set the rank value before adding the item to the composition
         */
        final int idx = this.<xsl:value-of select="name"/>.size();
        p<xsl:value-of select="$type"/>.setRank(idx);
      }
    </xsl:if>

      this.<xsl:value-of select="name"/>.add(p<xsl:value-of select="$type"/>);
      p<xsl:value-of select="$type"/>.setContainer(this);
      
    }
    </xsl:if>
  </xsl:template>

  <xsl:template match="composition" mode="add2composition">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    if ("<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>".equals(vodmlRef)) {
      add<xsl:value-of select="$name"/>((<xsl:value-of select="$type"/>)object);
      return true;
    }
  </xsl:template>



  <xsl:template match="reference" mode="declare">
  <xsl:if test="not(subsets)">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    /** 
    * ReferenceObject <xsl:value-of select="name"/> :
    * <xsl:apply-templates select="." mode="desc" />
    * (
    * Multiplicity : <xsl:value-of select="multiplicity"/>
    * )
    */
    <xsl:apply-templates select="." mode="JPAAnnotation"/>
    <xsl:apply-templates select="." mode="JAXBAnnotation"/>
    private <xsl:value-of select="$type"/>&bl;<xsl:value-of select="name"/> = null;
    private ReferenceObject&bl;_ref_<xsl:value-of select="name"/> = null;
    </xsl:if>
  </xsl:template>




  <xsl:template match="reference" mode="getset">
    <xsl:variable name="type">
      <xsl:call-template name="JavaType">
        <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    /**
    * Returns <xsl:value-of select="name"/> Reference<br/>
    * @return <xsl:value-of select="name"/> Reference
    */
    public <xsl:value-of select="$type"/>&bl;get<xsl:value-of select="$name"/>() {
    <xsl:choose>
      <xsl:when test="subsets">
        return (<xsl:value-of select="$type"/>)super.get<xsl:value-of select="$name"/>();
      </xsl:when>
      <xsl:otherwise>
        return this.<xsl:value-of select="name"/>;
      </xsl:otherwise>
    </xsl:choose>
    }
    /**
    * Defines <xsl:value-of select="name"/> Reference
    * @param p<xsl:value-of select="$name"/> reference to set
    */
    public void set<xsl:value-of select="$name"/>(final <xsl:value-of select="$type"/> p<xsl:value-of select="$name"/>) {
    <xsl:choose>
      <xsl:when test="subsets">
        super.set<xsl:value-of select="$name"/>(p<xsl:value-of select="$name"/>);
      </xsl:when>
      <xsl:otherwise>
        this.<xsl:value-of select="name"/> = p<xsl:value-of select="$name"/>;
      </xsl:otherwise>
    </xsl:choose>
    }
    /**
    * Defines <xsl:value-of select="name"/> Reference
    * @param p<xsl:value-of select="$name"/> reference to set
    */
    public void set<xsl:value-of select="$name"/>(final ReferenceObject p<xsl:value-of select="$name"/>) {
    <xsl:choose>
      <xsl:when test="subsets">
        super.set<xsl:value-of select="$name"/>(p<xsl:value-of select="$name"/>);
      </xsl:when>
      <xsl:otherwise>
        this._ref_<xsl:value-of select="name"/> = p<xsl:value-of select="$name"/>;
        p<xsl:value-of select="$name"/>.setOwner(this);
      </xsl:otherwise>
    </xsl:choose>
    }
  </xsl:template>




  <xsl:template match="reference" mode="setProperty">
    <xsl:variable name="type"><xsl:call-template name="JavaType"><xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/></xsl:call-template></xsl:variable>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>

    if ("<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>".equals(vodmlRef)) {
      if(pValue instanceof ReferenceObject)
        set<xsl:value-of select="$name"/>((ReferenceObject)pValue);
      else 
        set<xsl:value-of select="$name"/>((<xsl:value-of select="$type"/>)pValue);
      return true;
    }
  </xsl:template>

  <xsl:template match="literal" >
    /** 
    * Value <xsl:value-of select="name"/> :
    * 
    * <xsl:apply-templates select="." mode="desc" />
    */
    <xsl:variable name="up">
      <xsl:call-template name="constant">
        <xsl:with-param name="text" select="name"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:value-of select="$up"/>("<xsl:value-of select="name"/>")
    <xsl:choose>
      <xsl:when test="position() != last()"><xsl:text>,</xsl:text></xsl:when>
      <xsl:otherwise><xsl:text>;</xsl:text></xsl:otherwise>
    </xsl:choose>
    &cr;
  </xsl:template>


  <xsl:template match="attribute|reference|composition" mode="getProperty">
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    if ("<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>".equals(vodmlRef)) {
      return get<xsl:value-of select="$name"/>();
    }
  </xsl:template>




  <xsl:template match="*" mode="desc">
    <xsl:choose>
      <xsl:when test="count(description) > 0 and normalize-space(description) != 'TODO : Missing description : please, update your UML model asap.'"><xsl:value-of select="description" disable-output-escaping="yes"/></xsl:when>
      <xsl:otherwise>
<!--       <xsl:message >TODO : <xsl:value-of select="name"/> Missing description : please, update your VO-DML model asap.</xsl:message> -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>  




  <!-- specific documents --> 

  <!-- ModelVersion.java -->
  <xsl:template match="vo-dml:model" mode="modelFactory">
    <xsl:param name="root_package"/>
    <xsl:param name="root_package_dir"/>
    <xsl:variable name="file" select="concat($output_root, $root_package_dir,'/','ModelFactory.java')"/>
    <!-- open file for this class -->
    <xsl:message >Opening Factory file <xsl:value-of select="$file"/></xsl:message>
    <xsl:result-document href="{$file}">package <xsl:value-of select="$root_package"/>;
      <xsl:if test="descendant-or-self::objectType|descendant-or-self::dataType">
      import <xsl:value-of select="$vo-dml_package"/>.StructuredObject;
      </xsl:if>
      /**
      * Factory class for <xsl:value-of select="name"/> :
      *
      * <xsl:apply-templates select="." mode="desc" />
      *
      * @author generated by VO-URP tools <a href="http://code.google.com/p/vo-urp/">VO-URP Home</a>
      * @author Laurent Bourges (voparis) / Gerard Lemson (mpe)
      */
      public class ModelFactory extends <xsl:value-of select="$vo-dml_package"/>.ModelFactory { 

        /** last modification date of the VODML model */
        public final static String LAST_MODIFICATION_DATE = "<xsl:value-of select="lastModified"/>";

        <xsl:if test="descendant-or-self::objectType|descendant-or-self::dataType">
        @Override
        public StructuredObject newStructuredObject(String vodmlRef)
        {
          if(vodmlRef == null)
            return null;
          <xsl:for-each select="descendant-or-self::objectType|descendant-or-self::dataType" >
          <xsl:if test="not(@abstract = 'true')">
            <xsl:variable name="vodml-ref"><xsl:apply-templates select="vodml-id" mode="asvodml-ref"/></xsl:variable>
            <xsl:variable name="type">
              <xsl:call-template name="JavaType">
                <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
                <xsl:with-param name="fullpath" select="'true'"/>
              </xsl:call-template>
            </xsl:variable>
           else if("<xsl:value-of select="$vodml-ref"/>".equals(vodmlRef))
            return new <xsl:value-of select="$type"/>();
            </xsl:if>
          </xsl:for-each>  
          return null;
        }
        </xsl:if>
        <xsl:if test="descendant-or-self::enumeration">
        @Override
        public Object newEnumeratedValue(String vodmlRef, String value)
        {
          if(vodmlRef == null)
            return null;
          <xsl:for-each select="descendant-or-self::enumeration">
            <xsl:variable name="vodml-ref" select="concat(./ancestor::vo-dml:model/name,':',vodml-id)"/>
          <xsl:if test="not(@abstract = 'true')">
          else if("<xsl:value-of select="$vodml-ref"/>".equals(vodmlRef))
            return <xsl:apply-templates select="." mode="path"/>.fromValue(value);
            </xsl:if>
          </xsl:for-each>  
          return null;
        }
        </xsl:if>
        <xsl:if test="descendant-or-self::primitiveType">
        @Override
        public Object newPrimitiveValue(String vodmlRef, String value)
        {
          if(vodmlRef == null)
            return null;
          <xsl:for-each select="descendant-or-self::primitiveType">
            <xsl:variable name="vodml-ref" select="concat(./ancestor::vo-dml:model/name,':',vodml-id)"/>
            <xsl:variable name="type">
              <xsl:call-template name="JavaType">
                <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
                <xsl:with-param name="fullpath" select="'true'"/>
              </xsl:call-template>
            </xsl:variable>
          else if("<xsl:value-of select="$vodml-ref"/>".equals(vodmlRef))
            return new <xsl:value-of select="$type"/>(value);
          </xsl:for-each>  
          return null;
        }
        </xsl:if>
      }
    </xsl:result-document>
  </xsl:template>




  <!-- package.html -->
  <xsl:template match="vo-dml:model|package" mode="packageDesc">
    <xsl:param name="dir"/>
    <xsl:variable name="file" select="concat($output_root,$dir,'/package.html')"/>
    <!-- open file for this class -->
    <xsl:message >Opening package file <xsl:value-of select="$file"/></xsl:message>
    <xsl:result-document href="{$file}" format="packageInfo">
      <html>
        <head>
          <title>Package Information</title>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        </head>
        <body>&cr;
          <xsl:apply-templates select="." mode="desc" />
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>


  <xsl:template name="TypeImport">
    <xsl:param name="vodml-ref"/>
 <!--
        <xsl:message>Looking for vodml-ref <xsl:value-of select="$vodml-ref"/></xsl:message>
 -->    
    <xsl:variable name="vodml-id" select="substring-after($vodml-ref,':')"/>
    <xsl:variable name="mappedtype">
      <xsl:call-template name="findmapping">
        <xsl:with-param name="vodml-ref" select="$vodml-ref"/>
      </xsl:call-template>
    </xsl:variable>
<!--     <xsl:message>TypeImprt: mappedtype =  "<xsl:value-of select="$mappedtype"/>"</xsl:message> -->
   <xsl:choose>
      <xsl:when test="$mappedtype != ''">
<!--          <xsl:message>TypeImprt: found mapping for <xsl:value-of select="$vodml-ref"/>, no import necessary</xsl:message> -->
      </xsl:when>
      <xsl:otherwise>
<!--          <xsl:message>TypeImprt: building import for <xsl:value-of select="$vodml-ref" /></xsl:message> -->
         <xsl:variable name="themodel" as="element()">
            <xsl:call-template name="getmodel">
               <xsl:with-param name="vodml-ref" select="$vodml-ref" />
            </xsl:call-template>
         </xsl:variable>
<!--          <xsl:message>TypeImprt: looking for <xsl:value-of select="$vodml-ref" /> in model = <xsl:value-of select="$themodel/name" /></xsl:message> -->
         <xsl:variable name="type" as="element()" select="$themodel//*[vodml-id = $vodml-id]" />
         <xsl:variable name="path">
            <xsl:call-template name="package-path">
               <xsl:with-param name="model" select="$themodel" />
               <xsl:with-param name="packageid">
                  <xsl:value-of select="$type/../vodml-id" />
               </xsl:with-param>
               <xsl:with-param name="delimiter">.</xsl:with-param>
            </xsl:call-template>
         </xsl:variable>
         <xsl:variable name="root" select="$mapping/map:mappedModels/model[name=$themodel/name]/java-package" />
         import <xsl:value-of select="$root" /><xsl:if test="$path !=''">.</xsl:if><xsl:value-of select="$path" />.<xsl:value-of select="$type/name" />;
      </xsl:otherwise>
   </xsl:choose>
  </xsl:template> 
  
  <xsl:template match="objectType|dataType|enumeration|primitiveType" mode="path">
    <xsl:variable name="modelname" select="./ancestor::vo-dml:model/name"/>
    
    <xsl:message >Looking for path for <xsl:value-of select="vodml-id"/> in model <xsl:value-of select="$modelname"/>
    </xsl:message>

     <xsl:variable name="path" >
      <xsl:call-template name="package-path">
        <xsl:with-param name="model" select="./ancestor::vo-dml:model"/>
        <xsl:with-param name="packageid"><xsl:value-of select="./../vodml-id"/></xsl:with-param>
        <xsl:with-param name="delimiter">.</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="root" select="$mapping/map:mappedModels/model[name=$modelname]/java-package"/>
    <xsl:value-of select="$root"/><xsl:if test="$path !=''">.</xsl:if><xsl:value-of select="$path"/>.<xsl:value-of select="name"/>
  </xsl:template>
  
  


  <!-- deepToString methods -->
  <xsl:template match="objectType|dataType" mode="toString">
    <xsl:if test="attribute">
    <xsl:apply-templates select="." mode="attributesToString"/>
    </xsl:if>
    <xsl:if test="reference[not(subsets)]">
      <xsl:apply-templates select="." mode="referencesToString"/>
    </xsl:if>
    <xsl:if test="composition[not(subsets)]">
      <xsl:apply-templates select="." mode="compositionsToString"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="objectType|dataType" mode="attributesToString">
      /**
       * Puts the string representation of the attributes in the given string buffer : &lt;br&gt; 
       *
       * @param sb given string buffer to fill
       * @return stringbuffer the given string buffer filled with the string representation
       */
      @Override
      public void attributesToString(final StringBuilder sb, String offset) {
        super.attributesToString(sb, offset);
        String newoffset = offset+"  ";
        Object v = null;
        <xsl:for-each select="attribute">
            <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
          <xsl:variable name="element" as="element()">
            <xsl:call-template name="Element4vodml-ref" >
              <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
            </xsl:call-template>
          </xsl:variable>
          v = get<xsl:value-of select="$name"/>();
          if(v != null)
          {
        sb.append(offset).append("&lt;attribute&bl;vodmlRef=\"<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>\" name=\"<xsl:value-of select="name"/>\"&gt;").append(NEWLINE);
          <xsl:choose>
            <xsl:when test="$element/name() = 'primitiveType' or $element/name() = 'enumeration'">
              atomicToString("<xsl:value-of select="datatype/vodml-ref"/>",v, sb,newoffset);
              sb.append(NEWLINE);
            </xsl:when>            
            <xsl:otherwise>
            ((<xsl:value-of select="$vo-dml_package"/>.DataTypeInstance)v).deepToString(sb, newoffset);
            </xsl:otherwise>
          </xsl:choose> 
        sb.append(offset).append("&lt;/attribute&gt;").append(NEWLINE);
        }
        </xsl:for-each>
      }
      </xsl:template>
  <xsl:template match="objectType|dataType" mode="referencesToString">
  
      /**
       * Puts the string representation of the attributes in the given string buffer : &lt;br&gt; 
       *
       * @param sb given string buffer to fill
       * @return stringbuffer the given string buffer filled with the string representation
       */
      @Override
      public void referencesToString(final StringBuilder sb, String offset) {
        super.referencesToString(sb, offset);
        String newoffset = offset+"  ";
        Object v = null;
        <xsl:for-each select="reference[not(subsets)]">
          <xsl:variable name="element" as="element()">
            <xsl:call-template name="Element4vodml-ref" >
              <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
            </xsl:call-template>
          </xsl:variable>
          v = getProperty("<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>");
          if(v != null)
          {
            sb.append(offset).append("&lt;reference&bl;vodmlRef=\"<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>\" name=\"<xsl:value-of select="name"/>\"");
            sb.append(" type=\"").append(((<xsl:value-of select="$vo-dml_package"/>.ObjectTypeInstance)v).vodmlRef()).append("\"&gt;");
            ObjectID id = ((<xsl:value-of select="$vo-dml_package"/>.ObjectTypeInstance)v).get_ID();
            if(id != null)
              id.deepToString(sb, newoffset);
            sb.append("&lt;/reference&gt;").append(NEWLINE);
          }
        </xsl:for-each>
      }
      </xsl:template>


  <xsl:template match="objectType|dataType" mode="compositionsToString">
      /**
       * Puts the string representation of the attributes in the given string buffer : &lt;br&gt; 
       *
       * @param sb given string buffer to fill
       * @return stringbuffer the given string buffer filled with the string representation
       */
      @Override
      public void compositionsToString(final StringBuilder sb, String offset) {
        super.compositionsToString(sb, offset);
        String newoffset = offset+"  ";
        <xsl:for-each select="composition[not(subsets)]">
          <xsl:variable name="element" as="element()">
            <xsl:call-template name="Element4vodml-ref" >
              <xsl:with-param name="vodml-ref" select="datatype/vodml-ref"/>
            </xsl:call-template>
          </xsl:variable>
          if(<xsl:value-of select="name"/> != null)
          {
            sb.append(offset).append("&lt;composition&bl;vodmlRef=\"<xsl:apply-templates select="vodml-id" mode="asvodml-ref"/>\" name=\"<xsl:value-of select="name"/>\"&gt;");
            for(<xsl:value-of select="$vo-dml_package"/>.ObjectTypeInstance o: <xsl:value-of select="name"/>){
                sb.append(NEWLINE);
                o.deepToString(sb, newoffset);
            }
            sb.append(offset).append("&lt;/composition&gt;").append(NEWLINE);
          }
        </xsl:for-each>
      }
  
  </xsl:template>

  <!-- Find a mapping for the given vodml-id, in the provided model -->
  <xsl:template name="findmappingInThisModel">
    <xsl:param name="modelname"/>
    <xsl:param name="vodml-id"/>
        <xsl:value-of select="$mapping/map:mappedModels/model[name=$modelname]/type-mapping[vodml-id=$vodml-id]/java-type"/>
  </xsl:template>

  <xsl:template name="findmapping">
    <xsl:param name="vodml-ref"/>
    <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
    <xsl:value-of select="$mapping/map:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/java-type"/>
  </xsl:template>

  <!-- find a java package path towards the type identified with the name -->
  <xsl:template name="fullpath">
    <xsl:param name="vodml-ref"/>
    <xsl:variable name="themodel" as="element()">
        <xsl:call-template name="getmodel"><xsl:with-param name="vodml-ref" select="$vodml-ref"/></xsl:call-template>
    </xsl:variable>

    <xsl:variable name="root" select="$mapping/map:mappedModels/model[name=$themodel/name]/java-package"/>

    <xsl:variable name="vodmlid" select="substring-after($vodml-ref,':' )"/>    
    <xsl:variable name="path">
    <xsl:for-each select="$themodel//*[vodml-id=$vodmlid]/ancestor-or-self::*[name() != 'vo-dml:model']">
       <xsl:value-of select="./name"/>
       <xsl:if test="position() != last()">
       <xsl:text>.</xsl:text>
       </xsl:if>
    </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="concat($root,'.',$path)"/>

  </xsl:template>



</xsl:stylesheet>
