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
        <xsl:sequence select="count($models/key('ellookup',$vodml-ref)/extends) > 0"/>
    </xsl:function>

    <!-- number of supertypes in hierarchy -->
    <xsl:function name="vf:numberSupertypes" as="xsd:integer">
        <xsl:param name="vodml-ref"/>
        <xsl:sequence select="count(vf:baseTypeIds($vodml-ref))"/>
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
                        <xsl:value-of select="count($models//(attribute|composition)/datatype[vodml-ref=$vodml-ref])>0"/><!-- TODO should this not be just composition? -->
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

    <xsl:function name="vf:referencesInModels" as="xsd:string*">
        <xsl:sequence select="distinct-values($models//reference/datatype/vodml-ref)"/>
    </xsl:function>
    <xsl:function name="vf:containedReferencesInModels" as="xsd:string*">
        <xsl:sequence select="distinct-values($models//reference/datatype/vodml-ref[vf:isContained(.)])"/>
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
                <xsl:message><xsl:value-of select="concat('imports=',$thisModel,' --',string-join($m,','))"/> </xsl:message>
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
                <xsl:variable name="hier" as="xsd:string *">
                    <xsl:sequence>
                        <xsl:for-each  select="(vf:baseTypes($vodml-ref),$models/key('ellookup',$vodml-ref),vf:subTypes($vodml-ref))">
                            <xsl:value-of select="vf:asvodmlref(.)"/>
                        </xsl:for-each>
                    </xsl:sequence>
                </xsl:variable>
                <!--                <xsl:message>refs <xsl:value-of select="concat ($vodml-ref,' ',count($models//reference/datatype[vodml-ref = $hier])> 0,' h=',string-join($hier,','))"/></xsl:message>-->
                <xsl:value-of select="count($models/vo-dml:model[name = $modelsToSearch]//reference/datatype[vodml-ref = $hier])> 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type '<xsl:value-of select="$vodml-ref"/>' not in considered models</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


<!-- return all the reference types in the containment hierarchy of the argument type -->
    <xsl:function name="vf:referenceTypesInContainmentHierarchy" as="xsd:string*">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <xsl:sequence select="$el/reference/datatype/vodml-ref"/>
                <xsl:for-each select="$el/composition/datatype/vodml-ref">
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

    <xsl:function name="vf:hasContainedReferencesInContainmentHierarchy" as="xsd:boolean">
        <xsl:param name="vodml-ref"/>
        <xsl:sequence select="count(vf:referenceTypesInContainmentHierarchy($vodml-ref)[vf:isTypeContained(.,$vodml-ref)]) != 0"/>
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

    <!-- returns all the contained type ids -->
    <xsl:function name="vf:containedTypeIds" as="xsd:string*">
        <xsl:param name="vodml-ref"/>
        <xsl:choose>
            <xsl:when test="$models/key('ellookup',$vodml-ref)">
                <xsl:variable name="el" as="element()">
                    <xsl:copy-of select="$models/key('ellookup',$vodml-ref)" />
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$el/composition">
                        <xsl:sequence select="($el/composition/datatype/vodml-ref, for $v in $el/composition/datatype/vodml-ref return  vf:containedTypeIds($v))"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">type <xsl:value-of select="$vodml-ref"/> not in considered models for base types</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:isTypeContained" as="xsd:boolean">
        <xsl:param name="type-vodml-ref"  as="xsd:string" />
        <xsl:param name="root-vodml-ref" as="xsd:string"/>
        <xsl:variable name="root" select="$models/key('ellookup',$root-vodml-ref)"/>
        <xsl:choose>
            <xsl:when test="$root/composition">
                <xsl:sequence  select="$type-vodml-ref = vf:containedTypeIds($root-vodml-ref)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
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

    <xsl:function name="vf:isOptional" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="number($el/multiplicity/minOccurs) = 0 and number($el/multiplicity/maxOccurs) = 1" />
    </xsl:function>
    <xsl:function name="vf:isArrayLike" as="xsd:boolean">
        <xsl:param name="el" as="element()"/>
        <xsl:sequence select="number($el/multiplicity/minOccurs) >  1 and number($el/multiplicity/maxOccurs) > 1" />
    </xsl:function>

</xsl:stylesheet>