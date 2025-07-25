<?xml version="1.0" encoding="UTF-8"?>
<!-- common functions that query the underlying structure of the vodml
it is assumed that this file will be included and all the models are previously read into a global variable called $models
note - only define functions in here as it is included in the schematron rules
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1">
    <xsl:key name="ellookup" match="//*[vodml-id]" use="concat(ancestor::vo-dml:model/name,':',vodml-id)"/>

    <xsl:include href="common_functions.xsl"/>

    <!-- does the vodml-ref exist? -->
    <xsl:function name="vf:vo-dml-ref-exists" as="xsd:boolean">
        <xsl:param name="vodml-ref" />
        <xsl:sequence select="count($models/key('ellookup',$vodml-ref)) =1 " />
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
                        <xsl:sequence select="($models/key('ellookup',$el/extends/vodml-ref), vf:baseTypes($el/extends/vodml-ref))" />
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

    <xsl:function name="vf:baseTypeId" as="xsd:string">
        <xsl:param name="vodml-ref"/>
        <xsl:sequence select="vf:baseTypeIds($vodml-ref)[last()]"/>
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

    <xsl:function name="vf:subTypeIds" as="xsd:string*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="count($models//extends[vodml-ref = $vodml-ref])> 0">
                        <xsl:for-each select="$models//*[extends/vodml-ref = $vodml-ref]">
                            <!--                            <xsl:message><xsl:value-of select="concat('subtype of ',$vodml-ref, ' is ', name)" /></xsl:message>-->
                            <xsl:sequence select="(vf:asvodmlref(.),vf:subTypeIds(vf:asvodmlref(.)))"/>
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
        <xsl:sequence select="count($models/key('ellookup',$vodml-ref)/extends) > 0"/>
    </xsl:function>

    <!-- number of supertypes in hierarchy -->
    <xsl:function name="vf:numberSupertypes" as="xsd:integer">
        <xsl:param name="vodml-ref"/>
        <xsl:sequence select="count(vf:baseTypeIds($vodml-ref))"/>
    </xsl:function>




    <xsl:function name="vf:importedModelNames" as="xsd:string*">
        <xsl:param name="thisModel" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="$models/vo-dml:model[name=$thisModel]/import">
                <xsl:variable name="m" as="xsd:string*">
                    <xsl:for-each select="$models/vo-dml:model[name=$thisModel]/import">
                        <xsl:sequence select="distinct-values(document(url)/vo-dml:model/name)"/>
                    </xsl:for-each>
                </xsl:variable>
<!--                <xsl:message><xsl:value-of select="concat('imports=',$thisModel,' &#45;&#45;',string-join($m,','))"/> </xsl:message>-->
                <xsl:variable name="r" as="xsd:string*">
                    <xsl:sequence select="$m"/>
                    <xsl:for-each select="$m">
                        <xsl:sequence select="vf:importedModelNames(.)"/>  <!-- do recursion? see https://github.com/ivoa/vo-dml/issues/7 -->
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="distinct-values($r)"/>
            </xsl:when>
        </xsl:choose>

    </xsl:function>


    <!-- returns the types that are referenced in the models -->
    <xsl:function name="vf:referencesInModels" as="xsd:string*">
        <xsl:sequence select="distinct-values($models//reference/datatype/vodml-ref)"/>
    </xsl:function>
    <!-- returns the types that are contained references in models -->
    <xsl:function name="vf:containedReferencesInModels" as="xsd:string*">
        <xsl:sequence select="distinct-values($models//reference/datatype/vodml-ref[vf:isContained(.)])"/>
    </xsl:function>

    <xsl:function name="vf:refsToSerialize" as="xsd:string*">
    <xsl:param name="name" as="xsd:string"/>
    <!-- imported model names -->
    <xsl:variable name="modelsInScope" select="($name,vf:importedModelNames($name))"/>
    <xsl:variable name="possibleRefs" select="distinct-values($models/vo-dml:model[name = $modelsInScope ]//reference/datatype/vodml-ref)" as="xsd:string*"/>
       <xsl:sequence>
          <xsl:for-each select="$possibleRefs">
              <xsl:if test="not(vf:isContainedReferenceInModels(current(),$modelsInScope))">
                  <xsl:sequence select="current()"/>
              </xsl:if>
          </xsl:for-each>
       </xsl:sequence>
    </xsl:function>

    <xsl:function name="vf:contentToSerialize" as="element()*">
        <xsl:param name="name" as="xsd:string"/>
        <!-- imported model names -->
        <xsl:variable name="modelsInScope" select="($name,vf:importedModelNames($name))"/>
        <xsl:sequence >
            <xsl:for-each select="$models/vo-dml:model[name = $modelsInScope ]//objectType[not(@abstract='true')and not(vf:isContainedInModels(vf:asvodmlref(.),$modelsInScope))]">
                <xsl:variable name="cont" select="vf:containedTypes(vf:asvodmlref(current()))"/>
                <xsl:variable name="refby" select="vf:referredByInModels(vf:asvodmlref(current()),$modelsInScope)"/>
<!--                <xsl:message><xsl:value-of select="concat('content cand=',vf:asvodmlref(current()),' contained=',string-join($cont,','), ' refby=',string-join($refby,','), ' decision=',empty($refby[not(. = $cont)]))"/></xsl:message>-->
                <xsl:if test="empty($refby[not(. = $cont)])">
                    <xsl:sequence select="current()"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:sequence>
    </xsl:function>


    <!-- return the type hierarchy focussed on the type as argument -->
    <xsl:function name="vf:typeHierarchy" as="xsd:string*">
    <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:sequence>
            <xsl:for-each  select="(vf:baseTypes($vodml-ref),$models/key('ellookup',$vodml-ref),vf:subTypes($vodml-ref))">
                <xsl:value-of select="vf:asvodmlref(.)"/>
            </xsl:for-each>
        </xsl:sequence>
    </xsl:function>
    <!-- is the type (sub or base) used as a reference -->
    <xsl:function name="vf:referredTo" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:sequence select="vf:referredToInModels($vodml-ref,$models/vo-dml:model/name/text())"/>
    </xsl:function>
    <xsl:function name="vf:referredToInModels" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:param name="modelsToSearch" as="xsd:string*"/>

        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="hier" select="vf:typeHierarchy($vodml-ref)"/>
                <!--                <xsl:message>refs <xsl:value-of select="concat ($vodml-ref,' ',count($models//reference/datatype[vodml-ref = $hier])> 0,' h=',string-join($hier,','))"/></xsl:message>-->
                <xsl:value-of select="count($models/vo-dml:model[name = $modelsToSearch]//reference/datatype[vodml-ref = $hier])> 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:containedTypes" as="xsd:string*" >
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:sequence>
            <xsl:for-each select="distinct-values(for $v in (vf:baseTypes($vodml-ref),$models/key('ellookup',$vodml-ref)) return $v/composition/datatype/vodml-ref)">
                <xsl:choose>
                    <xsl:when test="current() != $vodml-ref">
                        <xsl:sequence select="(current(), vf:containedTypes(current()))"/>
                    </xsl:when>
                    <xsl:otherwise><xsl:sequence select="current()"/></xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:sequence>
    </xsl:function>



    <xsl:function name="vf:ContainerHierarchyInOwnModel" as="xsd:string*" >
    <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="modelName" select="$models/key('ellookup',$vodml-ref)/ancestor::vo-dml:model/name"/>
        <xsl:variable name="models" select="($modelName,vf:importedModelNames($modelName))"/>
        <xsl:sequence select="vf:ContainerHierarchy($vodml-ref,$models)"/>
    </xsl:function>

    <!-- finds the top container of a type in models -->
    <xsl:function name="vf:ContainerHierarchy" as="xsd:string*" >
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:param name="modelsToSearch" as="xsd:string*"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="hier" select="vf:typeHierarchy($vodml-ref)"/>
                <xsl:variable name="numcont" select="count($models/vo-dml:model[name = $modelsToSearch]//objectType[composition/datatype/vodml-ref = $hier])"/>
                <xsl:choose>
                <xsl:when test=" $numcont = 1">
                    <xsl:variable name="cont" select="vf:asvodmlref($models/vo-dml:model[name = $modelsToSearch]//objectType[composition/datatype/vodml-ref = $hier])"/>
                    <xsl:sequence select="($cont, vf:ContainerHierarchy($cont, $modelsToSearch))"/>
                </xsl:when>
                <xsl:when test="$numcont = 0">
                    <!-- null -->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="no">type '<xsl:value-of select="$vodml-ref"/>' is multiply contained <xsl:value-of select="string-join(for $v in $models/vo-dml:model[name = $modelsToSearch]//objectType[composition/datatype/vodml-ref = $hier] return vf:asvodmlref($v),',')"/> so containment hierarchy is ambiguous</xsl:message>
                </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>





    <!-- vodml-ids of referrers to the type in the argument -->
    <xsl:function name="vf:referredBy" as="xsd:string*">
    <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:sequence select="vf:referredByInModels($vodml-ref,$models/vo-dml:model/name/text())"/>
    </xsl:function>



    <xsl:function name="vf:referredByInModels" as="xsd:string*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:param name="modelsToSearch" as="xsd:string*"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="hier" select="vf:typeHierarchy($vodml-ref)"/>
                <!--                <xsl:message>refs <xsl:value-of select="concat ($vodml-ref,' ',count($models//reference/datatype[vodml-ref = $hier])> 0,' h=',string-join($hier,','))"/></xsl:message>-->
                <xsl:sequence select="distinct-values(for $i in $models/vo-dml:model[name = $modelsToSearch]//(objectType|dataType)[reference/datatype/vodml-ref = $hier] return vf:asvodmlref($i))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


<!-- return all the reference types in the containment hierarchy of the argument type (and its bases) -->
    <xsl:function name="vf:referenceTypesInContainmentHierarchy" as="xsd:string*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:sequence select="distinct-values(for $t in ($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref)) return $t/reference/datatype/vodml-ref)"/>
                <xsl:for-each select="distinct-values(for $t in ($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref)) return $t/composition/datatype/vodml-ref)[. != $vodml-ref]">
                    <!--                            <xsl:message><xsl:value-of select="concat('subtype of ',$vodml-ref, ' is ', name)" /></xsl:message>-->
                    <xsl:sequence select="vf:referenceTypesInContainmentHierarchy(.)"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="vf:hasReferencesInContainmentHierarchy" as="xsd:boolean">
       <xsl:param name="vodml-ref"/>
        <xsl:sequence select="count(vf:referenceTypesInContainmentHierarchy($vodml-ref)) != 0"/>
    </xsl:function>

   <!-- return the references in the order in which they need to be saved -->
   <!-- IMPL this is done rather simplistically ATM based on the length of the reference chain -->
    <xsl:function name="vf:orderReferences" as="xsd:string*">
        <xsl:param name="refs" as="xsd:string*"/>
        <xsl:sequence select="sort($refs,default-collation(),function($e){count(vf:referenceTypesInContainmentHierarchy($e)[. = $refs])})"/>
    </xsl:function>

    <xsl:function name="vf:orderContent" as="xsd:string*">
        <xsl:param name="cont" as="xsd:string*"/>
        <xsl:sequence select="sort($cont,default-collation(),function($e){count(vf:referenceTypesInContainmentHierarchy($e))})"/>
    </xsl:function>

    <!-- has contained reference in containment hierarchy - including above, starting at the second argument - this is needed in the contained reference handling rather than the reporting-->
    <xsl:function name="vf:hasContainedReferencesInContainmentHierarchy" as="xsd:boolean">
        <xsl:param name="vodml-ref"/>
        <xsl:param name="root-vodml-ref"/>
        <xsl:choose>
            <xsl:when test="vf:isContained($root-vodml-ref)">
                <xsl:variable name="top-container" select="vf:ContainerHierarchyInOwnModel($root-vodml-ref)[1]"/><!-- IMPL this may go wrong if multiply contained -->
                <xsl:sequence select="count(vf:referenceTypesInContainmentHierarchy($vodml-ref)[vf:isTypeContainedBelow(.,$top-container)]) != 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="count(vf:referenceTypesInContainmentHierarchy($vodml-ref)[vf:isTypeContainedBelow(.,$root-vodml-ref)]) != 0"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <!-- all the reference types below in the containment hierarchy -->
    <xsl:function name="vf:containedReferencesInContainmentHierarchy" as="xsd:string*">
        <xsl:param name="vodml-ref"/>
        <xsl:sequence select="vf:referenceTypesInContainmentHierarchy($vodml-ref)[vf:isTypeContainedBelow(.,$vodml-ref)]"/>
    </xsl:function>

    <xsl:function name="vf:hasContainedReferenceInTypeHierarchy" as="xsd:boolean">
        <xsl:param name="vodml-ref"/>
        <xsl:variable name="types" as="xsd:string*" >
        <xsl:sequence  select="vf:referenceTypesInContainmentHierarchy($vodml-ref)"/>
        <xsl:sequence  select="for $v in vf:subTypeIds($vodml-ref) return vf:referenceTypesInContainmentHierarchy($v)"/>
        </xsl:variable>
        <xsl:sequence select="$types = vf:containedReferencesInModels()"/>
    </xsl:function>


    <!-- is the member subsetted - for it to be truly subsetted from a type point of view (not just semantic)it needs to be subtyped too-->
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

    <!-- This will return all the subsets found in the sub hierarchy - will not return subset when it is the same type as the thing it subsets (happens when the only reason for the subset is semantic constraint?)
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



    <!-- TODO rationalize these isContainted methods - are the distinct ones needed - also the isContainedReference just too specific -->
    <!-- is the type (sub or base) used as a  contained reference -->
    <xsl:function name="vf:isContainedReference" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:sequence select="vf:isContainedReferenceInModels($vodml-ref,$models/vo-dml:model/name/text())"/>
    </xsl:function>
    <xsl:function name="vf:isContainedReferenceInModels" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:param name="modelsToSearch" as="xsd:string*"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="hier" select="vf:typeHierarchy($vodml-ref)"/>
                <!--                <xsl:message>refs <xsl:value-of select="concat ($vodml-ref,' ',count($models//reference/datatype[vodml-ref = $hier])> 0,' h=',string-join($hier,','))"/></xsl:message>-->
                <xsl:value-of select="count($models/vo-dml:model[name = $modelsToSearch]//reference/datatype[vodml-ref = $hier and vf:isContained(.)])> 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"><xsl:value-of select="concat('type', $vodml-ref,' not in considered models= ',string-join($modelsToSearch,','))"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:isContained" as="xsd:boolean">
    <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:sequence select="vf:isContainedInModels($vodml-ref,$models/vo-dml:model/name)"/>
    </xsl:function>
    <!-- is the type (or supertypes) contained anywhere -->
    <xsl:function name="vf:isContainedInModels" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:param name="modelsToSearch" as="xsd:string*"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <!--                <xsl:message>contained <xsl:value-of select="concat($vodml-ref, ' ', count($models//(attribute|composition)/datatype[vodml-ref=$vodml-ref])>0)"/> </xsl:message>-->
                <xsl:choose>
                    <xsl:when test="not($el/extends)">
                        <xsl:value-of select="count($models/vo-dml:model[name = $modelsToSearch]//composition/datatype[vodml-ref=$vodml-ref])>0"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="count($models/vo-dml:model[name = $modelsToSearch]//composition/datatype[vodml-ref=$vodml-ref])>0 or vf:isContained($el/extends/vodml-ref)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"><xsl:value-of select="concat('type', $vodml-ref,' not in considered models= ',string-join($models/vo-dml:model/name,','))"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="vf:containingTypes" as="element()*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <!--                <xsl:message>contained <xsl:value-of select="concat($vodml-ref, ' ', count($models//(attribute|composition)/datatype[vodml-ref=$vodml-ref])>0)"/> </xsl:message>-->
                <xsl:choose>
                    <xsl:when test="not($el/extends)">
                        <xsl:sequence select="$models//objectType[(attribute|composition)/datatype/vodml-ref=$vodml-ref]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="($models//objectType[(attribute|composition)/datatype/vodml-ref=$vodml-ref] , vf:containingTypes($el/extends/vodml-ref))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>



    <xsl:function name="vf:isTypeContainedBelow" as="xsd:boolean">
        <xsl:param name="type-vodml-ref"  as="xsd:string" />
        <xsl:param name="root-vodml-ref" as="xsd:string"/>
        <xsl:variable name="ct" select="vf:containedTypes($root-vodml-ref)"/>
        <xsl:sequence  select="$type-vodml-ref = $ct"/>
    </xsl:function>



    <xsl:function name="vf:attributeIsDtype" as="xsd:boolean">
        <xsl:param name="attr" as="element()"/>
        <xsl:sequence select="$models/key('ellookup',$attr/datatype/vodml-ref)/name() = 'dataType'"/>
    </xsl:function>




    <xsl:function name="vf:utype" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <!--        <xsl:message select="concat('subsetting in hierarchy for=',$vodml-ref)"/>-->
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
                <xsl:value-of select="concat($el/ancestor-or-self::vo-dml:model/name,':',$el/vodml-id)"/><!-- FIXME - this is not sufficient for a UType in all circumstances -->
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
    <xsl:function name="vf:isPrimitiveType" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="vf:typeRole($el/datatype/vodml-ref) = 'primtiveType'"/>
    </xsl:function>
    <xsl:function name="vf:isDataType" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="vf:typeRole($el/datatype/vodml-ref) = 'dataType'"/>
    </xsl:function>
    <xsl:function name="vf:isObjectType" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="vf:typeRole($el/datatype/vodml-ref) = 'objectType'"/>
    </xsl:function>

    <!-- returns the vodml-refs of the members including inherited ones -->
    <xsl:function name="vf:allInheritedMembers" as="xsd:string*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="supers" select="($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref))"/>
        <!--        <xsl:message>inherited <xsl:value-of select="concat($vodml-ref, ' subsets=',string-join($subsets,','),' members=',-->
        <!--        string-join(for $v in ($supers/attribute,$supers/composition,$supers/reference) return vf:asvodmlref($v), ',') )" /></xsl:message>-->
        <xsl:sequence>
            <xsl:for-each select="$supers/attribute,$supers/composition,$supers/reference">
                <xsl:sequence select="vf:asvodmlref(.)"/>
            </xsl:for-each>
        </xsl:sequence>
    </xsl:function>

    <xsl:function name="vf:dataTypeInheritedMembers" as="element()*">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="supers" select="($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref))"/>
        <!--        <xsl:message>inherited <xsl:value-of select="concat($vodml-ref, ' subsets=',string-join($subsets,','),' members=',-->
        <!--        string-join(for $v in ($supers/attribute,$supers/composition,$supers/reference) return vf:asvodmlref($v), ',') )" /></xsl:message>-->
        <xsl:sequence>
            <xsl:for-each select="$supers/attribute,$supers/reference">
                <xsl:sequence select="."/>
            </xsl:for-each>
        </xsl:sequence>
    </xsl:function>
    <xsl:function name="vf:dtypeUsedDirectly" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="name" select="$models/key('ellookup',$vodml-ref)/ancestor-or-self::vo-dml:model/name"/>
        <xsl:variable name="modelsInScope" select="($name,vf:importedModelNames($name))"/>
        <xsl:sequence select="count($models/vo-dml:model[name = $modelsInScope]//attribute/datatype[vodml-ref=$vodml-ref])>0" />
    </xsl:function>

    <xsl:function name="vf:dtypeHierarchyUsedPolymorphically" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <!-- the rules for whether a type is actually used polymophically are strict in hibernate

        see https://docs.jboss.org/hibernate/orm/6.6/userguide/html_single/Hibernate_User_Guide.html#embeddable-inheritance

        have requested easier way to specify this https://hibernate.atlassian.net/browse/HHH-19193
        -->
        <xsl:variable name="name" select="$models/key('ellookup',$vodml-ref)/ancestor-or-self::vo-dml:model/name"/>
        <xsl:variable name="modelsInScope" select="($name,vf:importedModelNames($name))"/>
        <xsl:variable name="typeTree" select="(reverse(vf:baseTypeIds($vodml-ref)),$vodml-ref,vf:subTypeIds($vodml-ref))"/>
<!--        <xsl:message>dtype polymorphism=<xsl:value-of select="$vodml-ref"/>  tree=<xsl:value-of select="string-join($typeTree,',')"/></xsl:message>-->
       <!-- TODO - need to actually work out the cases where polymorphism required
        really need to establish whether only leaf types are used-->
        <xsl:choose>
            <xsl:when test="vf:typeRole($vodml-ref)='dataType' and count(vf:baseTypeIds($typeTree[last()]))> 1"> <!--FIXME this is a very crude heuristic - essentially going polymorphic if more than one level of inheritance on the last subtype
             found, but even this might not resent the deepest subtype if a wide tree...-->
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>



    <xsl:function name="vf:isOptional" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="number($el/multiplicity/minOccurs) = 0 and number($el/multiplicity/maxOccurs) = 1" />
    </xsl:function>
    <xsl:function name="vf:isArrayLike" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="number($el/multiplicity/minOccurs) gt  1 and number($el/multiplicity/maxOccurs) gt 1" />
    </xsl:function>
    <xsl:function name="vf:isCollection" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="number($el/multiplicity/minOccurs) lt 2 and number($el/multiplicity/maxOccurs) != 1" />
    </xsl:function>


</xsl:stylesheet>