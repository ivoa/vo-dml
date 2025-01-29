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

<!-- this stylesheet requires that binding files have been read in -->
<xsl:include href="common.xsl"/>
<xsl:include href="common-structure-functions.xsl"/>

<xsl:key name="maplookup" match="type-mapping[vodml-id]" use="concat(ancestor::model/name,':',vodml-id)"/>

  <xsl:param name="targetnamespace_root"/>



  <!-- return the targetnamespace for the schema document for the package with the given id -->
  <xsl:template name="namespace-for-package">
    <xsl:param name="model"/>
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

   <xsl:template name="getmodel">
    <xsl:param name="vodml-ref"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
    <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>
    <xsl:if test="not($modelname) or $modelname=''">
      <xsl:message>!!!!!!! ERROR No prefix found in findmapping for <xsl:value-of select="$vodml-ref"/></xsl:message>
    </xsl:if>
    <xsl:copy-of select="$models/vo-dml:model[name=$modelname]"/>
    </xsl:template>

    <xsl:template name="listVocabs">
        <xsl:param name="outfile"/>
        <xsl:result-document href="{$outfile}" method="text">
            <xsl:for-each select="distinct-values($models/vo-dml:model//semanticconcept/vocabularyURI)">
                <xsl:value-of select="concat(current(),$nl)"/>
            </xsl:for-each>
        </xsl:result-document>

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
                                select="string-join($models/key('ellookup',$vodml-ref)/(ancestor::*[name() != 'vo-dml:model']/string(name),concat(upper-case(substring(name,1,1)),substring(name,2))),'.')"/>
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

    <xsl:function name="vf:CPPType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:value-of select="vf:fullCPPType($vodml-ref,false())"/>
    </xsl:function>
    <xsl:function name="vf:fullCPPType" as="xsd:string">
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
                                  select="string-join($models/key('ellookup',$vodml-ref)/(ancestor::*[name() != 'vo-dml:model']/string(name),concat(upper-case(substring(name,1,1)),substring(name,2))),'::')"/>
                    <xsl:value-of select="concat($root,'::',$path)"/>
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
    <!-- this function is a bit of a hack for xsdata https://xsdata.readthedocs.io/en/latest/data-types.html#converters - would be better to have a more general mechanism -->
    <xsl:function name="vf:PythonFormat" as="xsd:string?">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:if test="$vodml-ref='ivoa:datetime'">
            <xsl:sequence select="'%y-%m-%dT%H:%M:%SZ'"/>
       </xsl:if>
    </xsl:function>
    <!-- also a bit of a hack will only be called on something that is a primitive -->
    <xsl:function name="vf:PythonAlchemyType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'python')"/>
        <xsl:choose>
            <xsl:when test="$mappedtype != ''">
                <xsl:choose>
                    <xsl:when test="$mappedtype='datetime.datetime'"><xsl:sequence select="'sqlalchemy.DateTime'"/></xsl:when>
                    <xsl:when test="$mappedtype='str'"><xsl:sequence select="'sqlalchemy.String'"/></xsl:when>
                    <xsl:when test="$mappedtype='int'"><xsl:sequence select="'sqlalchemy.Integer'"/></xsl:when>
                    <xsl:when test="$mappedtype='float'"><xsl:sequence select="'sqlalchemy.Double'"/></xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="'sqlalchemy.Ignore'"/> <!-- IMPL this is nonsense - should not really be called -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'sqlalchemy.String'"/> <!-- IMPL assume locally defined primitive -->
            </xsl:otherwise>
        </xsl:choose>
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
            <xsl:when test="vf:hasMapping($vodml-ref,'python')">
                <xsl:value-of select="string-join(tokenize(vf:findmapping($vodml-ref,'python'),'\.')[position() > last() -1],'.')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="path"
                              select="string-join($models/key('ellookup',$vodml-ref)/ancestor::package/name,'_')"/>
                <xsl:value-of select="concat($path,'.',$models/key('ellookup',$vodml-ref)/name)"/>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="vf:PythonDataTypeMemberInfo" as="element()*" ><!--FIXME need to do something with references -->
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="supers" select="($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref))"/>
        <xsl:for-each select="$supers/attribute">
            <xsl:variable name="type" select="vf:el4vodmlref(current()/datatype/vodml-ref)"/>
            <xsl:element name="member">
                <xsl:attribute name="name" select="current()/name"/>
                <xsl:attribute name="ptype" select="vf:PythonType(current()/datatype/vodml-ref)"/>
                <xsl:attribute name="pyprim" select="vf:isPythonBuiltin(current()/datatype/vodml-ref)"/>
                <xsl:choose>
                    <xsl:when test="vf:findmapping(current()/datatype/vodml-ref,'python')">
                        <xsl:attribute name="altype" select="vf:PythonAlchemyType(current()/datatype/vodml-ref)"/>
                    </xsl:when>
                    <xsl:when test="$type/name() = 'primitiveType'">
                        <xsl:attribute name="altype" select="'sqlalchemy.String'"/><!--TODO assumption that underlying representation is string -->
                    </xsl:when>
                    <xsl:when test="$type/name() = 'enumeration'">
                        <xsl:attribute name="altype" select="concat('sqlalchemy.Enum(',$type/name,')')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="vf:PythonDataTypeMemberInfo(current()/datatype/vodml-ref)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>


    <xsl:function name="vf:xsdType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/> <!-- assumed to be fully qualified! i.e. also for elements in local model, the prefix is included! -->
        <xsl:variable name="type">
            <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'xsd')"/>
            <xsl:choose>
                <xsl:when test="$mappedtype != ''">
                    <xsl:value-of select="$mappedtype"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>
                    <xsl:variable name="root" select="vf:xsdNsPrefix($modelname)"/>
                    <xsl:value-of select="concat($root,':',substring-after($vodml-ref,':'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$type"/>
    </xsl:function>

    <xsl:function name="vf:jaxbType" as="xsd:string">
    <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:value-of select="substring-after($vodml-ref,':')"/>
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
            <xsl:when test="$lang eq 'xsd'">
                <xsl:copy-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/xsd-type"/>
            </xsl:when>
            <xsl:when test="$lang eq 'json'">
                <xsl:copy-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/json-type"/>
            </xsl:when>
            <xsl:when test="$lang eq 'cpp'">
                <xsl:copy-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/cpp-type"/>
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
            <xsl:when test="$lang eq 'cpp'">
                <xsl:value-of select="count($mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/cpp-type) > 0"/>
            </xsl:when>
            <xsl:when test="$lang eq 'json'">
                <xsl:value-of select="count($mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/json-type) > 0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">unknown language <xsl:value-of select="$lang"/> </xsl:message>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="vf:jsonType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="vf:hasMapping($vodml-ref,'json')">
                <xsl:variable name="mappedtype" select="vf:findmapping($vodml-ref,'json')"/>
                <xsl:choose>
                    <xsl:when test="$mappedtype/@format">
                        <xsl:value-of select="concat($dq,'format',$dq,': ',$dq,$mappedtype/@format,$dq)"/>
                    </xsl:when>
                    <xsl:when test="$mappedtype/@built-in">
                        <xsl:value-of select="concat($dq,'type',$dq,': ',$dq,$mappedtype/text(),$dq)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($dq,'$ref',$dq,': ',$dq,$mappedtype/text(),$dq)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="modelname" select="substring-before($vodml-ref,':')"/>
                <xsl:variable name="root" select="vf:jsonBaseURI($modelname)"/>
                <xsl:value-of select="concat($dq,'$ref',$dq,': ',$dq,$root,'#/$defs/',substring-after($vodml-ref,':'),$dq)"/>
            </xsl:otherwise>
        </xsl:choose>


    </xsl:function>

    <xsl:function name="vf:jsonReferenceType" as="xsd:string">
    <xsl:param name="vodml-ref" as="xsd:string"/>
    <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:choose>
            <xsl:when test="$el/attribute/constraint[ends-with(@xsi:type,':NaturalKey')]">
                <xsl:sequence select="vf:jsonType($el/attribute[constraint[ends-with(@xsi:type,':NaturalKey')]]/datatype/vodml-ref)"/>
            </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="concat($dq,'type',$dq,':',$dq,'number',$dq)"/>
                </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:jsonBaseURI" as="xsd:string">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:choose>
            <xsl:when test="$mapping/bnd:mappedModels/model[name=$modelName]/json-baseURI"> <!-- TODO can we allow customization really? -->
                <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelName]/json-baseURI/text()"/>
            </xsl:when>
            <xsl:otherwise>
                 <xsl:value-of select="concat('https://ivoa.net/dm/',vf:jsonFileName($modelName))"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>
    <xsl:function name="vf:jsonFileName" as="xsd:string">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:value-of select="concat(substring-before($mapping/bnd:mappedModels/model[name=$modelName]/file,'.xml'),'.json')"/>
    </xsl:function>

    <xsl:function name="vf:hasTypeDetail" as="xsd:boolean">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
        <xsl:value-of select="count($mapping/bnd:mappedModels/model[name=$modelname]/type-detail[@vodml-id=substring-after($vodml-ref,':')]) > 0"/>
    </xsl:function>

    <xsl:function name="vf:findTypeDetail" as="element()">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
        <xsl:choose>
            <xsl:when test="$mapping/bnd:mappedModels/model[name=$modelname]/type-detail[@vodml-id=substring-after($vodml-ref,':')]">
                <xsl:copy-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-detail[@vodml-id=substring-after($vodml-ref,':')]"/>
            </xsl:when>
            <xsl:otherwise> <!-- just return empty element -->
                <xsl:element name="type-detail">
                    <xsl:attribute name="vodml-id" select="substring-after($vodml-ref,':')"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>



    <xsl:function name="vf:isPythonBuiltin" as="xsd:boolean"> <!-- TODO does this really mean python primitive? -->
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="modelname" select="substring-before($vodml-ref,':')" />
        <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelname]/type-mapping[vodml-id=substring-after($vodml-ref,':')]/python-type/@built-in = 'true'"/>
    </xsl:function>

    <!-- will ensure that a member name is not a keyword byu appending '_' if it is-->
    <xsl:function name="vf:javaMemberName" as="xsd:string">
        <xsl:param name="n"/>
        <xsl:choose>
            <xsl:when test="$n = ('interface', 'long', 'class', 'default', 'native','super', 'transient', 'abstract','continue','for','new','switch',
            'assert', 'goto',	'package',	'synchronized',
