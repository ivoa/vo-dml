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

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:exsl="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                extension-element-prefixes="exsl">


  <xsl:variable name="jsontypinfo">
  @com.fasterxml.jackson.databind.annotation.JsonTypeIdResolver(value = org.ivoa.vodml.json.VodmlTypeResolver.class)
   //   @com.fasterxml.jackson.annotation.JsonTypeInfo (use = com.fasterxml.jackson.annotation.JsonTypeInfo.Id.NAME, include = com.fasterxml.jackson.annotation.JsonTypeInfo.As.WRAPPER_OBJECT )
  @com.fasterxml.jackson.annotation.JsonTypeInfo (use = com.fasterxml.jackson.annotation.JsonTypeInfo.Id.NAME, include = com.fasterxml.jackson.annotation.JsonTypeInfo.As.PROPERTY,property = "@type" )
  </xsl:variable>

  <xsl:template match="objectType|dataType" mode="JAXBAnnotation">

  @jakarta.xml.bind.annotation.XmlAccessorType( jakarta.xml.bind.annotation.XmlAccessType.NONE )
  @jakarta.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
  <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>
  <xsl:choose>
      <xsl:when test="vf:hasSubTypes($vodml-ref)"> <!-- TODO perhaps only necessary if abstract -->
  @jakarta.xml.bind.annotation.XmlSeeAlso({ <xsl:value-of select="string-join(for $s in vf:subTypes($vodml-ref) return concat(vf:QualifiedJavaType(vf:asvodmlref($s)),'.class'),',')"/>  })
  @com.fasterxml.jackson.annotation.JsonSubTypes({
          <xsl:value-of select="string-join(for $s in vf:subTypes($vodml-ref) return
              concat('@com.fasterxml.jackson.annotation.JsonSubTypes.Type(value=',vf:QualifiedJavaType(vf:asvodmlref($s)),'.class,name=&quot;',vf:utype(vf:asvodmlref($s)),'&quot;)'),',')"/>
  })
          <xsl:value-of select="$jsontypinfo" />
      </xsl:when>
      <xsl:otherwise>
          <xsl:choose>
              <xsl:when test="extends">
@com.fasterxml.jackson.annotation.JsonTypeInfo (use = com.fasterxml.jackson.annotation.JsonTypeInfo.Id.NAME )
              </xsl:when>
              <xsl:otherwise>
