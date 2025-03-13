<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="bnd"
                >
<!-- 
  This XSLT script transforms a data model in VO-DML/XML representation to 
  Purely Ordinary Java Classes.
  
  Only defines fields for components.

  Java 11 is required by these two libraries.
  
  Gerard Lemson (mpa)/Laurent Bourges (grenoble), Paul Harrison (JBO)
-->

  <xsl:include href="jaxb.xsl"/>
  <xsl:include href="jpa.xsl"/>

 

  <xsl:output method="text" encoding="UTF-8" indent="yes" />
  <xsl:output name="packageInfo" method="html" encoding="UTF-8" doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"/>
    <xsl:output name="packageInfoJ" method="text" encoding="UTF-8"/>

  <xsl:strip-space elements="*" />


  <xsl:param name="lastModified"/>
  <xsl:param name="lastModifiedText"/>
  <xsl:param name="output_root" />
  <xsl:param name="vo-dml_package" select="'org.ivoa.vodml.model'"/>
  <xsl:param name="binding"/>
    <xsl:param name="do_jpa" select="true()"/>
  <xsl:param name="write_persistence_xml" select="true()"/>
  <xsl:param name="pu_name" select="'model_pu'"/> <!--FIXME not used -->

    <xsl:param name="isMain"/>
  <xsl:include href="binding_setup.xsl"/>

  <xsl:variable name="jpafetch">
      <xsl:choose>
          <xsl:when test="$mapping/bnd:mappedModels/model[name=$themodelname]/rdb/@fetching = 'eager'">
              <xsl:message>doing eager fetching</xsl:message>
              <xsl:sequence select="'jakarta.persistence.FetchType.EAGER'"/>
          </xsl:when>
          <xsl:otherwise>
              <xsl:message>doing lazy fetching</xsl:message>
            <xsl:sequence select="'jakarta.persistence.FetchType.LAZY'"/>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:variable>

  <!-- main pattern : processes for root node model -->
  <xsl:template match="/">
  <xsl:message >Generating Java - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,' and ')" /></xsl:message>
  <xsl:apply-templates/>
 </xsl:template>

  <!-- model pattern : generates gen-log and processes nodes package and generates the ModelVersion class and persistence.xml -->
  <xsl:template match="vo-dml:model">
    <xsl:message>
-------------------------------------------------------------------------------------------------------
-- Generating Java code for model <xsl:value-of select="name"/> [<xsl:value-of select="title"/>].
-- last modification date of the model <xsl:value-of select="lastModified"/>
        fetch=<xsl:value-of select="$mapping/bnd:mappedModels/model[name=$themodelname]/rdb/@fetching"/>
-------------------------------------------------------------------------------------------------------
    </xsl:message>

    <xsl:variable name="prefix" select="name"/>
      <xsl:if test="not($mapping/bnd:mappedModels/model[name=$prefix])">
          <xsl:message terminate="yes">
              There is no binding for model <xsl:value-of select="$prefix"/>
          &cr;
          </xsl:message>
      </xsl:if>
      <xsl:variable name="root_package" select="$mapping/bnd:mappedModels/model[name=$prefix]/java-package"/>
      <xsl:variable name="root_package_dir" select="replace($root_package,'[.]','/')"/>

      <!--
          <xsl:message>root_package = <xsl:value-of select="$root_package"/></xsl:message>
          <xsl:message>root_package_dir = <xsl:value-of select="$root_package_dir"/></xsl:message>
       -->

      <!-- don't do model factory for now
    <xsl:apply-templates select="." mode="modelFactory">
      <xsl:with-param name="root_package" select="$root_package"/>
      <xsl:with-param name="root_package_dir" select="$root_package_dir"/>
    </xsl:apply-templates>
    -->

       <xsl:apply-templates select="." mode="modelClass">
          <xsl:with-param name="root_package" select="$root_package"/>
          <xsl:with-param name="root_package_dir" select="$root_package_dir"/>
      </xsl:apply-templates>

      <xsl:apply-templates select="." mode="content">
      <xsl:with-param name="dir" select="$root_package_dir"/>
      <xsl:with-param name="path" select="$root_package"/>
    </xsl:apply-templates>
      <xsl:if test="$isMain eq 'True'">
          <xsl:if test="$do_jpa ">
            <xsl:call-template name="persistence_xml">
                <xsl:with-param name="doit" select="$write_persistence_xml"/>
            </xsl:call-template>
          </xsl:if>
      </xsl:if>
      <xsl:call-template name="listVocabs">
          <xsl:with-param name="outfile" select="'vocabularies.txt'"/>
      </xsl:call-template>
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
          <xsl:with-param name="path" select="$newpath"/>
      </xsl:apply-templates>

      <xsl:apply-templates select="." mode="jaxb.index">
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
    <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
    <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'java')"/>
     <xsl:choose>
    <xsl:when test="not($mappedtype) or $mappedtype = ''" >
      <xsl:variable name="file" select="concat($output_root, '/', $dir, '/', vf:capitalize(name), '.java')"/>

    <!-- open file for this class -->
      <xsl:message >Writing to Class file <xsl:value-of select="$file"/> base=<xsl:value-of select="vf:baseTypes($vodml-ref)/vf:capitalize(name)"/> haschildren=<xsl:value-of
              select="vf:hasSubTypes($vodml-ref)"/> st=<xsl:value-of select="string-join(vf:subTypeIds($vodml-ref),',')"/> contained=<xsl:value-of select="vf:isContained($vodml-ref)"/> referredto=<xsl:value-of
              select="vf:referredTo($vodml-ref)"/> ct=<xsl:value-of select="string-join(vf:containingTypes($vodml-ref)/name,',')"/></xsl:message>
      
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
        <!-- do not import types - always refer to fully qualified - makes life easier -->
    </xsl:template>



    <xsl:template match="objectType|dataType" mode="builder">
        <xsl:variable name="this" select="."/>
