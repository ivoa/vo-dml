<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY cr "<xsl:text>
</xsl:text>">
<!ENTITY bl "<xsl:text> </xsl:text>">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1">

<xsl:include href="common.xsl"/>

<xsl:key name="ellookup" match="//*[vodml-id]" use="concat(ancestor::vo-dml:model/name,':',vodml-id)"/>
<xsl:key name="maplookup" match="type-mapping[vodml-id]" use="concat(ancestor::model/name,':',vodml-id)"/>

  <xsl:param name="targetnamespace_root"/>

  <xsl:template match="vo-dml:model" mode="xsd-path">
    <xsl:param name="delimiter"/>
    <xsl:param name="suffix" select="''"/>
    <xsl:value-of select="concat(vodml-id,$suffix)"/>
  </xsl:template>

  <xsl:template match="package" mode="xsd-path">
    <xsl:param name="delimiter"/>
    <xsl:param name="suffix" select="''"/>
    <xsl:variable name="newsuffix">
      <xsl:value-of select="concat($delimiter,./name,$suffix)"/>
    </xsl:variable>
    <xsl:apply-templates select=".." mode="xsd-path">
       <xsl:with-param name="suffix" select="$newsuffix"/>
       <xsl:with-param name="delimiter" select="$delimiter"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- return the targetnamespace for the schema document for the package with the given id -->
  <xsl:template name="namespace-for-package">
    <xsl:param name="model" select="ancestor-or-self::vo-dml:model"/>
    <xsl:param name="packageid"/>
    <xsl:variable name="path">
      <xsl:call-template name="package-path">
        <xsl:with-param name="model" select="$model"/>
        <xsl:with-param name="packageid" select="$packageid"/>
        <xsl:with-param name="delimiter" select="'/'"/>
      </xsl:call-template>
    </xsl:variable>    
    <xsl:value-of select="concat($targetnamespace_root,'/',$path)"/>
  </xsl:template>
  


  <!-- calculate a prefix for the package with the given id -->
  <xsl:template name="package-prefix">
    <xsl:param name="packageid"/>
    <xsl:variable name="rank">
      <xsl:value-of select="count(/*//package[@xmiid &lt; $packageid])+1"/>
    </xsl:variable>
    <xsl:value-of select="concat('p',$rank)"/>
  </xsl:template>



  <!-- calculate a prefix for the given object -->
  <xsl:template match="objectType" mode="package-prefix">
    <xsl:call-template name="package-prefix">
      <xsl:with-param name="packageid" select="./ancestor::package[1]/@xmiid"/>
    </xsl:call-template>
  </xsl:template>


  

  
