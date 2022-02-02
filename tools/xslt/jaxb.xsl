<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<!-- 
  This XSLT is used by intermediate2java.xsl to generate JAXB annotations and JAXB specific java code.
  
  Java 1.8+ is required by JAXB 2.1.
-->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:map="http://www.ivoa.net/xml/vodml-binding/v0.9"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:exsl="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                extension-element-prefixes="exsl">


  <xsl:template match="objectType|dataType" mode="JAXBAnnotation">

  @javax.xml.bind.annotation.XmlAccessorType( javax.xml.bind.annotation.XmlAccessType.NONE )  
  @javax.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
    <xsl:choose>
      <xsl:when test="not(vf:isContained(vf:asvodmlref(.))) and not(@abstract = 'true')">
    @javax.xml.bind.annotation.XmlRootElement( name = "<xsl:value-of select="name"/>")
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="primitiveType" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
  </xsl:template>

<!--
 have removed proporder for now
 -->
  <xsl:template match="objectType|dataType" mode="propOrder">
    <xsl:if test="attribute|composition|reference">
      <xsl:text>,propOrder={
      </xsl:text>
      <!--IMPL this is all a bit long-winded, but keep structure in case want to do something different -->
        <xsl:for-each select="attribute,composition,reference">
        <xsl:variable name="prop">
           <xsl:value-of select="name"/>
        </xsl:variable>
        <xsl:text>"</xsl:text><xsl:value-of select="$prop"/><xsl:text>"</xsl:text><xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
        </xsl:for-each>
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="enumeration" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
    @javax.xml.bind.annotation.XmlEnum
  </xsl:template>

  <!-- template attribute : adds JAXB annotations for primitive types, data types & enumerations -->
  <xsl:template match="attribute|composition[multiplicity/maxOccurs = 1]" mode="JAXBAnnotation">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
    @javax.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
    <xsl:if test="constraint[ends-with(@xsi:type,':NaturalKey')]"><!-- TODO deal with compound keys -->
      @javax.xml.bind.annotation.XmlID
    </xsl:if>
  </xsl:template>

  <!-- reference resolved via JAXB -->
  <xsl:template match="reference" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlIDREF
  </xsl:template>

  <xsl:template match="reference" mode="JAXBAnnotation_reference">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
    @javax.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = Reference.class)
  </xsl:template>

  <xsl:template match="composition[multiplicity/maxOccurs != 1]" mode="JAXBAnnotation">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
    @javax.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
  </xsl:template>

  <xsl:template match="literal" mode="JAXBAnnotation">
    @javax.xml.bind.annotation.XmlEnumValue("<xsl:value-of select="value"/>")
  </xsl:template>

  <xsl:template match="attribute|reference|composition" mode="required">
    <xsl:choose>
      <xsl:when test="starts-with(multiplicity, '0')">false</xsl:when>
      <xsl:otherwise>true</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="vo-dml:model|package" mode="jaxb.index">
    <xsl:param name="dir"/>
    <xsl:variable name="file" select="concat($output_root, '/', $dir, '/jaxb.index')"/>
    <!-- open file for this package -->
    <xsl:message >Writing to jaxb index file <xsl:value-of select="$file"/></xsl:message>

    <xsl:result-document href="{$file}">
      <xsl:if test="local-name() = 'model'">
        <xsl:value-of select="vf:upperFirst(name)"/>Model&cr;
      </xsl:if>
      <xsl:for-each select="objectType|dataType">
        <xsl:value-of select="name"/>&cr;
      </xsl:for-each>
    </xsl:result-document> 
  </xsl:template>

  <xsl:template match="vo-dml:model" mode="modelClass">
    <xsl:param name="root_package_dir"/>
    <xsl:param name="root_package"/>
    <xsl:variable name="file" select="concat($output_root, '/', $root_package_dir, '/',vf:upperFirst(name),'Model.java')"/>
    <!-- open file for this package -->
    <!-- imported model names -->
    <xsl:variable name="modelsInScope" select="(name,vf:importedModelNames(.))"/>
    <xsl:variable name="hasReferences" select="count(distinct-values($models//reference/datatype/vodml-ref[substring-before(.,':') = $modelsInScope]))>0"/>

    <xsl:message >Writing to Overall file <xsl:value-of select="$file"/></xsl:message>
    <xsl:result-document href="{$file}">
    package <xsl:value-of select="$root_package"/>;
    import java.util.List;
    import java.util.Set;
    import java.util.Map;
    import java.util.Collection;
    import java.util.ArrayList;
    import java.util.HashSet;
    import java.util.stream.Collectors;
    import java.util.stream.Stream;
    import java.util.AbstractMap;

    import javax.xml.bind.JAXBContext;
    import javax.xml.bind.annotation.XmlElement;
    import javax.xml.bind.annotation.XmlElements;
    import javax.xml.bind.annotation.XmlRootElement;
    import javax.xml.bind.annotation.XmlType;
    import javax.xml.bind.annotation.XmlAccessType;
    import javax.xml.bind.annotation.XmlAccessorType;
    import javax.xml.bind.JAXBException;

    import org.ivoa.vodml.jaxb.XmlIdManagement;

      @XmlAccessorType(XmlAccessType.NONE)
    @XmlRootElement
    public class <xsl:value-of select="vf:upperFirst(name)"/>Model {

    @XmlType
    public static class References {
    <xsl:for-each select="distinct-values($models//reference/datatype/vodml-ref[substring-before(.,':') = $modelsInScope])"> <!-- looking at all possible refs -->
      @XmlElement
      private Set&lt;<xsl:value-of select="vf:QualifiedJavaType(.)"/>&gt;&bl; <xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/> = new HashSet&lt;&gt;();
    </xsl:for-each>
    }
    @XmlElement
    private References refs = new References();
    <xsl:if test="$hasReferences" >
    @SuppressWarnings("rawtypes")
    private final  Map&lt;Class, Set&gt; refmap = Stream.of(
      <xsl:for-each select="distinct-values($models//reference/datatype/vodml-ref[substring-before(.,':') = $modelsInScope])"> <!-- looking at all possible refs -->
        new AbstractMap.SimpleImmutableEntry&lt;&gt;(<xsl:value-of select="vf:QualifiedJavaType(.)"/>.class, refs.<xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/>)<xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
      ).collect(
      Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    </xsl:if>
    @XmlElements(value = {
      <xsl:for-each select="//objectType[not(@abstract='true') and (not(vf:referredTo(vf:asvodmlref(.))) or (vf:asvodmlref(.) = vf:referencesInHierarchy(vf:asvodmlref(.)) ))]">
        @XmlElement(name="<xsl:value-of select="name"/>",
               type = <xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/>.class)
                    <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
    })
    private List&lt;Object&gt; content  = new ArrayList&lt;&gt;();
      <xsl:for-each select="//objectType[not(@abstract='true') and (not(vf:referredTo(vf:asvodmlref(.))) or (vf:asvodmlref(.) = vf:referencesInHierarchy(vf:asvodmlref(.)) )) ]">
<!--         <xsl:message>ref in hierarchy <xsl:value-of select="vf:asvodmlref(.)"/> refs= <xsl:value-of select="vf:referencesInHierarchy(vf:asvodmlref(.))"/>  </xsl:message>-->
        public void addContent( final <xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/> c)
        {
            content.add(c);

        org.ivoa.vodml.nav.Util.findReferences(c, refmap);

        }
      </xsl:for-each>
      @SuppressWarnings("unchecked")
      public &lt;T&gt; List&lt;T&gt; getContent(Class&lt;T&gt; c) {
      return (List&lt;T&gt;) content.stream().filter(p -> p.getClass().isAssignableFrom(c)).collect(
      Collectors.toList()
      );
      }
      public void makeRefIDsUnique()
      {
      <xsl:if test="$hasReferences">
      List&lt;? extends XmlIdManagement&gt; idrefs =  Stream.of(
      <xsl:for-each select="distinct-values($models//reference/datatype/vodml-ref[substring-before(.,':') = $modelsInScope])"> <!-- looking at all possible refs -->
        refs.<xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/><xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
      ).flatMap(Collection::stream)
      .collect(Collectors.toList());
      org.ivoa.vodml.nav.Util.makeUniqueIDs(idrefs);
      </xsl:if>
      }
      public static boolean hasReferences(){
         return <xsl:value-of select="$hasReferences"/>;
      }

      public static JAXBContext contextFactory()  throws JAXBException
      {
      <xsl:variable name="packages" as="xsd:string*">
        <xsl:apply-templates select="$models" mode="JAXBContext"/>
      </xsl:variable>
         return JAXBContext.newInstance("<xsl:value-of select="string-join($packages,':')"/>" );
      }

  }
    </xsl:result-document>

  </xsl:template>
  <xsl:template match="vo-dml:model|package" mode="JAXBContext">
    <xsl:variable name="jpackage" select="$mapping/map:mappedModels/model[name=current()/ancestor-or-self::vo-dml:model/name]/java-package"/>
    <xsl:value-of select="string-join(($jpackage,ancestor-or-self::package/name),'.')"/>
    <xsl:apply-templates select="package" mode="JAXBContext"/>
  </xsl:template>


</xsl:stylesheet>