<!--        <xsl:variable name="subsetsInSubtypes" select="vf:subSettingInSubHierarchy(vf:asvodmlref(current()))/role/vodml-ref" as="xsd:string*"/>-->

        <xsl:variable name="members" as="xsd:string*" select="vf:javaAllMembers(vf:asvodmlref($this))" />
        <xsl:variable name="subsets" select="vf:subSettingInSuperHierarchy(vf:asvodmlref(current()))" as="element()*"/>

        /**
          A builder class for <xsl:value-of select="name"/>, mainly for use in the functional builder pattern.
        */
        public static class <xsl:value-of select="vf:capitalize(name)"/>Builder {
           <xsl:for-each select="$members">
               <xsl:variable name="m" select="$models/key('ellookup',current())"/>
<!--               <xsl:message>builder member=<xsl:value-of select="concat(current(),' ',name($m),' subs=',string-join($subsetsInSubtypes,','))"/> </xsl:message>-->

                   /**
                   * <xsl:apply-templates select="$m" mode="desc"/>
                   */
                   <xsl:choose>
                       <xsl:when test="current() = $subsets/role/vodml-ref">
                           <xsl:variable name="type" select="vf:JavaType($subsets[role/vodml-ref/text() = current()]/datatype/vodml-ref)"/>
                           <xsl:choose>
                               <xsl:when test="$m/multiplicity[maxOccurs != 1]">
                                   <xsl:value-of select="concat('public java.util.List', $lt, $type, $gt, ' ', $m/name)"/>;
                               </xsl:when>
                               <xsl:otherwise>
                                   <xsl:value-of select="concat('public ',$type, ' ', $m/name)"/>;
                               </xsl:otherwise>
                           </xsl:choose>

                       </xsl:when>
                       <xsl:otherwise>
                           <xsl:value-of>
                               <xsl:text>public </xsl:text>
                               <xsl:apply-templates select="$m" mode="paramDecl"/>;
                           </xsl:value-of>
                       </xsl:otherwise>
                   </xsl:choose>


           </xsl:for-each>

           private <xsl:value-of select="vf:capitalize(name)"/>Builder with (java.util.function.Consumer &lt;<xsl:value-of select="vf:capitalize(name)"/>Builder&gt; f)
           {
             f.accept(this);
             return this;
           }
           /**
           *  create a <xsl:value-of select="name"/> from this builder.
           *  @return an object initialized from the builder.
           */
           public <xsl:value-of select="vf:capitalize(name)"/> create()
           {
             return new <xsl:value-of select="vf:capitalize(name)"/> (
          <!-- this ought to be concise, but reverses the subsets order for some reason
             <xsl:value-of select="string-join(for $v in ($members,$subsets/role/vodml-ref) return tokenize($v,'[.]')[last()], ',')" />
             -->
              <xsl:variable name="params"  as="xsd:string*">
                  <xsl:for-each select="$members"><xsl:value-of select="vf:javaMemberName($models/key('ellookup',current())/name)" /></xsl:for-each>
              </xsl:variable>
              <xsl:value-of select="string-join($params,',')"/>
              );
           }
         }
        /**
        *   create a <xsl:value-of select="name"/> in functional builder style.
        *  @param f the functional builder.
        *  @return an object initialized from the builder.
        */
         public static <xsl:value-of select="vf:capitalize(name)"/>&bl;create<xsl:value-of select="vf:capitalize(name)"/> (java.util.function.Consumer &lt;<xsl:value-of select="vf:capitalize(name)"/>Builder&gt; f)
         {
             return new <xsl:value-of select="vf:capitalize(name)"/>Builder().with(f).create();
         }
    </xsl:template>

    <!-- generate an all member constructor

    -->
    <xsl:template match="objectType|dataType" mode="constructor">
        <xsl:variable name="this" select="."/>
        <xsl:variable name="supertype" select="$models/key('ellookup',current()/extends/vodml-ref)"/>
        <xsl:variable name="subsetsInSubtypes" select="distinct-values(vf:subSettingInSubHierarchy(vf:asvodmlref(current()))/role/vodml-ref)" as="xsd:string*"/>

        <xsl:variable name="members" as="xsd:string*" select="vf:javaAllMembers(vf:asvodmlref($this))" />
        <xsl:variable name="subsets" select="vf:subSettingInSuperHierarchy(vf:asvodmlref(current()))" as="element()*" />

        <xsl:variable name="consmembers" select="($members)"/>
        <xsl:variable name="localmembers" select="vf:javaLocalDefines(vf:asvodmlref($this))" as="xsd:string*"/>

        <xsl:variable name="superparams" as="xsd:string*">
            <xsl:if test="extends">
                <xsl:sequence select="vf:javaAllMembers(extends/vodml-ref)"/>
            </xsl:if>
        </xsl:variable>
<!--        <xsl:message>members=<xsl:value-of select="string-join($members,',')"/></xsl:message>
        <xsl:message>subsets=<xsl:value-of select="concat(string-join(for $w in $subsets return concat($w/role/vodml-ref,'==', $w/datatype/vodml-ref,'|', $models/key('ellookup',$w/role/vodml-ref)/name(), '|', $models/key('ellookup',$w/role/vodml-ref)/multiplicity/maxOccurs),', '),' subsetssub=',string-join($subsetsInSubtypes,','))"/></xsl:message>
        <xsl:message><xsl:value-of select="concat('cons=',string-join($consmembers,','),  ' loc=',string-join($localmembers,','),  ' sup=',string-join($superparams,','))"/></xsl:message> -->
        <xsl:variable name="decls" as="map(xsd:string,text())">
            <xsl:map>
            <xsl:for-each select="$consmembers">
                <xsl:variable name="m" select="$models/key('ellookup',current())"/>