<!--  Do we potentially want to generate root elements even for dadaType-s?
See similar comment in jaxb.xsl:  <xsl:template match="objectType|dataType" mode="JAXBAnnotation">
 -->
  <xsl:template match="objectType|dataType" mode="root-element-name">
      <xsl:variable name="firstletterisvowel" select="translate(substring(name,1,1),'AEIOU','11111')"/>
      <xsl:variable name="article">
        <xsl:choose>
          <xsl:when test="$firstletterisvowel = '1'" >
            <xsl:text>an</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>a</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="concat($article,name)"/>
  </xsl:template>
  
   <xsl:template name="getmodel">
    <xsl:param name="vodml-ref"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
    <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>
    <xsl:if test="not($modelname) or $modelname=''">
      <xsl:message>!!!!!!! ERROR No prefix found in findmapping for <xsl:value-of select="$vodml-ref"/></xsl:message>
    </xsl:if>
    <xsl:copy-of select="$models/vo-dml:model[name=$modelname]"/>
    </xsl:template>

    <xsl:function name="vf:JavaType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:value-of select="vf:FullJavaType($vodml-ref,true())"/>
    </xsl:function>
    <xsl:function name="vf:QualifiedJavaType" as="xsd:string">
    <xsl:param name="vodml-ref" as="xsd:string"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
        <xsl:value-of select="vf:FullJavaType($vodml-ref,true())"/>
    </xsl:function>
    <!-- find JavaType for given vodml-ref, starting from provided model element -->
  <xsl:function name="vf:FullJavaType" as="xsd:string">
    <xsl:param name="vodml-ref" as="xsd:string"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
    <xsl:param name="fullpath" as="xsd:boolean"/>
      <xsl:variable name="type">
          <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'java')"/>
          <xsl:choose>
              <xsl:when test="$mappedtype != ''">
                  <xsl:value-of select="$mappedtype"/>
              </xsl:when>
              <xsl:otherwise>
                  <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>

                  <xsl:variable name="root" select="$mapping/bnd:mappedModels/model[name=$modelname]/java-package"/>
                  <xsl:variable name="path"
                                select="string-join($models/key('ellookup',$vodml-ref)/ancestor-or-self::*[name() != 'vo-dml:model']/name,'.')"/>
                  <xsl:value-of select="concat($root,'.',$path)"/>
              </xsl:otherwise>
          </xsl:choose>
      </xsl:variable>
      <xsl:choose>
          <xsl:when test="$fullpath">
              <xsl:value-of select="$type"/>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="tokenize($type,'\.')[last()]"/>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:function>
    <xsl:function name="vf:PythonType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:value-of select="vf:FullPythonType($vodml-ref,false())"/>
    </xsl:function>
    <xsl:function name="vf:FullPythonType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
        <xsl:param name="fullpath" as="xsd:boolean"/>
        <xsl:variable name="type">
            <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'python')"/>
            <xsl:choose>
                <xsl:when test="$mappedtype != ''">
                    <xsl:value-of select="$mappedtype"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>

                    <xsl:variable name="root" select="$mapping/bnd:mappedModels/model[name=$modelname]/python-package"/>
                    <xsl:variable name="path"
                                  select="string-join($models/key('ellookup',$vodml-ref)/ancestor-or-self::package/name,'_')"/>
                    <xsl:value-of select="concat($root,'.',$path,'.',$models/key('ellookup',$vodml-ref)/name)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$fullpath">
                <xsl:value-of select="$type"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="tokenize($type,'\.')[last()]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="vf:PythonModule" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
        <xsl:choose>
            <xsl:when test="vf:hasMapping($vodml-ref,'python')">
                <xsl:value-of select="string-join(tokenize(vf:findmapping($vodml-ref,'python'),'\.')[position() != last()],'.')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="root" select="$mapping/bnd:mappedModels/model[name=$modelname]/python-package"/>

                <xsl:variable name="path"
                              select="string-join($models/key('ellookup',$vodml-ref)/(ancestor::package|ancestor::vo-dml:model)/name,'_')"/>
                <xsl:value-of select="concat($root,'.',$path)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:PythonImportedType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="vf:hasMapping($vodml-ref,'pythom')">
                <xsl:value-of select="string-join(tokenize(vf:findmapping($vodml-ref,'python'),'\.')[position() > last() -1],'.')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="path"
                              select="string-join($models/key('ellookup',$vodml-ref)/ancestor::package/name,'_')"/>
                <xsl:value-of select="concat($path,'.',$models/key('ellookup',$vodml-ref)/name)"/>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>



    <!-- it would be better if this function was not needed and every vodml-id also contained the model prefix - or vodml-id removed entirely... -->
    <xsl:function name="vf:asvodmlref" as="xsd:string">
        <xsl:param name="el" as="element()"/>
        <xsl:value-of select="concat($el/ancestor::vo-dml:model/name,':',$el/vodml-id/text())"/>
    </xsl:function>

    <xsl:function name="vf:isOptional" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="number($el/multiplicity/minOccurs) = 0 and number($el/multiplicity/maxOccurs) = 1" />
    </xsl:function>
    <xsl:function name="vf:isArrayLike" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="number($el/multiplicity/minOccurs) >  1 and number($el/multiplicity/maxOccurs) > 1" />
    </xsl:function>


    <xsl:function name="vf:isRdbSingleTable" as="xsd:boolean">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:sequence select="count($mapping/bnd:mappedModels/model[name=$modelName]/rdb[@inheritance-strategy='single-table'] )= 1"/>
    </xsl:function>


    <!-- this function should be avoided as it only returns a copy of the asked for element - i.e. the element is not in context of model -->
   <xsl:function name="vf:Element4vodml-ref" as="element()">
      <xsl:param name="vodml-ref" as="xsd:string" />
      <xsl:variable name="prefix" select="substring-before($vodml-ref,':')" />
      <xsl:if test="not($prefix) or $prefix=''">
         <xsl:message terminate="yes">!!!!!!! ERROR No prefix found in Element4vodml-ref for <xsl:value-of select="$vodml-ref" /></xsl:message>
      </xsl:if>
      <xsl:choose>
         <xsl:when test="$models/key('ellookup',$vodml-ref)">
            <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
         </xsl:when>
         <xsl:otherwise>
           <xsl:message terminate="yes">**ERROR** failed to find '<xsl:value-of select="$vodml-ref" />'</xsl:message>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

    <xsl:function name="vf:findmapping" as="element()?"><!-- note allowed empty sequence -->
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:param name="lang" as="xsd:string"/>
        <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
        <xsl:choose>
            <xsl:when test="$lang eq 'java'">
                <xsl:copy-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/java-type"/>
            </xsl:when>
            <xsl:when test="$lang eq 'python'">
                <xsl:copy-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/python-type"/>
            </xsl:when>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="vf:hasMapping" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:param name="lang" as="xsd:string" />
        <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
        <xsl:choose>
            <xsl:when test="$lang eq 'java'">
                <xsl:value-of select="count($mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/java-type) > 0"/>
            </xsl:when>
            <xsl:when test="$lang eq 'python'">
                <xsl:value-of select="count($mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/python-type) > 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">unknown language <xsl:value-of select="$lang"/> </xsl:message>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>
    <xsl:function name="vf:isPythonBuiltin" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
        <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/python-type/@built-in = 'true'"/>
    </xsl:function>