@com.fasterxml.jackson.annotation.JsonTypeInfo (use = com.fasterxml.jackson.annotation.JsonTypeInfo.Id.NONE )
              </xsl:otherwise>
          </xsl:choose>
      </xsl:otherwise>
  </xsl:choose>

    <xsl:choose>
      <xsl:when test="not(vf:isContained(vf:asvodmlref(.))) and not(@abstract = 'true')">
 //   @jakarta.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>")
      </xsl:when>
     </xsl:choose>
      <xsl:if test="vf:referredTo(vf:asvodmlref(.)) and not(extends)">
          <xsl:choose>
              <xsl:when test="attribute/constraint[ends-with(@xsi:type,':NaturalKey')]">
  @com.fasterxml.jackson.annotation.JsonIdentityInfo(property = "<xsl:value-of select="attribute/constraint[ends-with(@xsi:type,':NaturalKey')]/preceding-sibling::name"/>", generator = com.fasterxml.jackson.annotation.ObjectIdGenerators.PropertyGenerator.class, scope=<xsl:value-of select="vf:QualifiedJavaType($vodml-ref)"/>.class )
              </xsl:when>
              <xsl:otherwise>
  @com.fasterxml.jackson.annotation.JsonIdentityInfo(property = "_id", generator = com.fasterxml.jackson.annotation.ObjectIdGenerators.PropertyGenerator.class, scope=<xsl:value-of select="vf:QualifiedJavaType($vodml-ref)"/>.class )
              </xsl:otherwise>
          </xsl:choose>
      </xsl:if>
  </xsl:template>

  <xsl:template match="primitiveType" mode="JAXBAnnotation">
    @jakarta.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
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
    @jakarta.xml.bind.annotation.XmlType( name = "<xsl:value-of select="name"/>")
    @jakarta.xml.bind.annotation.XmlEnum
  </xsl:template>

  <!-- template attribute : adds JAXB annotations for primitive types, data types & enumerations -->
  <xsl:template match="attribute|composition[multiplicity/maxOccurs = 1]" mode="JAXBAnnotation">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
      <xsl:if test="$models/key('ellookup',current()/datatype/vodml-ref)/name() != 'primitiveType' and ($models/key('ellookup',current()/datatype/vodml-ref)/@abstract or vf:hasSubTypes(current()/datatype/vodml-ref))">
       <xsl:value-of select="$jsontypinfo"/>
      </xsl:if>
    @jakarta.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
    <xsl:if test="constraint[ends-with(@xsi:type,':NaturalKey')]"><!-- TODO deal with compound keys -->
    @jakarta.xml.bind.annotation.XmlID
    </xsl:if>
  </xsl:template>

  <!-- reference resolved via JAXB -->
  <xsl:template match="reference" mode="JAXBAnnotation">
      <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
      <xsl:if test="$models/key('ellookup',current()/datatype/vodml-ref)/@abstract or vf:hasSubTypes(current()/datatype/vodml-ref)">
          <xsl:value-of select="$jsontypinfo"/>
      </xsl:if>
    @jakarta.xml.bind.annotation.XmlIDREF
  </xsl:template>

  <xsl:template match="reference" mode="JAXBAnnotation_reference">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
    @jakarta.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = Reference.class)
  </xsl:template>

  <xsl:template match="composition[multiplicity/maxOccurs != 1]" mode="JAXBAnnotation">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
  @jakarta.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required = <xsl:apply-templates select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
      <xsl:if test="$models/key('ellookup',current()/datatype/vodml-ref)/@abstract or vf:hasSubTypes(current()/datatype/vodml-ref)">
       <xsl:value-of select="$jsontypinfo"/>
      </xsl:if>
  </xsl:template>

  <xsl:template match="literal" mode="JAXBAnnotation">
    @jakarta.xml.bind.annotation.XmlEnumValue("<xsl:value-of select="value"/>")
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
      <xsl:for-each select="objectType[not(vf:hasMapping(vf:asvodmlref(.),'java'))]|dataType[not(vf:hasMapping(vf:asvodmlref(.),'java'))]"> <!-- dont put mapped types in - TODO need to find a way to put the mapped types into context-->
        <xsl:value-of select="name"/>&cr;
      </xsl:for-each>
    </xsl:result-document> 
  </xsl:template>

  <xsl:template match="vo-dml:model" mode="modelClass">
    <xsl:param name="root_package_dir"/>
    <xsl:param name="root_package"/>
    <xsl:variable name="file" select="concat($output_root, '/', $root_package_dir, '/',vf:upperFirst(name),'Model.java')"/>
    <xsl:message >Writing to Overall Model file <xsl:value-of select="$file"/></xsl:message>
      <!-- open file for this package -->
    <!-- imported model names -->
    <xsl:variable name="modelsInScope" select="(name,vf:importedModelNames(name))"/>
      <xsl:variable name="possibleRefs" select="distinct-values($models/vo-dml:model[name = $modelsInScope ]//reference/datatype/vodml-ref)" as="xsd:string*"/>

      <xsl:message>models in scope=<xsl:value-of select="concat(string-join($modelsInScope,','), ' hasref=',string-join($possibleRefs,','))"/> </xsl:message>
    <xsl:variable name="references-vodmlref" as="xsd:string*">
        <xsl:for-each select="$possibleRefs">
            <xsl:variable name="contained" select="$models/vo-dml:model[name = $modelsInScope ]//*[composition/datatype/vodml-ref/text()=current()]" as="element()*"/> <!-- could be multiply contained? -->
            <xsl:variable name="okref" select="for $v in $contained return vf:asvodmlref($v) = $possibleRefs" as="xsd:boolean*"/>
            <xsl:message>model references type=<xsl:value-of select="."/> contained=<xsl:value-of select="string-join(for $v in $contained return vf:asvodmlref($v),',')" /> ok=<xsl:value-of
                    select="string-join(string($okref),',')"/></xsl:message>

            <xsl:if test="not($contained) or not(true() = $okref)"> <!-- if the reference is not contained or if it is not contained in another ref -->
                <xsl:message >OK ref = <xsl:value-of select="."/> </xsl:message>
               <xsl:sequence select="."/>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="hasReferences" select="count($possibleRefs) > 0"/>
    <xsl:message>filtered refs=<xsl:value-of select="string-join($references-vodmlref,',')"/> </xsl:message>
    <xsl:variable name="ModelClass" select="concat(vf:upperFirst(name),'Model')"/>
    <xsl:result-document href="{$file}">
    package <xsl:value-of select="$root_package"/>;
    import java.io.IOException;
    import java.util.List;
    import java.util.Set;
    import java.util.Map;
    import java.util.Collection;
    import java.util.ArrayList;
    import java.util.HashMap;
    import java.util.HashSet;
    import java.util.stream.Collectors;
    import java.util.stream.Stream;
    import java.util.AbstractMap;

    import jakarta.xml.bind.JAXBContext;
    import jakarta.xml.bind.annotation.XmlElement;
    import jakarta.xml.bind.annotation.XmlElements;
    import jakarta.xml.bind.annotation.XmlRootElement;
    import jakarta.xml.bind.annotation.XmlType;
    import jakarta.xml.bind.annotation.XmlAccessType;
    import jakarta.xml.bind.annotation.XmlAccessorType;
    import jakarta.xml.bind.JAXBException;

    import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
    import com.fasterxml.jackson.annotation.JsonTypeInfo;
    import com.fasterxml.jackson.databind.ObjectMapper;
    import com.fasterxml.jackson.databind.annotation.JsonTypeIdResolver;
    import com.fasterxml.jackson.annotation.JsonProperty;

    import org.ivoa.vodml.jaxb.XmlIdManagement;
    import org.ivoa.vodml.ModelManagement;
    import org.ivoa.vodml.VodmlModel;
    import org.ivoa.vodml.ModelDescription;
    import org.ivoa.vodml.annotation.VoDml;
    import org.ivoa.vodml.annotation.VodmlRole;

    @XmlAccessorType(XmlAccessType.NONE)
    @XmlRootElement
    @JsonTypeInfo(include=JsonTypeInfo.As.WRAPPER_OBJECT, use=JsonTypeInfo.Id.NAME)
    @JsonIgnoreProperties({"refmap"})
    @VoDml(id="<xsl:value-of select="name"/>" ,role = VodmlRole.model, type="<xsl:value-of select="name"/>")
    public class <xsl:value-of select="$ModelClass"/> implements VodmlModel&lt;<xsl:value-of select="$ModelClass"/>&gt; {

    @XmlType
    public static class References {
    <xsl:for-each select="$references-vodmlref"> <!-- looking at all possible refs -->
        @XmlElement
        @JsonProperty("<xsl:value-of select="vf:utype(.)"/>")
        <xsl:if test="$models/key('ellookup',current())/@abstract or vf:hasSubTypes(current())">
            <xsl:value-of select="$jsontypinfo"/>
        </xsl:if>
        private Set&lt;<xsl:value-of select="vf:QualifiedJavaType(current())"/>&gt;&bl; <xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/> = new HashSet&lt;&gt;();
        void add(<xsl:value-of select="vf:QualifiedJavaType(current())"/> r){<xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/>.add(r);}
    </xsl:for-each>
    }
    @XmlElement
    private References refs = new References();
    <xsl:if test="$hasReferences" >
    @SuppressWarnings("rawtypes")
    private final  Map&lt;Class, Set&gt; refmap = Stream.of(
      <xsl:for-each select="$references-vodmlref"> <!-- looking at all possible refs -->
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
        <xsl:value-of select="$jsontypinfo"/>
    private List&lt;Object&gt; content  = new ArrayList&lt;&gt;();
      <xsl:for-each select="//objectType[not(@abstract='true') and (not(vf:referredTo(vf:asvodmlref(.))) or (vf:asvodmlref(.) = vf:referencesInHierarchy(vf:asvodmlref(.)) )) ]">
<!--         <xsl:message>ref in hierarchy <xsl:value-of select="vf:asvodmlref(.)"/> refs= <xsl:value-of select="vf:referencesInHierarchy(vf:asvodmlref(.))"/>  </xsl:message>-->
      public void addContent( final <xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/> c)
      {
      content.add(c);
      <xsl:if test="$hasReferences">
          org.ivoa.vodml.nav.Util.findReferences(c, refmap);
      </xsl:if>
      }

      public void deleteContent( final <xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/> c)
      {
      content.remove(c);
      <xsl:if test="$hasReferences">
          //FIXME this is not  removing the right references - need to remove need to search for references and in content and then remove if last one...
          if(refmap.containsKey(c.getClass()))
          {
          refmap.get(c.getClass()).remove(c);
          }
      </xsl:if>
      }
      </xsl:for-each>
        <xsl:for-each select="$references-vodmlref">
        <!--         <xsl:message>ref in hierarchy <xsl:value-of select="vf:asvodmlref(.)"/> refs= <xsl:value-of select="vf:referencesInHierarchy(vf:asvodmlref(.))"/>  </xsl:message>-->
        /** directly add reference. N.B. should not be necessary in normal operation adding content should find embedded references.
         * @param c the reference to be added.
         */
        public void addReference( final <xsl:value-of select="vf:QualifiedJavaType(current())"/> c)
        {
            refs.add(c);
        }
        </xsl:for-each>
        @SuppressWarnings("unchecked")
      public &lt;T&gt; List&lt;T&gt; getContent(Class&lt;T&gt; c) {
      return (List&lt;T&gt;) content.stream().filter(p -> p.getClass().isAssignableFrom(c)).collect(
      Collectors.toUnmodifiableList()
      );
      }
      @Override
      public void processReferences()
      {
        List&lt;XmlIdManagement&gt; il = org.ivoa.vodml.nav.Util.findXmlIDs(content);
        <xsl:if test="$hasReferences">
        @SuppressWarnings("unchecked")
        Stream&lt;Object&gt; t = refmap.values().stream().flatMap(f->f.stream());
        il.addAll(t.map(f->(XmlIdManagement)f).collect(Collectors.toList()));
        </xsl:if>
        org.ivoa.vodml.nav.Util.makeUniqueIDs(il);
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
       public static String pu_name(){
        return "<xsl:value-of select='concat("vodml_",name)'/>";
        }

        public static void writeXMLSchema() {
        try {
            contextFactory().generateSchema(new org.javastro.ivoa.jaxb.SchemaNamer(description().schemaMap()));
        } catch (IOException | JAXBException e) {
            throw new RuntimeException("Problem writing XML Schema",e);
        }
        }
        /**
        * Return a Jackson objectMapper suitable for JSON serialzation.
        * @return the objectmapper.
        */
        public static ObjectMapper jsonMapper()
        {
        return org.ivoa.vodml.json.JsonManagement.jsonMapper(<xsl:value-of select="$ModelClass"/>.description());
        }
        /**
        * generate management interface instance for model.
        * @return the management interface.
        */
        @Override
        public ModelManagement&lt;<xsl:value-of select="$ModelClass"/>&gt; management() {return new ModelManagement&lt;<xsl:value-of select="$ModelClass"/>&gt;()
        {
        @Override
        public String pu_name() {return <xsl:value-of select="$ModelClass"/>.pu_name();}

        @Override
        public void writeXMLSchema() { <xsl:value-of select="$ModelClass"/>.writeXMLSchema();}

        @Override
        public JAXBContext contextFactory() throws JAXBException {  return <xsl:value-of select="$ModelClass"/>.contextFactory();}

        @Override
        public boolean hasReferences() { return <xsl:value-of select="$ModelClass"/>.hasReferences();}

        @Override
        public ObjectMapper jsonMapper() { return <xsl:value-of select="$ModelClass"/>.jsonMapper();}

        @Override
        public <xsl:value-of select="$ModelClass"/> theModel() { return <xsl:value-of select="$ModelClass"/>.this;}

        @Override
        public List&lt;Object&gt; getContent() {
        return content;
        }


        };};

        public static ModelDescription description(){
        return new ModelDescription() {
        @SuppressWarnings("rawtypes")
        @Override
        public Map&lt;String, Class&gt; utypeToClassMap() {
        final HashMap&lt;String, Class&gt; retval = new HashMap&lt;&gt;();
        <xsl:for-each select="$models/vo-dml:model[name = $modelsInScope ]//(objectType|dataType)">
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"></xsl:variable>
        retval.put("<xsl:value-of select="vf:utype($vodml-ref)"/>", <xsl:value-of select="vf:QualifiedJavaType($vodml-ref)"/>.class);
        </xsl:for-each>
        return retval;
        }

        @Override
        public Map&lt;String, String&gt; schemaMap() {
        final  Map&lt;String,String&gt; schemaMap = new HashMap&lt;&gt;();
        <xsl:for-each select="$mapping/bnd:mappedModels/model/xml-targetnamespace">
            <xsl:choose>
                <xsl:when test="@schemaFilename">
                    schemaMap.put("<xsl:value-of select="normalize-space(text())"/>","<xsl:value-of select="@schemaFilename"/>");
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="ns" select="normalize-space(text())"/>
                    schemaMap.put("<xsl:value-of select="$ns"/>","<xsl:value-of select="concat(tokenize($ns,'/+')[string-length(.)>0][last()],'.xsd')"/>");
                </xsl:otherwise>
            </xsl:choose>

        </xsl:for-each>
        return schemaMap;
        }

        @Override
        public String xmlNamespace() {
        return "<xsl:value-of select="$mapping/bnd:mappedModels/model[name=current()/name]/xml-targetnamespace"/>";

        }

        };
        }


        /**
        * Return the model description in non-static fashion.
        * overrides @see org.ivoa.vodml.VodmlModel#descriptor()
        * @return the model description.
        */
        @Override
        public ModelDescription descriptor() {
        return description();

        }

        }
    </xsl:result-document>

  </xsl:template>
  <xsl:template match="vo-dml:model|package" mode="JAXBContext">
    <xsl:variable name="jpackage" select="$mapping/bnd:mappedModels/model[name=current()/ancestor-or-self::vo-dml:model/name]/java-package"/>
    <xsl:value-of select="string-join(($jpackage,ancestor-or-self::package/name),'.')"/>
    <xsl:apply-templates select="package" mode="JAXBContext"/>
  </xsl:template>


</xsl:stylesheet>