<!--                <xsl:message>constructor member=<xsl:value-of select="concat(current(),' ',name($m),' insubs=', count($subsets/role[vodml-ref = current()])>0,' insubsubs=',name($m)='attribute' and current() = $subsetsInSubtypes)"/> </xsl:message>-->
                <xsl:map-entry key = ".">
                    <xsl:choose>
                        <xsl:when test="$this/constraint[ends-with(@xsi:type,':SubsettedRole')]/role[vodml-ref/text() = current()]"><!--TODO test if this condition is actually covered by below -->
                            <xsl:variable name="type" select="vf:JavaType($this/constraint[ends-with(@xsi:type,':SubsettedRole') and role/vodml-ref/text() = current()]/datatype/vodml-ref)"/>
                            <xsl:choose>
                                <xsl:when test="$m/multiplicity[maxOccurs != 1]">
                                    <xsl:value-of select="concat('final java.util.List', $lt, $type, $gt, ' ', $m/name)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat('final ',$type, ' ', $m/name)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="$subsets/role[vodml-ref = current()]">
                            <xsl:variable name="type" select="vf:JavaType($subsets[role/vodml-ref/text() = current()]/datatype/vodml-ref)"/>
                            <xsl:choose>
                                <xsl:when test="$m/multiplicity[maxOccurs != 1]">
                                    <xsl:value-of select="concat('final java.util.List', $lt, $type, $gt, ' ', $m/name)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat('final ',$type, ' ', $m/name)"/>
                                </xsl:otherwise>
                            </xsl:choose>

                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of>
                                <xsl:text>final </xsl:text>
                                <xsl:apply-templates select="$m" mode="paramDecl"/>
                            </xsl:value-of>
                        </xsl:otherwise>
                    </xsl:choose>
                 </xsl:map-entry>
            </xsl:for-each>
           </xsl:map>
        </xsl:variable>
        <xsl:if test="count($consmembers) > 0">
        /**
        * full parameter constructor.
            <xsl:for-each select="($consmembers)">
                <xsl:variable name="m" select="$models/key('ellookup',current())"/>
        *   @param <xsl:value-of select="concat(vf:javaMemberName($m/name),' ')"   /> <xsl:apply-templates select="$m" mode="desc" />
            </xsl:for-each>
        */
        public  <xsl:value-of select="vf:capitalize(name)"/> (
          <xsl:value-of select="string-join(for $v in ($consmembers) return map:get($decls, $v),', ')"/>
        )
        {
            super(<xsl:value-of select="string-join(for $v in $superparams return vf:javaMemberName($models/key('ellookup',$v)/name),',')"/>);
           <xsl:for-each select="$localmembers">
               <xsl:variable name="m" select="$models/key('ellookup',current())"/>
               <xsl:choose>
                   <xsl:when test="$m/semanticconcept/vocabularyURI">
                       set<xsl:value-of select="concat(vf:upperFirst($m/name),'(',vf:javaMemberName($m/name),')')"/>;
                   </xsl:when>
                   <xsl:otherwise>
                       this.<xsl:value-of select="vf:javaMemberName($m/name)"/> = <xsl:value-of select="vf:javaMemberName($m/name)"/>;
                   </xsl:otherwise>
               </xsl:choose>

           </xsl:for-each>
          }
        </xsl:if>
        <xsl:if test="vf:hasSubTypes(vf:asvodmlref($this)) or extends or @abstract">
            <xsl:variable name="thistype" select="vf:JavaType(vf:asvodmlref($this))"/>
            <xsl:variable name="toptype" >
                <xsl:choose>
                    <xsl:when test="extends">
                        <xsl:value-of select="vf:JavaType(vf:baseTypeIds(vf:asvodmlref($this))[last()])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$thistype"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            /**
            * make a clone of the object taking into account current polymorhic type.
            * @return the cloned object.
            */
            <xsl:if test="@abstract">abstract </xsl:if><xsl:value-of select="concat( 'public ', $toptype, ' copyMe()')"/><xsl:if test="@abstract">;</xsl:if>
            <xsl:if test="not(@abstract)">
                {
                   return new <xsl:value-of select="concat($thistype,'(this)')"/>;
                }
            </xsl:if>

        </xsl:if>

        <xsl:if test="vf:hasContainedReferenceInTypeHierarchy(vf:asvodmlref($this))" >

            /** updates any cloned references that are contained within the hierarchy. */
            public void updateClonedReferences() {
            <xsl:if test="$this/extends">
            super.updateClonedReferences();
            </xsl:if>
            <xsl:for-each select="$localmembers">
                <xsl:variable name="m" select="$models/key('ellookup',current())"/>
                <xsl:choose>
                    <xsl:when test="$m/name()='reference' and vf:isContained($m/datatype/vodml-ref)">
                        this.<xsl:value-of select="concat(vf:javaMemberName($m/name),' = org.ivoa.vodml.ModelContext.current().cache(',vf:JavaType($m/datatype/vodml-ref),'.class).get(this.',vf:javaMemberName($m/name),');')"/>
                    </xsl:when>
                    <xsl:when test=" vf:hasContainedReferencesInContainmentHierarchy($m/datatype/vodml-ref,vf:asvodmlref($this))">
                        if(<xsl:value-of select="concat('this.',vf:javaMemberName($m/name),'!= null')"/>){
                        <xsl:choose>
                        <xsl:when test="vf:isCollection($m)">
                            for( var _x: this.<xsl:value-of select="vf:javaMemberName($m/name)"/>){_x.updateClonedReferences();}
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('this.',vf:javaMemberName($m/name),'.updateClonedReferences();')"/>
                        </xsl:otherwise>
                        </xsl:choose>
                        }
                    </xsl:when>
                    <xsl:otherwise>
                        //  this.<xsl:value-of select="concat(vf:javaMemberName($m/name),' ', vf:hasReferencesInContainmentHierarchy($m/datatype/vodml-ref), ' ', vf:hasContainedReferencesInContainmentHierarchy($m/datatype/vodml-ref,vf:asvodmlref($this)),' ', string-join(vf:referenceTypesInContainmentHierarchy($m/datatype/vodml-ref),','),' ch=',string-join(vf:ContainerHierarchyInOwnModel(vf:asvodmlref($this)),','))"/>;
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each>
            }

        </xsl:if>

        /**
        * Copy Constructor. Note that references will remain as is rather than be copied.
        * @param other the object to be copied.
        */
        public  <xsl:value-of select="vf:capitalize(name)"/> ( final <xsl:value-of select="vf:capitalize(name)"/> other)
        {
        <xsl:choose>
            <xsl:when test="extends">
                super(other);
            </xsl:when>
            <xsl:otherwise>
                super ();
            </xsl:otherwise>
        </xsl:choose>


        <xsl:for-each select="$members">
            <xsl:variable name="m" select="$models/key('ellookup',current())"/>
            <xsl:call-template name="copymember">
                <xsl:with-param name="m" select="$m"/>
                <xsl:with-param name="subsets" select="$subsets"/>
            </xsl:call-template>
        </xsl:for-each>

        }


        /**
        * Update this object with the content of the given object. Note that references will remain as is rather than be copied.
        * @param other the object to be copied.
        */
        public void updateUsing ( final <xsl:value-of select="vf:capitalize(name)"/> other)
        {

        <xsl:for-each select="$members">
            <xsl:variable name="m" select="$models/key('ellookup',current())"/>
            <xsl:call-template name="copymember">
                <xsl:with-param name="m" select="$m"/>
                <xsl:with-param name="subsets" select="$subsets"/>
            </xsl:call-template>
        </xsl:for-each>

        }

        <xsl:if test="not(@abstract) and extends "><!--TODO if abstact of abstract! -->
            <xsl:variable name="sparms" select="(concat('final ',vf:JavaType(extends/vodml-ref), ' superinstance'), for $v in $localmembers return map:get($decls, $v))"/>
            /**
            * Constructor from supertype instance.
            * @param superinstance The supertype.
            <xsl:for-each select="$localmembers">
                <xsl:variable name="m" select="$models/key('ellookup',current())"/>
            * @param <xsl:value-of select="concat($m/name,' ')"/> <xsl:apply-templates select="$m" mode="desc" />
            </xsl:for-each>
            */
            public  <xsl:value-of select="vf:capitalize(name)"/> ( <xsl:value-of select="string-join($sparms,',')"/> )
            {
            super (superinstance);
            <xsl:for-each select="$localmembers">
                <xsl:variable name="m" select="$models/key('ellookup',current())"/>
                <xsl:choose>
                    <xsl:when test="$m/semanticconcept/vocabularyURI">
                        set<xsl:value-of select="concat(vf:upperFirst($m/name),'(',vf:javaMemberName($m/name),')')"/>;
                    </xsl:when>
                    <xsl:otherwise>
                        this.<xsl:value-of select="vf:javaMemberName($m/name)"/> = <xsl:value-of select="vf:javaMemberName($m/name)"/>;
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>

            }
        </xsl:if>
    </xsl:template>
    <xsl:template name="copymember">
        <xsl:param name="m" as="element()"/>
        <xsl:param name="subsets" as="element()*"/>

        <xsl:variable name="jt">
            <xsl:choose>
                <xsl:when test="count($subsets/role[vodml-ref = current()])>0">
                    <xsl:value-of select="vf:JavaType($subsets[role/vodml-ref = current()]/datatype/vodml-ref)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="vf:JavaType($m/datatype/vodml-ref)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="t" select="$models/key('ellookup',$m/datatype/vodml-ref)"/>
        <xsl:if test="$m/name() = 'composition' and vf:referredTo($m/datatype/vodml-ref)" >
            // contained reference
        </xsl:if>
        <xsl:choose>
            <xsl:when test="vf:isArrayLike($m)">
                this.<xsl:value-of select="concat($m/name,'=(',$jt,'[])other.',$m/name)"/>;
            </xsl:when>
            <xsl:when test="$m/multiplicity/maxOccurs != 1">

                <!-- TODO consider multiple references -->
                if<xsl:value-of select="concat(' (other.',vf:javaMemberName($m/name),' != null ) {')"/><xsl:text>
                </xsl:text>

                <xsl:variable name="assn">
                <xsl:value-of select="concat('other.',vf:javaMemberName($m/name),'.stream().map(s -',$gt)"/>
                <xsl:choose>
                    <xsl:when test="name($t) = 'enumeration'">
                        <xsl:text>s</xsl:text> <!-- this is just an identity - probably better to do something different at higher level -->
                    </xsl:when>
                    <xsl:when test="name($m) = 'reference'">
                        <xsl:text>s</xsl:text> <!-- just identity -->
                    </xsl:when>
                    <xsl:when test="count($subsets/role[vodml-ref = current()])>0 ">
                        <xsl:value-of select="concat('((',$jt,')s).copyMe()' )"/>
                    </xsl:when>
                    <xsl:when test="$t/@abstract">
                        <xsl:value-of select="concat('(',$jt,')s.copyMe()' )"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(' new ',$jt,'((',$jt,')s )')"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="').collect(java.util.stream.Collectors.toList())'"/>
                </xsl:variable>

                <xsl:choose>
                    <xsl:when test="$m/name() = 'composition' and vf:referredTo($m/datatype/vodml-ref)">
                        <!-- FIXME this is probably not the right place to do this - better to do it in the clone of the type itself -->
                        <xsl:value-of select="concat('var cache = org.ivoa.vodml.ModelContext.current().cache(',$jt,'.class)')"/>;
                        <xsl:value-of select="concat('var cloned = ',$assn)"/>;
                        <xsl:value-of select="concat('cache.setValues(other.',vf:javaMemberName($m/name),', cloned)')"/>;
                        <xsl:value-of select="concat('this.',vf:javaMemberName($m/name), ' = cloned')"/>;
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('this.',vf:javaMemberName($m/name), ' = ',$assn)"/>;
                    </xsl:otherwise>
                </xsl:choose>

                }
            </xsl:when>
            <xsl:when test="$t/name() = 'primitiveType' or $m/name() = 'reference' or $t/name() = 'enumeration'">
                  this.<xsl:value-of select="concat(vf:javaMemberName($m/name),'= other.',vf:javaMemberName($m/name))"/>;
            </xsl:when>
            <xsl:when test="count($subsets/role[vodml-ref = current()])>0">
                this.<xsl:value-of select="concat(vf:javaMemberName($m/name),'=(',$jt,')other.',vf:javaMemberName($m/name))"/>;
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not($t/@abstract)">
                    if<xsl:value-of select="concat(' (other.',vf:javaMemberName($m/name),' != null )this.',vf:javaMemberName($m/name),'= new ',$jt,'(other.',vf:javaMemberName($m/name),')')"/>;
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
  <xsl:template match="attribute|composition|reference" mode="paramDecl">
      <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
      <xsl:variable name="rt" select="$models/key('ellookup',datatype/vodml-ref)"/>
      <xsl:choose>
          <xsl:when test="name()='composition' and multiplicity/maxOccurs != 1" >
              <xsl:choose>
                  <xsl:when test="vf:isSubSetted(vf:asvodmlref(.))">
                      <xsl:value-of select="concat('java.util.List',$lt,'? extends ',$type,$gt, ' ',vf:javaMemberName(name))" />
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:value-of select="concat('java.util.List',$lt,$type,$gt, ' ',vf:javaMemberName(name))" />
                  </xsl:otherwise>
              </xsl:choose>

          </xsl:when>
          <xsl:otherwise>
              <xsl:choose>
                  <xsl:when test="xsd:int(multiplicity/maxOccurs) gt 1">
                      <xsl:value-of select="concat($type, '[] ',vf:javaMemberName(name))" />
                  </xsl:when>
                  <xsl:when test="multiplicity/maxOccurs = -1 and $rt/@abstract" >
                      <xsl:value-of select="concat('java.util.List',$lt,'? extends ',$type,$gt, ' ',vf:javaMemberName(name))" />
                  </xsl:when>
                  <xsl:when test="multiplicity/maxOccurs = -1">
                      <xsl:value-of select="concat('java.util.List',$lt,$type,$gt, ' ',vf:javaMemberName(name))" />
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:value-of select="concat($type, ' ',vf:javaMemberName(name))" />
                  </xsl:otherwise>
              </xsl:choose>

          </xsl:otherwise>
      </xsl:choose>

  </xsl:template>

    <!-- template class creates a java class (JPA compliant) for UML object & data types -->
  <xsl:template match="objectType|dataType" mode="class">
    <xsl:param name="path"/>
    <xsl:variable name="vodml-ref"><xsl:apply-templates select="vodml-id" mode="asvodml-ref"/></xsl:variable>
  package <xsl:value-of select="$path"/>;

    <!-- imports -->
    <xsl:if test="composition">
      import java.util.List;
      import java.util.ArrayList;
    </xsl:if>
    <xsl:apply-templates select="." mode="typeimports"/>