<!-- return the base types for current type - note that this does not return the types in strict hierarchy order (not sure why!) -->
    <xsl:function name="vf:baseTypes" as="element()*">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                 <xsl:variable name="el" as="element()">
                     <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                 </xsl:variable>
                 <xsl:choose>
                     <xsl:when test="$el/extends">
                         <xsl:sequence select="($models/key('ellookup',$el/extends/vodml-ref),vf:baseTypes($el/extends/vodml-ref))" />
                     </xsl:when>
                 </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models for base types</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <!--just returning the IDs will work in hierarchy order, but then need to use in for-each -->
    <xsl:function name="vf:baseTypeIds" as="xsd:string*">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$el/extends">
                        <xsl:sequence select="($el/extends/vodml-ref,vf:baseTypeIds($el/extends/vodml-ref))"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models for base types</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>


    <xsl:function name="vf:subTypes" as="element()*">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="count($models//extends[vodml-ref = $vodml-ref])> 0">
                        <xsl:for-each select="$models//*[extends/vodml-ref = $vodml-ref]">
<!--                            <xsl:message><xsl:value-of select="concat('subtype of ',$vodml-ref, ' is ', name)" /></xsl:message>-->
                        <xsl:sequence select="(.,vf:subTypes(vf:asvodmlref(.)))"/>
                        </xsl:for-each>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <!-- this means does the model have children in inheritance hierarchy -->
    <xsl:function name="vf:hasSubTypes" as="xsd:boolean">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:value-of select="count($models//extends[vodml-ref = $vodml-ref])> 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="vf:hasSuperTypes" as="xsd:boolean">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:value-of select="count($models//extends[vodml-ref = $vodml-ref])> 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- is the type (or supertypes) contained anywhere -->
    <xsl:function name="vf:isContained" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
<!--                <xsl:message>contained <xsl:value-of select="concat($vodml-ref, ' ', count($models//(attribute|composition)/datatype[vodml-ref=$vodml-ref])>0)"/> </xsl:message>-->
                <xsl:choose>
                    <xsl:when test="not($el/extends)">
                        <xsl:value-of select="count($models//(attribute|composition)/datatype[vodml-ref=$vodml-ref])>0"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="count($models//(attribute|composition)/datatype[vodml-ref=$vodml-ref])>0 or vf:isContained($el/extends/vodml-ref)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>




    <!-- is the type used as a reference -->
    <xsl:function name="vf:referredTo" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>

        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                  <xsl:variable name="hier" as="xsd:string *">
                      <xsl:sequence>
                      <xsl:for-each  select="(vf:baseTypes($vodml-ref),$models/key('ellookup',$vodml-ref),vf:subTypes($vodml-ref))">
                          <xsl:value-of select="vf:asvodmlref(.)"/>
                      </xsl:for-each>
                      </xsl:sequence>
                  </xsl:variable>
<!--                <xsl:message>refs <xsl:value-of select="concat ($vodml-ref,' ',count($models//reference/datatype[vodml-ref = $hier])> 0,' h=',string-join($hier,','))"/></xsl:message>-->
                <xsl:value-of select="count($models//reference/datatype[vodml-ref = $hier])> 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:referencesInHierarchy" as="xsd:string*">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <xsl:sequence select="$el/reference/datatype/vodml-ref"/>
                <xsl:for-each select="$el/composition/datatype/vodml-ref">
                    <!--                            <xsl:message><xsl:value-of select="concat('subtype of ',$vodml-ref, ' is ', name)" /></xsl:message>-->
                    <xsl:sequence select="vf:referencesInHierarchy(.)"/>
                </xsl:for-each>
              </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <!-- is the attribute subsetted - for it to be truly subsetted it needs to be subtyped too-->
    <xsl:function name="vf:isSubSetted" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">

                <!--note that comparison below ignores vodml namespace prefix - slightly dangerous, but only slightly -->
                <!-- also note that the datatype checking is just done on not exact equivalence, not if strictly a subtype -->
                <xsl:value-of select="count($models//*[constraint[ends-with(@xsi:type,':SubsettedRole') and
                          role[vodml-ref = $vodml-ref] and datatype[vodml-ref != $models/key('ellookup',$vodml-ref)/datatype/vodml-ref ]]])> 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:isSubSettedInHierarchy" as="xsd:boolean">
        <xsl:param name="type"  as="xsd:string" />
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="subsets" select="vf:subSettingInSuperHierarchy($type)" as="element()*"/>
        <xsl:message>is_ssinhier <xsl:value-of select="concat('type=',$type, ' ref=', $vodml-ref)"/>"</xsl:message>
        <xsl:value-of select="count($subsets[role/vodml-ref = $vodml-ref]) > 0" />
    </xsl:function>

    <!-- This will return all the subsets found in the hierarchy - will not return subset when it is the same type as the thing it subsets -
     qlso should take care of multiple levels of subsetting...-->
    <xsl:function name="vf:subSettingInSuperHierarchy" as="element()*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
