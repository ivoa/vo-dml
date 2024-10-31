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
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(current())"/>

  @jakarta.xml.bind.annotation.XmlAccessorType( jakarta.xml.bind.annotation.XmlAccessType.NONE )
  @jakarta.xml.bind.annotation.XmlType( name = "<xsl:value-of select="vf:jaxbType($vodml-ref)"/>"
      <!-- proporder is troublesome with subSetting TODO rethink subsetting -->
<!--      ,propOrder={<xsl:value-of select="string-join(for $v in vf:memberOrderXML($vodml-ref) return concat($dq,$v,$dq),',')"/>}-->
      )
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
    @jakarta.xml.bind.annotation.XmlType( name = "<xsl:value-of select="vf:jaxbType(vf:asvodmlref(current()))"/>")
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
    @jakarta.xml.bind.annotation.XmlType( name = "<xsl:value-of select="vf:jaxbType(vf:asvodmlref(current()))"/>")
    @jakarta.xml.bind.annotation.XmlEnum
  </xsl:template>

  <!-- template attribute : adds JAXB annotations for primitive types, data types & enumerations -->
    <xsl:template match="attribute|composition[multiplicity/maxOccurs = 1]" mode="JAXBAnnotation">
        <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
        <xsl:if test="$models/key('ellookup',current()/datatype/vodml-ref)/name() != 'primitiveType' and ($models/key('ellookup',current()/datatype/vodml-ref)/@abstract or vf:hasSubTypes(current()/datatype/vodml-ref))">
            <xsl:value-of select="$jsontypinfo"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="current()/name() = 'attribute' and vf:findTypeDetail(vf:asvodmlref(current()))/isAttribute">
    @jakarta.xml.bind.annotation.XmlAttribute(name = "<xsl:value-of select="name"/>", required =<xsl:apply-templates
                    select="." mode="required"/>)
            </xsl:when>
            <xsl:otherwise>
    @jakarta.xml.bind.annotation.XmlElement( name = "<xsl:value-of select="name"/>", required =<xsl:apply-templates
                    select="." mode="required"/>, type = <xsl:value-of select="$type"/>.class)
            </xsl:otherwise>
        </xsl:choose>

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
      <xsl:variable name="modelsInScope" select="(name,vf:importedModelNames(name))"/>
      <xsl:variable name="references-vodmlref" select="vf:refsToSerialize(name)"/>


      <xsl:variable name="hasReferences" select="count($references-vodmlref) > 0"/>
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
    import org.ivoa.vodml.ModelContext;
    import org.ivoa.vodml.nav.ReferenceCache;
    import org.ivoa.vodml.vocabularies.Vocabulary;

        /** The container class for the <xsl:value-of select="name"/> Model.
        * <xsl:value-of select="description" disable-output-escaping="yes"/>
        */
    @XmlAccessorType(XmlAccessType.NONE)
    @XmlRootElement
    @XmlType(propOrder = {"refs","content"} )
    @JsonTypeInfo(include=JsonTypeInfo.As.WRAPPER_OBJECT, use=JsonTypeInfo.Id.NAME)
    @JsonIgnoreProperties({"refmap"})
    @VoDml(id="<xsl:value-of select="name"/>" ,role = VodmlRole.model, type="<xsl:value-of select="name"/>")
        public class <xsl:value-of select="$ModelClass"/> implements VodmlModel&lt;<xsl:value-of select="$ModelClass"/>&gt; {

    /** A container class for the references in the model. */
    @XmlType
    public static class References {
    <xsl:message>references</xsl:message>
    <xsl:for-each select="$references-vodmlref"> <!-- looking at all possible refs -->
        <xsl:message>ref=<xsl:value-of select="concat(current(),'  references=',string-join(vf:referenceTypesInContainmentHierarchy(current()),','))"/></xsl:message>
        @XmlElement(name="<xsl:value-of select='vf:lowerFirst(vf:jaxbType(current()))'/>")
        @JsonProperty("<xsl:value-of select="vf:utype(.)"/>")
        <xsl:if test="$models/key('ellookup',current())/@abstract or vf:hasSubTypes(current())">
            <xsl:value-of select="$jsontypinfo"/>
        </xsl:if>
        private Set&lt;<xsl:value-of select="vf:QualifiedJavaType(current())"/>&gt;&bl; <xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/> = new HashSet&lt;&gt;();
        void add(<xsl:value-of select="vf:QualifiedJavaType(current())"/> r){<xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/>.add(r);}
    </xsl:for-each>
    <xsl:message>reforder=<xsl:value-of select="string-join(vf:orderReferences($references-vodmlref),',')"/></xsl:message>
    }
    private References refs = new References();

        /**
        * @return the refs
        */
        private References getRefs() {
        return refs;
        }


        /**
        * @param refs the refs to set
        */
        @XmlElement(required = true)
        private void setRefs(References refs) {
        this.refs = refs;
        <xsl:if test="$hasReferences" >
        this.refmap = updateRefmap();
        </xsl:if>
        }


    @SuppressWarnings("rawtypes")
    private static java.util.List&lt;Class&gt; refOrder = java.util.List.of(<xsl:value-of select="string-join(vf:orderReferences($references-vodmlref) ! concat(vf:QualifiedJavaType(.),'.class'),',')"/>);
    <xsl:if test="$hasReferences" >
    @SuppressWarnings("rawtypes")
    private  Map&lt;Class, Set&gt; refmap;
    @SuppressWarnings("rawtypes")
    private  Map&lt;Class, Set&gt; updateRefmap(){
        return Map.ofEntries(
      <xsl:for-each select="$references-vodmlref"> <!-- looking at all possible refs -->
          java.util.Map.entry(<xsl:value-of select="vf:QualifiedJavaType(.)"/>.class, refs.<xsl:value-of select="vf:lowerFirst($models/key('ellookup',current())/name)"/>)<xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
        );
    }
    </xsl:if>
    <xsl:variable name="contentTypes" as="element()*" select="vf:contentToSerialize(name)"/>
    @XmlElements(value = {
      <xsl:for-each select="$contentTypes">
          <xsl:variable name="tv" select="vf:asvodmlref(current())"/>
        @XmlElement(name="<xsl:value-of select="vf:lowerFirst(vf:jaxbType($tv))"/>",
               type = <xsl:value-of select="vf:QualifiedJavaType($tv)"/>.class)
                    <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
    })
        <xsl:value-of select="$jsontypinfo"/>
    private List&lt;Object&gt; content  = new ArrayList&lt;&gt;();

    /** default constructor.
    */
    public <xsl:value-of select="$ModelClass"/>(){
        <xsl:choose>
            <xsl:when test="$hasReferences">
                refmap = updateRefmap();
            </xsl:when>
            <xsl:otherwise>
                //no references
            </xsl:otherwise>
        </xsl:choose>
    }

    private static Map&lt;String,Vocabulary&gt; vocabs = new HashMap&lt;&gt;();
    private static ModelDescription modelDescription;
    static {
        modelDescription = description();

     <xsl:for-each select="distinct-values($models/vo-dml:model[name=$modelsInScope]//semanticconcept/vocabularyURI)">
         vocabs.put(<xsl:value-of select="concat($dq,current(),$dq)"/>,Vocabulary.load(<xsl:value-of select="concat($dq,current(),$dq)"/>));
     </xsl:for-each>
    }
        <!--- TODO possibly put this in the model management interface -->
        /**
        * Test if a term is in the vocabulary.
        * @param value the value to test
        * @param vocabulary the uri for the vocabulary.
        * @return true if the term is in the vocabulary.
        */
        public static boolean isInVocabulary(String value, String vocabulary)
        {
        if(vocabs.containsKey(vocabulary))
        {
        return vocabs.get(vocabulary).hasTerm(value);
        }
        return false;
        }


        <xsl:for-each select="$contentTypes">
<!--         <xsl:message>ref in hierarchy <xsl:value-of select="vf:asvodmlref(.)"/> refs= <xsl:value-of select="vf:referenceTypesInContainmentHierarchy(vf:asvodmlref(.))"/>  </xsl:message>-->
      /**
      * add <xsl:value-of select="current()/name"/> to model.
      * @param c  <xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/>
          */
          public void addContent( final <xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/> c)
      {
      content.add(c);
      <xsl:if test="$hasReferences">
          org.ivoa.vodml.nav.Util.findReferences(c, refmap);
      </xsl:if>
      }
          /**
          * remove <xsl:value-of select="current()/name"/> from model.
          *  @param c  <xsl:value-of select="vf:QualifiedJavaType(vf:asvodmlref(.))"/>
          */
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
        <!--         <xsl:message>ref in hierarchy <xsl:value-of select="vf:asvodmlref(.)"/> refs= <xsl:value-of select="vf:referenceTypesInContainmentHierarchy(vf:asvodmlref(.))"/>  </xsl:message>-->
        /** directly add reference. N.B. should not be necessary in normal operation - adding content should find embedded references.
         * @param c the reference to be added.
         */
        public void addReference( final <xsl:value-of select="vf:QualifiedJavaType(current())"/> c)
        {
            refs.add(c);
        }
        </xsl:for-each>
        /**
        * Get the content of the given type.
        * @param &lt;T&gt; The type of the content
        * @param c the class of the content.
        * @return the content.
        */
        @SuppressWarnings("unchecked")
      public &lt;T&gt; List&lt;T&gt; getContent(Class&lt;T&gt; c) {
        if(!Stream.concat(refOrder.stream(), modelDescription.contentClasses().stream()).anyMatch(i -> i.isAssignableFrom(c))) throw new IllegalArgumentException(c.getCanonicalName() + " is not part of the model");

        return (List&lt;T&gt;)
        <xsl:choose>
            <xsl:when test="$hasReferences">
                Stream.concat(content.stream(),
                refmap.getOrDefault(c, java.util.Collections.emptySet()).stream())
            </xsl:when>
            <xsl:otherwise>
                content.stream()
            </xsl:otherwise>
        </xsl:choose>
        .filter(p -> p.getClass().isAssignableFrom(c)).collect(
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


      /** if the model has references.
        * @return true if the model has references.
        */
      public static boolean hasReferences(){
         return <xsl:value-of select="$hasReferences"/>;
      }

        /**
        * the context factory for the model.
        * @return the JAXBContext.
        * @throws JAXBException if there is a problem.
        */
        public static JAXBContext contextFactory()  throws JAXBException
      {
      <xsl:variable name="packages" as="xsd:string*">
        <xsl:apply-templates select="$models" mode="JAXBContext"/>
      </xsl:variable>
         return JAXBContext.newInstance("<xsl:value-of select="string-join($packages,':')"/>" );
      }
        /** The persistence unit name for the model.
        * @return the name.
        */
       public static String pu_name(){
        return "<xsl:value-of select='$pu_name'/>";
        }
        /** write an XML schema based on JAXB interpretation. */
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
        /**
        * {@inheritDoc}
        */
        @Override
        public String pu_name() {return <xsl:value-of select="$ModelClass"/>.pu_name();}
        /**
        * {@inheritDoc}
        */
        @Override
        public void writeXMLSchema() { <xsl:value-of select="$ModelClass"/>.writeXMLSchema();}

        /**
        * {@inheritDoc}
        */
        @Override
        public JAXBContext contextFactory() throws JAXBException {  return <xsl:value-of select="$ModelClass"/>.contextFactory();}

        /**
        * {@inheritDoc}
        */
        @Override
        public boolean hasReferences() { return <xsl:value-of select="$ModelClass"/>.hasReferences();}

        /**
        * {@inheritDoc}
        */
        @Override
        public void persistRefs(jakarta.persistence.EntityManager em)
        {
        <xsl:if test="$hasReferences">
            for(@SuppressWarnings("rawtypes") Set refset: refOrder.stream().map(c->refmap.get(c)).toList())
            {
            for(Object ref:refset) {
            em.persist(ref);
            }
            }
        </xsl:if>
        }

        /**
        * {@inheritDoc}
        */
        @Override
        public ObjectMapper jsonMapper() { return <xsl:value-of select="$ModelClass"/>.jsonMapper();}

        /**
        * {@inheritDoc}
        */
        @Override
        public <xsl:value-of select="$ModelClass"/> theModel() { return <xsl:value-of select="$ModelClass"/>.this;}

        /**
        * {@inheritDoc}
        */
        @Override
        public List&lt;Object&gt; getContent() {
        return content;
        }


        };};

        /** Get the model description.
        * @return the description.
        */
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
        <xsl:for-each select="$mapping/bnd:mappedModels/model/name">
            schemaMap.put(<xsl:value-of select="concat($dq,vf:xsdNs(current()),$dq,',',$dq,vf:xsdFileName(current()),$dq)"/>);
        </xsl:for-each>
        return schemaMap;
        }

        @Override
        public String xmlNamespace() {
        return "<xsl:value-of select="vf:xsdNs(current()/name)"/>";

        }

        /**
        * Return a list of content classes for this model.
        * @return the list.
        */
        @Override
        @SuppressWarnings("rawtypes")
        public  java.util.List&lt;Class&gt; contentClasses()
        {
        return java.util.List.of(
        <xsl:for-each select="$contentTypes">
            <xsl:if test="position() != 1">,</xsl:if><xsl:value-of select="concat(vf:QualifiedJavaType(vf:asvodmlref(.)),'.class')"/>
        </xsl:for-each>
        );
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
        /** create a context in preparation for cloning. */
        @SuppressWarnings("rawtypes")
        public void createContext()
        {

        final Map&lt;Class, ReferenceCache&gt; collect = Map.ofEntries(
        <xsl:for-each select="vf:containedReferencesInModels()">
        <xsl:value-of select="concat('Map.entry(',vf:QualifiedJavaType(current()),'.class, new ReferenceCache',$lt,vf:QualifiedJavaType(current()),$gt,'())')"/>
            <xsl:if test="position() != last()">,
            </xsl:if>
        </xsl:for-each>
        );
        ModelContext.create(  collect );
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