/**
* <xsl:apply-templates select="." mode="desc" />
*
* <xsl:value-of select="name()"/>: &bl;<xsl:value-of select="vf:capitalize(name)" />
*
* <xsl:value-of select="$vodmlauthor"/>
*/
      <xsl:if test="$do_jpa"><xsl:apply-templates select="." mode="JPAAnnotation"/></xsl:if>
    <xsl:apply-templates select="." mode="JAXBAnnotation"/>
    <xsl:call-template name="vodmlAnnotation"/>
      <xsl:apply-templates select="." mode="openapiAnnotation"/>

      public&bl;<xsl:if test="@abstract='true'">abstract</xsl:if>&bl;class <xsl:value-of select="vf:capitalize(name)"/>&bl;
      <xsl:if test="extends">extends <xsl:value-of select="vf:JavaType(extends/vodml-ref)"/></xsl:if>
       implements org.ivoa.vodml.jpa.JPAManipulations<xsl:if test="./name() = 'objectType'">ForObjectType&lt;<xsl:value-of
              select="vf:JavaKeyType(vf:asvodmlref(current()))"/>&gt;</xsl:if>
          <xsl:if test="vf:referredTo($vodml-ref)">,org.ivoa.vodml.jaxb.XmlIdManagement</xsl:if>

    &bl;{
      <xsl:if test="local-name() eq 'objectType' and not (extends) and not(attribute/constraint[ends-with(@xsi:type,':NaturalKey')])" >


          <xsl:if test="not(vf:noTableInComposition($vodml-ref))">
          /**
          * inserted database key
          */
          @jakarta.persistence.Id
          @jakarta.persistence.GeneratedValue
          @jakarta.persistence.Column(name = "<xsl:value-of select="vf:rdbIDColumnName($vodml-ref)"/>")
          </xsl:if>
          <xsl:if test="not(vf:referredTo($vodml-ref))"><!--TODO do we really want to ignore - is this just making everything more complicated - try to do this in conditional way for json depending on use.  see https://github.com/ivoa/vo-dml/issues/30  -->
              @jakarta.xml.bind.annotation.XmlTransient
              // @com.fasterxml.jackson.annotation.JsonIgnore
          </xsl:if>
          protected Long _id = (long) 0;

          /**
          * @return the id
          */
          @Override
          public Long getId() {
          return _id;
          }

          <xsl:if test="vf:referredTo($vodml-ref)">
              /**
              * getter for XMLID
              */

              @jakarta.xml.bind.annotation.XmlAttribute(name = "_id" )
              @jakarta.xml.bind.annotation.XmlID
              @Override
              public String getXmlId(){
              return org.ivoa.vodml.jaxb.XmlIdManagement.createXMLId(_id, this.getClass());
              }
              @Override
              public void setXmlId (String id)
              {
              this._id = org.ivoa.vodml.jaxb.XmlIdManagement.parseXMLId(id);
              }
              @Override
              public boolean hasNaturalKey()
              {
                return false;
              }

          </xsl:if>


      </xsl:if>
<!-- 
      /** serial uid = last modification date of the UML model */
      private static final long serialVersionUID = LAST_MODIFICATION_DATE;
 -->
      <xsl:variable name="localdefs" select="vf:javaLocalDefines($vodml-ref)"/>
      <xsl:apply-templates select="attribute" mode="declare" />
      <xsl:apply-templates select="constraint[ends-with(@xsi:type,':SubsettedRole')]" mode="declare" />
      <xsl:apply-templates select="composition" mode="declare" />
      <xsl:apply-templates select="reference" mode="declare" />
      /**
       * Creates a new <xsl:value-of select="name"/>
       */
      public <xsl:value-of select="vf:capitalize(name)"/>() {
        super();
      }
      <xsl:apply-templates select="." mode="constructor"/>

      <xsl:apply-templates select="attribute|reference|composition|constraint[ends-with(@xsi:type,':SubsettedRole')]" mode="getset"/>

      <xsl:if test="attribute/constraint[ends-with(@xsi:type,':NaturalKey')]">

          <!--TODO deal with multiple natural keys -->
          <!-- TODO this assumes that the natural key is a string -->
          <xsl:variable name="nk" select="attribute[ends-with(constraint/@xsi:type,':NaturalKey')]"/>
          <xsl:variable name="nktype" select="vf:JavaKeyType($vodml-ref)"/>
          <xsl:if test="vf:referredTo($vodml-ref)" >
          @Override
          public String getXmlId(){
          return <xsl:value-of select="$nk/name"/>;
          }
          @Override
          public void setXmlId (String id)
          {
          this.<xsl:value-of select="$nk/name"/> = id;
          }
          @Override
          public boolean hasNaturalKey()
          {
          return true;
          }
      </xsl:if>
          <xsl:if test="$nk/name != 'id'"> <!--only produce this method if the ID is not called ID -->
          /**
          * return the database key id. Note that this is the same as attribute <xsl:value-of select="$nk/name"/>.
          * @return the id
          */
          @Override
          public <xsl:value-of select="$nktype"/> getId() {
          return <xsl:value-of select="$nk/name"/>;
          }</xsl:if>

      </xsl:if>

      <xsl:if test="not(@abstract)">
      <xsl:apply-templates select="." mode="builder"/>
      </xsl:if>

      <xsl:apply-templates select="." mode="jpawalker"/>
      <xsl:apply-templates select="." mode="jparefs"/>
      <xsl:apply-templates select="./self::objectType" mode="jpadeleter"/>

<!--      <xsl:if test="local-name() eq 'dataType'">-->
<!--          <xsl:apply-templates select="." mode="JPAConverter"/>-->
<!--      </xsl:if>-->
}
  </xsl:template>




  <xsl:template match="enumeration" mode="class">
    <xsl:param name="dir"/>
    <xsl:param name="path"/>