<!--        <xsl:message select="concat('subsetting in hierarchy for=',$vodml-ref)"/>-->
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <!-- have to do this to get types in hierarchical order -->
                <xsl:variable name="typenames" as="xsd:string*" select="($vodml-ref,vf:baseTypeIds($vodml-ref))"/>
                <!-- TODO need to worry about the cases where a subset is subset again -->
                <xsl:variable name="allsubsets"  as="element()*">
                    <xsl:for-each select="$typenames">
                        <xsl:copy-of select="$models/key('ellookup',current())/constraint[ends-with(@xsi:type,':SubsettedRole')]"/>
                    </xsl:for-each>
                </xsl:variable>
<!--                <xsl:message>supertypenames=<xsl:value-of select="string-join($typenames,',')"/> subsets=<xsl:value-of select="string-join(for $x in $allsubsets return string-join(($x/role/vodml-ref,$x/datatype/vodml-ref),'|'),',')"/></xsl:message>-->
                    <!-- cannot see hy this will not work - actually because of the context in key() call
                   <xsl:copy-of select="$allsubsets[datatype/vodml-ref != $models/key('ellookup',role/vodml-ref)/datatype/vodml-ref]"/>
                    so doing for loop below-->
                   <xsl:for-each select="$allsubsets">
                       <xsl:variable name="subsetted" select="$models/key('ellookup',current()/role/vodml-ref)/datatype/vodml-ref"/>
                       <xsl:if test="current()/datatype/vodml-ref/text() != $subsetted">
                           <xsl:copy-of select="."/>
                       </xsl:if>
                   </xsl:for-each>
              </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <!-- This will return all the subsets found in the sub hierarchy - will not return subset when it is the same type as the thing it subsets (happens when the only reason for the subset is semantic constaint?)
    In addition does not return subsets for composition

    FIXME - this needs to only return the subsets for members of the starting point.
  -->
    <xsl:function name="vf:subSettingInSubHierarchy" as="element()*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