'boolean',	'do',	'if',	'private',	'this',
'break',	'double',	'implements',	'protected',	'throw',
'byte',	'else',	'import',	'public',	'throws',
'case',	'enum','instanceof',	'return',
'catch',	'extends',	'int',	'short',	'try',
'char',	'final', 'static',	'void',
'finally',	'strictfp',	'volatile',
'const',	'float','while')"><xsl:sequence select="concat($n,'_')"/></xsl:when>
            <xsl:otherwise><xsl:sequence select="$n"/></xsl:otherwise>
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


    <xsl:function name="vf:JavaKeyType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="supers" select="($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref))"/>
        <xsl:choose>
            <xsl:when test="$supers/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]">
                <xsl:value-of select="vf:QualifiedJavaType($supers/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]/datatype/vodml-ref)"/>
            </xsl:when>
            <xsl:otherwise>Long</xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:memberOrderXML" as="xsd:string*">
    <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:sequence select="for $m in vf:allInheritedMembers($vodml-ref) return $models/key('ellookup',$m)/name"/>
    </xsl:function>

    <xsl:function name="vf:xsdNsPrefix" as="xsd:string">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelName]/xml-targetnamespace/@prefix"/>
    </xsl:function>
    <xsl:function name="vf:xsdNs" as="xsd:string">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$modelName]/xml-targetnamespace/text()"/>
    </xsl:function>
    <xsl:function name="vf:xsdFileName" as="xsd:string">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:value-of select="concat(substring-before($mapping/bnd:mappedModels/model[name=$modelName]/file,'.xml'),'.xsd')"/>
    </xsl:function>

    <xsl:function name="vf:isRdbSingleTable" as="xsd:boolean">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:sequence select="count($mapping/bnd:mappedModels/model[name=$modelName]/rdb[@inheritance-strategy='single-table'] )= 1"/>
    </xsl:function>

    <xsl:function name="vf:isRdbAddRef" as="xsd:boolean">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:sequence select="count($mapping/bnd:mappedModels/model[name=$modelName]/rdb[@useRefInColumnName=true()] )= 1"/>
    </xsl:function>
    <xsl:function name="vf:isRdbNaturalJoin" as="xsd:boolean">
        <xsl:param name="modelName" as="xsd:string"/>
        <xsl:sequence select="count($mapping/bnd:mappedModels/model[name=$modelName]/rdb[@naturalJoin=true()] )= 1"/>
    </xsl:function>
    <xsl:function name="vf:rdbODiscriminatorName" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:sequence select="concat($el/name,'_SUBTYPE')"/>
    </xsl:function>

    <xsl:function name="vf:rdbTableName" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:choose>
            <xsl:when test="$mapping/bnd:mappedModels/model[name=substring-before($vodml-ref,':')]/rdb/rdbmap[@vodml-id=substring-after($vodml-ref,':')]">
                <xsl:sequence select="$mapping/bnd:mappedModels/model[name=substring-before($vodml-ref,':')]/rdb/rdbmap[@vodml-id=substring-after($vodml-ref,':')]/tableName"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$el/name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="vf:rdbIDColumnName" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/> <!-- the objectType -->
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:choose>
            <xsl:when test="count($mapping/bnd:mappedModels/model[name=substring-before($vodml-ref,':')]/rdb[@naturalJoin=true()])> 0">
                <xsl:sequence select="concat(upper-case($el/name),'_ID')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'ID'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:rdbJoinTargetColumnName" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/> <!-- the objectType to join to -->
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:variable name="supers" select="($el,vf:baseTypes($vodml-ref))"/>
        <xsl:choose>
            <xsl:when test="$supers/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]">
                <xsl:sequence select="$supers/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]/name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="count($mapping/bnd:mappedModels/model[name=substring-before($vodml-ref,':')]/rdb[@naturalJoin=true()])> 0">
                        <xsl:sequence select="concat(upper-case($el/name),'_ID')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="'ID'"/>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>




    <xsl:function name="vf:rdbCompositionJoinName" as="xsd:string">
    <xsl:param name="parent" as="element()"/> <!-- the parent of the composition -->
        <xsl:choose>
            <xsl:when test="$parent/attribute/constraint[ends-with(@xsi:type,':NaturalKey')]">
                <xsl:value-of select="$parent/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]/name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(upper-case($parent/name),'_ID')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="vf:rdbRefColumnName" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="el" select="$models/key('ellookup',$vodml-ref)"/>
        <xsl:variable name="type" select="$models/key('ellookup',$el/datatype/vodml-ref)"/>
        <xsl:variable name="modelName" select="$el/ancestor-or-self::vo-dml:model/name"/>
        <xsl:choose>
            <xsl:when test="vf:isRdbAddRef($modelName)">
                <xsl:choose>
                    <xsl:when test="vf:isRdbNaturalJoin($modelName)">
                       <xsl:sequence select="concat(upper-case($type/name),'_ID')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence  select="concat(upper-case($el/name),'_',upper-case($type/name),'_ID')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$el/name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:function name="vf:rdbTapType" as="xsd:string">
    <xsl:param name="vodml-ref" as="xsd:string"/>

     <xsl:choose>
         <xsl:when test="vf:typeRole($vodml-ref) = 'enumeration'">VARCHAR</xsl:when>
         <xsl:otherwise>
             <xsl:variable name="jtype" select="vf:JavaType($vodml-ref)"/>
             <!-- IMPL mapping from JavaType for convenience as that will include other primitives not thought of yet - would probably need another mapping in the binding otherwise-->
             <xsl:choose>
                 <xsl:when test="$jtype='String'">VARCHAR</xsl:when>
                 <xsl:when test="$jtype=('Double', 'double')">DOUBLE</xsl:when>
                 <xsl:when test="$jtype=('Integer','int')">INTEGER</xsl:when>
                 <xsl:when test="$jtype=('Boolean','boolean')">INTEGER</xsl:when>
                 <xsl:when test="$jtype=('java.math.BigDecimal')">INTEGER</xsl:when>
                 <xsl:when test="$jtype=('java.util.Date')">TIMESTAMP</xsl:when>
                 <!--TODO this is incomplete -->
                 <xsl:otherwise>UNKNOWN</xsl:otherwise>
             </xsl:choose>
         </xsl:otherwise>
     </xsl:choose>

    </xsl:function>

    <xsl:function name="vf:rdbKeyType" as="xsd:string">
        <xsl:param name="vodml-ref" as="xsd:string"/>
        <xsl:variable name="supers" select="($models/key('ellookup',$vodml-ref),vf:baseTypes($vodml-ref))"/>
        <xsl:choose>
            <xsl:when test="$supers/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]">
                <xsl:value-of select="vf:rdbTapType($supers/attribute[ends-with(constraint/@xsi:type,':NaturalKey')]/datatype/vodml-ref)"/>
            </xsl:when>
            <xsl:otherwise>BIGINT</xsl:otherwise>
        </xsl:choose>
    </xsl:function>



    <xsl:function name="vf:schema-location4model" as="xsd:string">
        <xsl:param name="s" as="xsd:string"/>
        <xsl:value-of select="concat($s, 'xsd')"/>
    </xsl:function>
    <xsl:function name="vf:modelNameFromFile" as="xsd:string"><!-- note allowed empty sequence -->
        <xsl:param name="filename" as="xsd:string"/>
        <xsl:value-of select="$mapping/bnd:mappedModels/model[file=$filename]/name"/>
    </xsl:function>
    <xsl:function name="vf:fileNameFromModelName" as="xsd:string"><!-- note allowed empty sequence -->
        <xsl:param name="model" as="xsd:string"/>
        <xsl:value-of select="$mapping/bnd:mappedModels/model[name=$model]/file"/>
    </xsl:function>
    <xsl:function name="vf:el4vodmlref" as="element()?"> <!-- once rest of code working - can remove this and just use key directly -->
        <xsl:param name="vodml-ref" as="xsd:string" />
        <xsl:sequence select="$models/key('ellookup',$vodml-ref)" />
    </xsl:function>

    <xsl:function name="vf:modelJavaClass">
        <xsl:param name="this" as="element()"/>
        <xsl:variable name="model" select="$this/ancestor-or-self::vo-dml:model/name"/>
        <xsl:sequence select="concat($mapping/bnd:mappedModels/model[name=$model]/java-package,'.',vf:upperFirst($model),'Model')"/>
    </xsl:function>




</xsl:stylesheet>