package <xsl:value-of select="$path"/>;

      /**
      * <xsl:apply-templates select="." mode="desc" />
      *
      * Enumeration <xsl:value-of select="name"/> :
      *
      * <xsl:value-of select="$vodmlauthor"/>
      */
      <xsl:call-template name="vodmlAnnotation"/>
      <xsl:apply-templates select="." mode="openapiAnnotation"/>
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
        @com.fasterxml.jackson.annotation.JsonValue
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

      }
  </xsl:template>

  <xsl:template match="primitiveType" mode="class">
    <xsl:param name="path"/>

    <xsl:variable name="valuetype">
      <xsl:choose>
        <xsl:when test="extends">
          <xsl:value-of select="vf:JavaType(vf:baseTypeIds(vf:asvodmlref(current()))[last()])"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>Primitive type <xsl:value-of select="name"/> is being represented as a String - in general it is probably best to specialize primitive types with the binding mechanism to get desired representation/behavious</xsl:message>
            <xsl:value-of select="'String'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
package <xsl:value-of select="$path"/>;
        <xsl:apply-templates select="." mode="typeimports" />
<!---->

      /**
      *  <xsl:apply-templates select="." mode="desc" />
      *  PrimitiveType <xsl:value-of select="name"/> :
      *
      *  <xsl:value-of select="$vodmlauthor"/>
      */
      <xsl:call-template name="vodmlAnnotation"/>
      <xsl:apply-templates select="." mode="openapiAnnotation"/>
      <xsl:if test="$do_jpa"><xsl:apply-templates select="." mode="JPAAnnotation"/></xsl:if>
      <xsl:apply-templates select="." mode="JAXBAnnotation"/>
      public class&bl;<xsl:if test="@abstract='true'">abstract</xsl:if>&bl;<xsl:value-of select="vf:capitalize(name)"/>&bl;
      implements java.io.Serializable {

        private static final long serialVersionUID = 1L;


      /**
      * no arg constructor.
      */
      protected <xsl:value-of select="vf:capitalize(name)"/>() {}

      <xsl:if test="not(@abstract)">
      /**
      * copy constructor.
      * @param c the object to be copied.
      */
      public <xsl:value-of select="vf:capitalize(name)"/>(<xsl:value-of select="vf:capitalize(name)"/> c)
      {
         this(c.value);
      }

      /**  representation */
      @jakarta.xml.bind.annotation.XmlValue
      private <xsl:value-of select="$valuetype"/> value;

      /**
      * Creates a new <xsl:value-of select="name"/> Primitive Type instance, using the base type.
      *
      * @param v the base type.
      */
      public <xsl:value-of select="vf:capitalize(name)"/>(final <xsl:value-of select="$valuetype"/> v) {
      this.value = v;
      }
      /**
         * Return the representation of this primitive (value)
         * @return string representation of this primitive( value)
         */
        public final <xsl:value-of select="$valuetype"/> value() {
            return this.value;
        }

        /**
         * Return the string representation of this primitive value
         * @see #value()
         * @return string representation of this primitive
         */
        @Override
        public final String toString() {
            return value().toString();
        }
      </xsl:if>

      }
  </xsl:template>



  <xsl:template match="attribute" mode="declare">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
      <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>

    /**
    * <xsl:apply-templates select="." mode="desc" /> : Attribute <xsl:value-of select="vf:javaMemberName(name)"/> : multiplicity <xsl:apply-templates select="multiplicity" mode="tostring"/>
    *
    */
    <xsl:call-template name="vodmlAnnotation"/>
    <xsl:apply-templates select="." mode="openapiAnnotation"/>

    <xsl:apply-templates select="." mode="JAXBAnnotation"/>
          <xsl:choose>
              <xsl:when test="vf:isSubSetted($vodml-ref)">
    @jakarta.persistence.Transient
              </xsl:when>
              <xsl:otherwise>
                  <xsl:if test="$do_jpa"><xsl:apply-templates select="." mode="JPAAnnotation"/></xsl:if>
              </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
        <xsl:when test="xsd:int(multiplicity/maxOccurs) gt 1"> <!-- TODO this will not work in RDBs -->
    protected <xsl:value-of select="concat($type,'[] ',vf:javaMemberName(name))"/>;
        </xsl:when>
        <xsl:when test="xsd:int(multiplicity/maxOccurs) lt 0"> <!-- IMPL - this is done in db by serializing to delimited string -->
    protected <xsl:value-of select="concat('java.util.List',$lt,$type,$gt,' ',vf:javaMemberName(name))"/> = new java.util.ArrayList&lt;&gt;();
        </xsl:when>
        <xsl:otherwise>
    protected <xsl:value-of select="concat($type,' ',vf:javaMemberName(name))"/>;
        </xsl:otherwise>
    </xsl:choose>

  </xsl:template>




    <xsl:template match="constraint[ends-with(@xsi:type,':SubsettedRole')]" mode="declare">
        <!-- FIXME subsets can also be of compositions and references - worry about multiplicity-->
      <xsl:variable name="subsetted" select="$models/key('ellookup',current()/role/vodml-ref)"/>
      <xsl:if test="name($subsetted)='attribute' and datatype/vodml-ref != $subsetted/datatype/vodml-ref"> <!-- only do this if types are different (subsetting can change just the semantic stuff)-->
        <xsl:variable name="javatype" select="vf:JavaType(datatype/vodml-ref)"/>
        <xsl:variable name="name" select="tokenize(role/vodml-ref/text(),'[.]')[last()]"/>
          /*
          * <xsl:apply-templates select="$subsetted" mode="desc" />. Attribute <xsl:value-of select="$subsetted/name"/> : subsetted
          * IMPL - done with getter and setter.
          */
      </xsl:if>
    </xsl:template>


    <xsl:template match="constraint[ends-with(@xsi:type,':SubsettedRole')]" mode="getset">
        <xsl:variable name="subsetted" select="$models/key('ellookup',current()/role/vodml-ref)"/>
        <xsl:variable name="name" select="tokenize(role/vodml-ref/text(),'[.]')[last()]"/>
        <xsl:if test="name($subsetted)='attribute' and datatype/vodml-ref != $subsetted/datatype/vodml-ref"> <!-- only do this if types are different (subsetting can change just the semantic stuff)-->

        <xsl:if test="$do_jpa">
        <xsl:call-template name="doEmbeddedJPA">
            <xsl:with-param name="nillable" >true</xsl:with-param><!--TODO think if it is possible to do better with nillable value-->
        </xsl:call-template>

        @jakarta.persistence.Access(jakarta.persistence.AccessType.PROPERTY)
        </xsl:if>
        </xsl:if>
      <xsl:call-template name="doGetSet">
          <xsl:with-param name="name" select="$name"/>
          <xsl:with-param name="mult" select="$models/key('ellookup',current()/role/vodml-ref)/multiplicity"/>
      </xsl:call-template>

  </xsl:template>


  <xsl:template match="(attribute|composition[multiplicity/maxOccurs = 1])" mode="getset">
    <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