<!--                <xsl:message select="concat('subsetting in hierarchy for=',$vodml-ref)"/>-->
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="locals" as="xsd:string*">
                    <xsl:for-each select="$models/key('ellookup',$vodml-ref)/(attribute|composition|reference)"><xsl:value-of select="vf:asvodmlref(current())"/></xsl:for-each>
                </xsl:variable>
<!--                <xsl:message select="concat('sslocals=', string-join($locals,','))"/>-->
                <xsl:variable name="allsubsets" select="vf:subTypes($vodml-ref)/constraint[ends-with(@xsi:type,':SubsettedRole') and role/vodml-ref = $locals]" as="element()*"/>
<!--                <xsl:message>sssubtypes=<xsl:value-of select="string-join(vf:subTypes($vodml-ref)/name,',')"/> subsets=<xsl:value-of select="string-join($allsubsets/role/vodml-ref,',')"/></xsl:message>-->

                <!-- cannot see hy this will not work - actually because of the context in key() call
               <xsl:copy-of select="$allsubsets[datatype/vodml-ref != $models/key('ellookup',role/vodml-ref)/datatype/vodml-ref]"/>
                so doing for loop below-->
                <xsl:for-each select="$allsubsets">
                    <xsl:variable name="subsetted" select="$models/key('ellookup',current()/role/vodml-ref)"/>
                    <xsl:if test="$subsetted/datatype/vodml-ref != current()/datatype/vodml-ref">
                        <xsl:copy-of select="."/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <!--
     Returns a list of vomdml refs for the Object/DataType members that should be declared locally to a particular Class in Java. It applies
     some heuristics to try to push declarations as far down the Java class inheritance hierarchy as possible to
     have as much type safety as possible - this is particularly applied in the case of subsetting.
    -->
    <xsl:function name="vf:javaLocalDefines" as="xsd:string*">

        <xsl:param name="vodml-ref" as="xsd:string"/>
<!--        <xsl:message select="concat('javalocals for ',$vodml-ref)"/>-->
        <xsl:variable name="m" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:variable name="localdefs" select="for $v in $m/(attribute,composition,reference) return vf:asvodmlref($v)"/>
        <xsl:variable name="subsubs" select="vf:subSettingInSubHierarchy($vodml-ref)"/>
        <xsl:choose>
            <xsl:when test="$m and $m/name() = ('objectType','dataType')">
                <xsl:sequence>
                    <xsl:choose>
                        <xsl:when test="$m/@abstract">
                            <xsl:for-each select="$m/(attribute[not(vf:asvodmlref(.) = $subsubs/role/vodml-ref)],composition,reference)">
                                <xsl:value-of select="vf:asvodmlref(current())"/>
                           </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="$m/(attribute,composition,reference)">
                                <xsl:value-of select="vf:asvodmlref(current())"/>
                            </xsl:for-each>