<!--      <xsl:message>attribute <xsl:value-of select="concat($vodml-ref,' from ', parent::*/name,' ', parent::*/@abstract, ' ', vf:isSubSetted($vodml-ref) )" /></xsl:message>-->
      <xsl:if test="not(parent::*/@abstract and vf:isSubSetted($vodml-ref))">
          <xsl:call-template name="doGetSet"/>
       </xsl:if>

   </xsl:template>

    <xsl:template name="doGetSet">
        <xsl:param name="name" select="name"/>
        <xsl:param name="type" select="vf:JavaType(datatype/vodml-ref)"/>
        <xsl:param name="mult" select="multiplicity"/>

        <xsl:variable name="upName">
            <xsl:call-template name="upperFirst">
                <xsl:with-param name="val" select="$name"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="fulltype">
            <xsl:choose>
                <xsl:when test="xsd:int($mult/maxOccurs) =-1"><xsl:value-of select="concat('java.util.List',$lt,$type,$gt)"/></xsl:when><!--TODO think about arrays -->
                <xsl:when test="xsd:int($mult/maxOccurs)  gt 1"><xsl:value-of select="concat($type,'[]')"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        /**
        * Returns <xsl:value-of select="$name"/> Attribute.
        * @return <xsl:value-of select="$name"/> Attribute
        */
        <xsl:if test="$mult/maxOccurs != 1">@SuppressWarnings("unchecked")</xsl:if><!--the cast should be ok even for the list-->
        public <xsl:value-of select="$fulltype"/>&bl;get<xsl:value-of select="$upName"/>() {
        return (<xsl:value-of select="$fulltype"/>)this.<xsl:value-of select="vf:javaMemberName($name)"/>;
        }
        <!-- cannot need to rely on most generic set if list of subsetted type, because of type erasure - IMPL might be able to do something clever with type argument on the base class, but gets tricky if there is more than one level of subclassing -->
        <xsl:if test="not(parent::*/extends and current()[ends-with(@xsi:type,':SubsettedRole')] and $mult/maxOccurs != 1)">
        /**
        * Set <xsl:value-of select="$name"/> Attribute.
        * @param p<xsl:value-of select="$upName"/> value to set
        */
        public void set<xsl:value-of select="$upName"/>(final <xsl:value-of select="$fulltype"/> p<xsl:value-of select="$upName"/>) {
        <xsl:if test="semanticconcept/vocabularyURI">
            <xsl:choose>
                <xsl:when test="$mult/maxOccurs = 1">
                    if (!<xsl:value-of select="concat(vf:modelJavaClass(current()),'.isInVocabulary(p',$upName,',',$dq,semanticconcept/vocabularyURI,$dq,')')"/>)
                    {
                    throw new IllegalArgumentException(p<xsl:value-of select="$upName"/>+" is not a value in vocabulary <xsl:value-of select="semanticconcept/vocabularyURI"/> ");
                    }

                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="concat($fulltype,' _i = p',$upName,'.stream().filter(i-> !',vf:modelJavaClass(current()),'.isInVocabulary(i,',$dq,semanticconcept/vocabularyURI,$dq,')).toList();')"/>
                   if(!_i.isEmpty()) {
                    throw new IllegalArgumentException(_i.stream().collect(java.util.stream.Collectors.joining(", ")) +" is not a value in vocabulary <xsl:value-of select="semanticconcept/vocabularyURI"/> ");
                    }
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        this.<xsl:value-of select="vf:javaMemberName($name)"/> = p<xsl:value-of select="$upName"/>;
        }
        </xsl:if>
        /**
        * fluent setter for <xsl:value-of select="$name"/> Attribute.
        * @param p<xsl:value-of select="$upName"/> value to set
        * @return <xsl:value-of select="current()/parent::*/name"/>
        */
        public <xsl:value-of select="vf:JavaType(vf:asvodmlref(parent::*))"/>&bl;with<xsl:value-of select="$upName"/>(final <xsl:value-of select="$fulltype"/> p<xsl:value-of select="$upName"/>) {
        set<xsl:value-of select="$upName"/>(p<xsl:value-of select="$upName"/>);
        return this;
        }

    </xsl:template>






  <xsl:template match="composition[multiplicity/maxOccurs != 1]" mode="declare">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
      <xsl:variable name="rt" select="$models/key('ellookup',datatype/vodml-ref)"/>

      /**
    * <xsl:apply-templates select="." mode="desc" />
    * composition <xsl:value-of select="name"/> :
    * (
    * Multiplicity : <xsl:apply-templates select="multiplicity" mode="tostring"/>
    * )
    */
    <xsl:apply-templates select="." mode="JAXBAnnotation"/>
      <xsl:if test="$do_jpa"><xsl:apply-templates select="." mode="JPAAnnotation"/></xsl:if>
    <xsl:call-template name="vodmlAnnotation"/>
      <xsl:apply-templates select="." mode="openapiAnnotation"/>
      <xsl:choose>
           <xsl:when test="vf:isSubSetted(vf:asvodmlref(.)) "><!--  or $rt/@abstract or vf:hasSubTypes(datatype/vodml-ref)-->
     protected java.util.List&lt;? extends <xsl:value-of select="$type"/>&gt;&bl;<xsl:value-of select="vf:javaMemberName(name)"/> = new java.util.ArrayList&lt;&gt;();
          </xsl:when>
          <xsl:otherwise>
     protected java.util.List&lt;<xsl:value-of select="$type"/>&gt;&bl;<xsl:value-of select="vf:javaMemberName(name)"/> = new java.util.ArrayList&lt;&gt;();
          </xsl:otherwise>
      </xsl:choose>

  </xsl:template>

    <xsl:template match="composition[multiplicity/maxOccurs = 1]" mode="declare">
        <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
        /**
        * <xsl:apply-templates select="." mode="desc" />
        * composition <xsl:value-of select="name"/> :
        * (
        * Multiplicity : <xsl:apply-templates select="multiplicity" mode="tostring"/>
        * )
        */
        <xsl:apply-templates select="." mode="JAXBAnnotation"/>
        <xsl:if test="$do_jpa"><xsl:apply-templates select="." mode="JPAAnnotation"/></xsl:if>
        <xsl:call-template name="vodmlAnnotation"/>
        <xsl:apply-templates select="." mode="openapiAnnotation"/>
        protected <xsl:value-of select="$type"/>&bl;<xsl:value-of select="vf:javaMemberName(name)"/> = null;
    </xsl:template>




    <!-- define methods for getting/setting and adding to/removing from composition -->
  <xsl:template match="composition[multiplicity/maxOccurs != 1]" mode="getset">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
    <xsl:variable name="name">
      <xsl:call-template name="upperFirst">
        <xsl:with-param name="val" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="datatype" select="substring-after(datatype/vodml-ref,':')"/>
    
    /**
    * Returns <xsl:value-of select="name"/> composition as an immutable list.
    * @return <xsl:value-of select="name"/> composition.
    */
      <xsl:choose>
      <xsl:when test="vf:isSubSetted(vf:asvodmlref(.))">
      public List&lt;? extends <xsl:value-of select="$type"/>&gt;&bl;get<xsl:value-of select="$name"/>() { // is subsetted
      </xsl:when>
      <xsl:otherwise>
      public List&lt;<xsl:value-of select="$type"/>&gt;&bl;get<xsl:value-of select="$name"/>() {
      </xsl:otherwise>
      </xsl:choose>
    return java.util.Collections.unmodifiableList(this.<xsl:value-of select="vf:javaMemberName(name)"/> != null?this.<xsl:value-of select="vf:javaMemberName(name)"/>: new ArrayList&lt;&gt;());
    }
    /**
    * Defines whole <xsl:value-of select="name"/> composition.
    * @param p<xsl:value-of select="$name"/> composition to set.
    */
    <xsl:choose>
        <xsl:when test="vf:isSubSetted(vf:asvodmlref(.))">
    public void set<xsl:value-of select="$name"/>(final java.util.List&lt;? extends <xsl:value-of select="$type"/>&gt; p<xsl:value-of select="$name"/>) {
        </xsl:when>
        <xsl:otherwise>
    public void set<xsl:value-of select="$name"/>(final java.util.List&lt;<xsl:value-of select="$type"/>&gt; p<xsl:value-of select="$name"/>) {
        </xsl:otherwise>
    </xsl:choose>
    this.<xsl:value-of select="vf:javaMemberName(name)"/> = p<xsl:value-of select="$name"/>;
    }
    <xsl:if test="not(vf:isSubSetted(vf:asvodmlref(.)))">
    /**
    * Add a <xsl:value-of select="$type"/> to the composition.
    * @param p&bl;<xsl:value-of select="$type"/> to add
    */
    public void addTo<xsl:value-of select="$name"/>(final <xsl:value-of select="$type"/> p) {
      if(this.<xsl:value-of select="vf:javaMemberName(name)"/> == null) {
        this.<xsl:value-of select="vf:javaMemberName(name)"/> = new ArrayList&lt;&gt;();
      }
      this.<xsl:value-of select="vf:javaMemberName(name)"/>.add(p);
    }
    /**
    * Remove a <xsl:value-of select="$type"/> from the composition.
    * @param p&bl;<xsl:value-of select="$type"/> to remove
    */
    public void removeFrom<xsl:value-of select="$name"/>(final <xsl:value-of select="$type"/> p) {
        if(this.<xsl:value-of select="vf:javaMemberName(name)"/> != null) {
            this.<xsl:value-of select="vf:javaMemberName(name)"/>.remove(p);
        }

    }
        /**
        * update a <xsl:value-of select="$type"/> in the composition.
        * @param _p&bl;<xsl:value-of select="$type"/> to update
        * the match is done via the database key
        */
        public void replaceIn<xsl:value-of select="$name"/>(final <xsl:value-of select="$type"/> _p) {
        if(this.<xsl:value-of select="vf:javaMemberName(name)"/> != null) {
        for (<xsl:value-of select="$type"/> _l : this.<xsl:value-of select="vf:javaMemberName(name)"/>) {
        if(_l.getId().equals(_p.getId())) {
           _l.updateUsing(_p);
           return;
        }
        }
        throw new IllegalArgumentException("entry not found in composition");
        }
        else
        throw new IllegalStateException("there is no exiting entry in the composition");
        }
    </xsl:if>
  </xsl:template>

    <xsl:template match="objectType" mode="jpawalker">

    @Override
    public void forceLoad() {
    <xsl:apply-templates select="composition|reference" mode="jpawalker"/><!-- IMPL dtypes can have references which might contain compositions - requires looking in all attributes - assume that top level will do that -->
       <xsl:if test="extends">
       super.forceLoad();
       </xsl:if>
    }
    </xsl:template>

    <xsl:template match="(composition[multiplicity/maxOccurs != 1]|reference[multiplicity/maxOccurs != 1])" mode="jpawalker">
       if( <xsl:value-of select="vf:javaMemberName(name)"/> != null ) {
        for( <xsl:value-of select="vf:FullJavaType(datatype/vodml-ref, true())"/> c : <xsl:value-of select="vf:javaMemberName(name)"/> ) {
           c.forceLoad();
        }
       }
    </xsl:template>
    <xsl:template match="composition|reference" mode="jpawalker">
        if( <xsl:value-of select="vf:javaMemberName(name)"/> != null ) <xsl:value-of select="vf:javaMemberName(name)"/>.forceLoad();
    </xsl:template>
    <xsl:template match="dataType" mode="jpawalker">
        @Override
        public void forceLoad() {
        <xsl:apply-templates select="reference" mode="jpawalker"/><!-- IMPL dtypes can have references which might contain compositions  -->
        <xsl:if test="extends">
            super.forceLoad();
        </xsl:if>
        }
    </xsl:template>

<!-- jparefs-->
    <xsl:template match="objectType|dataType" mode="jparefs">
        /**
        * {@inheritDoc}
        * @deprecated generally better to use the model level reference persistence as only this can deal with "contained" references properly. */
        @Override
        @Deprecated
        public void persistRefs(jakarta.persistence.EntityManager _em) {
          <xsl:variable name="localdefs" select="vf:javaLocalDefines(vf:asvodmlref(current()))"/>
          <xsl:apply-templates select="composition[vf:asvodmlref(.) = $localdefs]
                          |reference[vf:asvodmlref(.) = $localdefs]
                          |attribute[vf:attributeIsDtype(.) and vf:asvodmlref(.) = $localdefs]
                          |constraint[ends-with(@xsi:type,':SubsettedRole') and
                          role[vodml-ref = $localdefs]]" mode="jparefs"/>
          <xsl:if test="extends">super.persistRefs(_em);</xsl:if>
          <xsl:if test="vf:referredTo(vf:asvodmlref(current())) and not(extends)">
              _em.persist(this);
          </xsl:if>
        }
    </xsl:template>
    <xsl:template match="composition[multiplicity/maxOccurs != 1]|attribute[multiplicity/maxOccurs != 1]|reference[multiplicity/maxOccurs != 1]" mode="jparefs" >
        if( <xsl:value-of select="vf:javaMemberName(name)"/> != null ) {
          for( <xsl:value-of select="vf:FullJavaType(datatype/vodml-ref, true())"/> _c : <xsl:value-of select="vf:javaMemberName(name)"/> ) {
            _c.persistRefs(_em);
          }
        }

    </xsl:template>
    <xsl:template match="composition|reference|attribute" mode="jparefs">
        if( <xsl:value-of select="vf:javaMemberName(name)"/> != null ) <xsl:value-of select="vf:javaMemberName(name)"/>.persistRefs(_em);
    </xsl:template>
    <xsl:template match="constraint[ends-with(@xsi:type,':SubsettedRole')]" mode="jparefs">
        <xsl:variable name="ss" select="$models/key('ellookup',current()/role/vodml-ref)"/>
        if( <xsl:value-of select="vf:javaMemberName($ss/name)"/> != null ) <xsl:value-of select="vf:javaMemberName($ss/name)"/>.persistRefs(_em);
    </xsl:template>






  <xsl:template match="reference" mode="declare">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
    /** 
    * ReferenceObject <xsl:value-of select="name"/> :
    * <xsl:apply-templates select="." mode="desc" />
    * (
    * Multiplicity : <xsl:apply-templates select="multiplicity" mode="tostring"/>
    * )
    */
      <xsl:if test="$do_jpa"><xsl:apply-templates select="." mode="JPAAnnotation"/></xsl:if>
    <xsl:apply-templates select="." mode="JAXBAnnotation"/>
    <xsl:call-template name="vodmlAnnotation"/>
      <xsl:apply-templates select="." mode="openapiAnnotation"/>
      <xsl:choose>
          <xsl:when test="xsd:int(multiplicity/maxOccurs) lt 0"> <!-- IMPL are allowing for multiplicity > 1 i.e. aggregation-->
              protected <xsl:value-of select="concat('java.util.List',$lt,$type,$gt,' ',vf:javaMemberName(name))"/>;
          </xsl:when>
          <xsl:otherwise>
              protected <xsl:value-of select="$type"/>&bl;<xsl:value-of select="vf:javaMemberName(name)"/> = null;
          </xsl:otherwise>
      </xsl:choose>

  </xsl:template>




  <xsl:template match="reference[multiplicity/maxOccurs = 1]" mode="getset">
    <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
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
        return this.<xsl:value-of select="vf:javaMemberName(name)"/>;
    }
    /**
    * Defines <xsl:value-of select="name"/> Reference
    * @param p<xsl:value-of select="$name"/> reference to set
    */
    public void set<xsl:value-of select="$name"/>(final <xsl:value-of select="$type"/> p<xsl:value-of select="$name"/>) {
        this.<xsl:value-of select="vf:javaMemberName(name)"/> = p<xsl:value-of select="$name"/>;
    }
  </xsl:template>

    <xsl:template match="reference[multiplicity/maxOccurs != 1]" mode="getset"> <!-- IMPL could use the same rule as composition? -->
        <xsl:variable name="type" select="vf:JavaType(datatype/vodml-ref)"/>
        <xsl:variable name="name">
            <xsl:call-template name="upperFirst">
                <xsl:with-param name="val" select="name"/>
            </xsl:call-template>
        </xsl:variable>
        /**
        * Returns <xsl:value-of select="name"/> Reference<br/>
        * @return <xsl:value-of select="name"/> Reference
        */
        public java.util.List&lt;<xsl:value-of select="$type"/>&gt;&bl;get<xsl:value-of select="$name"/>() {
        return this.<xsl:value-of select="vf:javaMemberName(name)"/>;
        }
        /**
        * Defines <xsl:value-of select="name"/> Reference
        * @param p<xsl:value-of select="$name"/> references to set
        */
        public void set<xsl:value-of select="$name"/>(final java.util.List&lt;<xsl:value-of select="$type"/>&gt; p<xsl:value-of select="$name"/>) {
        this.<xsl:value-of select="vf:javaMemberName(name)"/> = p<xsl:value-of select="$name"/>;
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
    @jakarta.xml.bind.annotation.XmlEnumValue("<xsl:value-of select="name"/>")
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
      <xsl:when test="count(description) > 0 and normalize-space(description) != 'TODO : Missing description : please, update your UML model asap.'">
          <xsl:value-of select="description" disable-output-escaping="yes"/>
          <xsl:if test="not(ends-with(normalize-space(description/text()), '.'))">
              <xsl:value-of select="'.'"/>
          </xsl:if>
      </xsl:when>
      <xsl:otherwise>
<!--       <xsl:message >TODO : <xsl:value-of select="name"/> Missing description : please, update your VO-DML model asap.</xsl:message> -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>  




  <!-- specific documents --> 

  <!-- ModelVersion.java - deprecated -->
  <xsl:template match="vo-dml:model" mode="modelFactory">
    <xsl:param name="root_package"/>
    <xsl:param name="root_package_dir"/>
    <xsl:variable name="file" select="concat($output_root,'/', $root_package_dir,'/','ModelFactory.java')"/>
    <!-- open file for this class -->
    <xsl:message >Writing Factory file <xsl:value-of select="$file"/></xsl:message>
    <xsl:result-document href="{$file}">package <xsl:value-of select="$root_package"/>;
      <xsl:if test="descendant-or-self::objectType|descendant-or-self::dataType">
      import <xsl:value-of select="$vo-dml_package"/>.StructuredObject;
      </xsl:if>
      /**
      * Factory class for model <xsl:value-of select="name"/>.
      *
      * <xsl:apply-templates select="." mode="desc" />
      *
      * <xsl:value-of select="$vodmlauthor"/>
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
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
            <xsl:variable name="type" select="vf:QualifiedJavaType($vodml-ref)"/>

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
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
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
            <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
            <xsl:variable name="type" select="vf:QualifiedJavaType($vodml-ref)"/>
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
      <xsl:param name="path"/>
    <xsl:variable name="file" select="concat($output_root,'/',$dir,'/package.html')"/>
    <!-- open file for this class -->
    <xsl:message >Writing package file <xsl:value-of select="$file"/></xsl:message>
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
      <xsl:variable name="file" select="concat($output_root,'/',$dir,'/package-info.java')"/>
      <!-- open file for this class -->
      <xsl:message >Writing package info file <xsl:value-of select="$file"/></xsl:message>
      <xsl:variable name="ns" select="$mapping/bnd:mappedModels/model[name=current()/ancestor-or-self::vo-dml:model/name]/xml-targetnamespace"/>
      <xsl:variable name="elformdefault">
          <xsl:choose>
              <xsl:when test="vf:XMLqualified(current()/ancestor-or-self::vo-dml:model/name)"><xsl:value-of select="'QUALIFIED'"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="'UNQUALIFIED'"/></xsl:otherwise>
          </xsl:choose>
      </xsl:variable>
      <xsl:result-document href="{$file}" >

/**
* package <xsl:value-of select="name"/>.
*   <xsl:apply-templates select="." mode="desc" />
*/
@jakarta.xml.bind.annotation.XmlSchema(namespace = "<xsl:value-of select="normalize-space($ns)"/>",elementFormDefault=XmlNsForm.<xsl:value-of select="$elformdefault"/>, xmlns = {
@jakarta.xml.bind.annotation.XmlNs(namespaceURI = "<xsl:value-of select="normalize-space($ns)"/>", prefix = "<xsl:value-of select="$ns/@prefix"/>")
  })
package <xsl:value-of select="$path"/>;
import jakarta.xml.bind.annotation.XmlNsForm;
      </xsl:result-document>

  </xsl:template>


  <xsl:template name="TypeImport">
    <xsl:param name="vodml-ref"/>
 <!--
        <xsl:message>Looking for vodml-ref <xsl:value-of select="$vodml-ref"/></xsl:message>
 -->    
    <xsl:variable name="vodml-id" select="substring-after($vodml-ref,':')"/>
    <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'java')" />

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
         <xsl:variable name="root" select="$mapping/bnd:mappedModels/model[name=$themodel/name]/java-package" />
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
    <xsl:variable name="root" select="$mapping/bnd:mappedModels/model[name=$modelname]/java-package"/>
    <xsl:value-of select="$root"/><xsl:if test="$path !=''">.</xsl:if><xsl:value-of select="$path"/>.<xsl:value-of select="name"/>
  </xsl:template>

  <xsl:template name="vodmlAnnotation">
      <xsl:choose>
          <xsl:when test="name(current()) = ('attribute', 'composition', 'reference')">
@org.ivoa.vodml.annotation.VoDml(id="<xsl:value-of select='concat(ancestor::vo-dml:model/name,":",vodml-id)'/>", role=org.ivoa.vodml.annotation.VodmlRole.<xsl:value-of select='name(.)'/>, type="<xsl:value-of select="datatype/vodml-ref"/>",typeRole=org.ivoa.vodml.annotation.VodmlRole.<xsl:value-of select="vf:typeRole(datatype/vodml-ref)"/>)
          </xsl:when>
          <xsl:otherwise>
@org.ivoa.vodml.annotation.VoDml(id="<xsl:value-of select='concat(ancestor::vo-dml:model/name,":",vodml-id)'/>", role=org.ivoa.vodml.annotation.VodmlRole.<xsl:value-of select='name(.)'/>)
          </xsl:otherwise>
      </xsl:choose>
 </xsl:template>
    <xsl:template match="*" mode="openapiAnnotation">
        <xsl:variable name="AllowedSymbols" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789()*%$#@!,.?[]=- +   /\'''"/>

        @org.eclipse.microprofile.openapi.annotations.media.Schema(description="<xsl:if test="current()/name()='reference'"><xsl:value-of
            select="'A reference to - '"/></xsl:if><xsl:value-of select="translate(string-join(for $s in description/text() return normalize-space($s),' '),'&quot;','''')"/>")
    </xsl:template>


</xsl:stylesheet>