<!--                            <xsl:message>localsub==<xsl:value-of select="$models/key('ellookup',$m/constraint[ends-with(@xsi:type,':SubsettedRole')]/role/vodml-ref)/parent::*/@abstract"/> </xsl:message>-->
                            <xsl:for-each select="$m/constraint[ends-with(@xsi:type,':SubsettedRole')]">
                                <xsl:if test="$models/key('ellookup',current()/role/vodml-ref)/parent::*/@abstract and $models/key('ellookup',current()/role/vodml-ref)/name() = 'attribute'"> <!-- TODO this was a fairly arbitrary rule - not sure that it is necessary. -->
                                <xsl:value-of select="current()/role/vodml-ref"/>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:sequence>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models or wrong type (<xsl:value-of select="$m/name()"/>) </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- returns the vodml-refs of the members including inherited ones for java purposes -->
    <xsl:function name="vf:javaAllMembers" as="xsd:string*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="supers" select="($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref))"/>
<!--        <xsl:message select="concat('allmember=',$vodml-ref, ' supers=', string-join($supers/name,','))"/>-->
            <xsl:sequence select="for $s in $supers return vf:javaLocalDefines(vf:asvodmlref($s))"/>
    </xsl:function>


    <xsl:function name="vf:importedModelNames" as="xsd:string*">
        <xsl:param name="model" as="element()"/>
        <xsl:for-each select="$model/import">  <!--TODO  implement recursive model lookup (still not sure it this is expected see https://github.com/ivoa/vo-dml/issues/7) -->
            <xsl:value-of select="document(url)/vo-dml:model/name"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="vf:upperFirst" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="concat(upper-case(substring($s,1,1)),substring($s,2))"/>
    </xsl:function>
    <xsl:function name="vf:lowerFirst" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="concat(lower-case(substring($s,1,1)),substring($s,2))"/>
    </xsl:function>

    <xsl:function name="vf:utype" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <!--        <xsl:message select="concat('subsetting in hierarchy for=',$vodml-ref)"/>-->
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
                <xsl:value-of select="$vodml-ref"/><!-- TODO is this true? -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="vf:typeRole" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <!--        <xsl:message select="concat('subsetting in hierarchy for=',$vodml-ref)"/>-->
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:value-of select="$models/key('ellookup',$vodml-ref)/name()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- returns the vodml-refs of the members including inherited ones -->
    <xsl:template name="allInheritedMembers" as="xsd:string*">
        <xsl:variable name="vodml-ref" select="vf:asvodmlref(.)"/>
        <xsl:variable name="supers" select="(.,vf:baseTypes($vodml-ref))"/>
        <!--        <xsl:message>inherited <xsl:value-of select="concat($vodml-ref, ' subsets=',string-join($subsets,','),' members=',-->
        <!--        string-join(for $v in ($supers/attribute,$supers/composition,$supers/reference) return vf:asvodmlref($v), ',') )" /></xsl:message>-->
        <xsl:sequence>
            <xsl:for-each select="$supers/attribute,$supers/composition,$supers/reference">
                <xsl:value-of select="vf:asvodmlref(.)"/>
            </xsl:for-each>
        </xsl:sequence>
    </xsl:template>
    <xsl:function name="vf:ns4model" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$s]/xml-targetnamespace"/>
    </xsl:function>
    <xsl:function name="vf:nsprefix4model" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$s]/xml-targetnamespace/@prefix"/>
    </xsl:function>
    <xsl:function name="vf:schema-location4model" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="concat($s, 'xsd')"/>
    </xsl:function>
    <xsl:function name="vf:modelNameFromFile" as="xsd:string"><!-- note allowed empty sequence -->
        <xsl:param name="filename" as="xsd:string"/>
        <xsl:value-of select="$mapping/bnd:mappedModels/model[file=$filename]/name"/>
    </xsl:function>
    <xsl:function name="vf:element4vodmlref" as="element()"> <!-- once rest of code working - can remove this and just use key directly -->
        <xsl:param name="vodml-ref" as="xsd:string" />
        <xsl:variable name="prefix" select="substring-before($vodml-ref,':')" />
        <xsl:if test="not($prefix) or $prefix=''">
            <xsl:message>!!!!!!! ERROR No prefix found in Element4vodml-ref for <xsl:value-of select="$vodml-ref" /></xsl:message>
        </xsl:if>
        <xsl:variable name="vodml-id" select="substring-after($vodml-ref,':')" />
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>**ERROR** failed to find '<xsl:value-of select="$vodml-ref" />'</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>