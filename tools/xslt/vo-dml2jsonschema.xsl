<?xml version="1.0" encoding="UTF-8"?>
<!--
create a json schema

this is still not a complete representation of the JSON produced - it will validate the "syntax", but is still not
capable of flagging all errors that might be present

* typing using @type
* references - via their ID

that allow for successful JSON round tripping.
 -->

<!DOCTYPE stylesheet [
        <!ENTITY cr "<xsl:text>
</xsl:text>">
        <!ENTITY bl "<xsl:text> </xsl:text>">
        ]>

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
                xmlns:vodml-base="http://www.ivoa.net/xml/vo-dml/xsd/base/v0.1"
                exclude-result-prefixes="bnd"
>


  <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes" />

  <xsl:strip-space elements="*" />

  <!-- Input parameters -->
  <xsl:param name="lastModifiedText"/>
  <xsl:param name="binding"/>
  <xsl:include href="binding_setup.xsl"/>

  <xsl:variable name="strict" as="xsd:boolean">
      <xsl:sequence select="not($mapping/bnd:mappedModels/model[name=current()/vo-dml:model/name]/json/@lax='true')"/>
  </xsl:variable>
 <!-- main pattern : processes for root node model -->
  <xsl:template match="/">
    <xsl:message >Generating JSON <xsl:value-of select="document-uri(.) "/> - considering models <xsl:value-of select="string-join($models/vo-dml:model/name,' and ')" /></xsl:message>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="vo-dml:model">

    <xsl:variable name="modelname" select="vf:upperFirst(name)"/>
      {
      "$schema": "https://json-schema.org/draft/2020-12/schema"
      <xsl:call-template name="id"/>
       ,"title" : "<xsl:value-of select="title"/>"
        ,<xsl:apply-templates select="description"/>
        ,"type": "object"
        ,"properties":  {
            "<xsl:value-of select="concat($modelname,'Model')"/>": {
                "type": "object"
             ,"properties" :
             {
                <xsl:apply-templates select="current()" mode="refs"/>
                <xsl:apply-templates select="current()" mode="content"/>
             }
             ,"additionalProperties": false
            }

         }

        ,"$defs" : {
        "$comment" : "placeholder to make commas easier!"

        <xsl:apply-templates select="objectType" />
        <xsl:apply-templates select="dataType" />
        <xsl:apply-templates select="primitiveType"/>
        <xsl:apply-templates select="enumeration"/>
        <xsl:apply-templates select="package"/>
        }

      }

  </xsl:template>
    <xsl:template match="vo-dml:model" mode="refs">
        <xsl:variable name="references-vodmlref" select="vf:refsToSerialize(name)"/>
            "refs" : {
               "type" : "object"
               ,"properties" : {
            "$comment" : "placeholder to make commas easier!"
            <xsl:for-each select="$references-vodmlref"><!-- IMPL mostly expecting the actual reference object mostly in the refs array - but could be a ref to an object if it has occurred as contained reference in a preceding reference object -->
                ,"<xsl:value-of select="current()"/>" : {
                   "type": "array"
                   ,"items" : {
                      "oneOf" : [
                         {<xsl:value-of select="vf:jsonType(current())"/>},
                         {<xsl:value-of select="vf:jsonReferenceType(current())"/>}
                       ]
                   }
                }
            </xsl:for-each>
            }
            ,"additionalProperties": false
            }
    </xsl:template>

    <xsl:template match="vo-dml:model" mode="content">
        <xsl:variable name="contentTypes" as="element()*" select="vf:contentToSerialize(name)"/>
        ,"content" : {
           "type" : "array"
            ,"items" : {
                "anyOf" : [
                <xsl:for-each select="$contentTypes">
                    <xsl:if test="position() != 1">,</xsl:if>{<xsl:value-of select="vf:jsonType(vf:asvodmlref(current()))"/>}
                </xsl:for-each>
            ]
        }
        ,"additionalProperties": false
        }
    </xsl:template>

  <xsl:template match="description">
    "description" : "<xsl:value-of select="normalize-space(translate(current(),$dq,$sq))"/>"
  </xsl:template>
  <xsl:template name="defnName">
    "<xsl:value-of select="substring-after(vf:asvodmlref(current()),':')"/>"
  </xsl:template>


  <xsl:template name="id">
    ,"$id": "<xsl:value-of select="vf:jsonBaseURI(name)"/>"
  </xsl:template>


  <xsl:template match="package">
    <xsl:apply-templates select="objectType"/>
    <xsl:apply-templates select="dataType" />
    <xsl:apply-templates select="primitiveType"/>
    <xsl:apply-templates select="enumeration"/>
    <xsl:apply-templates select="package"/>
  </xsl:template>


  <xsl:template name="makeStrict">
    <xsl:if test="$strict">
      <xsl:choose>
          <xsl:when test="not(current()/extends) and not(vf:hasSubTypes(vf:asvodmlref(current())))">
              ,"additionalProperties" : false
          </xsl:when>
          <xsl:when test="not(vf:hasSubTypes(vf:asvodmlref(current())))">
              ,"unevaluatedProperties" : false
          </xsl:when>
      </xsl:choose>

    </xsl:if>
  </xsl:template>

  <xsl:template match="objectType">
    ,<xsl:call-template name="defnName"/> : {
    <xsl:if test="extends">
        "allOf" : [

        {<xsl:value-of select="vf:jsonType(extends/vodml-ref)"/>},
        {
    </xsl:if>
    "type": "object"
    ,<xsl:apply-templates select="description"/>
    ,"properties" : {
    "$comment" : "placeholder to make commas easier!"
      <!--  as properties optional by default - just define this  <xsl:if test="not(extends)"> &lt;!&ndash; impl perhaps vf:hasSubTypes(vf:asvodmlref(current())) what we really want and then do special things for the "content" types &ndash;&gt;-->
    ,"@type" : { "type": "string"}
<!--    </xsl:if>-->
    <xsl:apply-templates select="attribute"/>
    <xsl:apply-templates select="composition"/>
    <xsl:apply-templates select="reference"/>
    <xsl:if test="not(attribute/constraint[ends-with(@xsi:type,':NaturalKey')])">
    ,"_id" : { "type": "number"}
    </xsl:if>
      }
    <xsl:call-template name="required"/>
      <xsl:if test="extends">
         } ]
      </xsl:if>
    <xsl:call-template name="makeStrict"/>
    }
   &cr;&cr;
  </xsl:template>

    <xsl:template match="dataType">
        ,<xsl:call-template name="defnName"/> : {
        <xsl:if test="extends">
            "allOf" : [

            {<xsl:value-of select="vf:jsonType(extends/vodml-ref)"/>},
            {
        </xsl:if>
        "type": "object"
        ,<xsl:apply-templates select="description"/>
        ,"properties" : {
        "$comment" : "placeholder to make commas easier!"
        ,"@type" : { "type": "string"}
        <xsl:apply-templates select="attribute|reference"/>
        }
        <xsl:call-template name="required"/>
        <xsl:if test="extends">
            } ]
        </xsl:if>
        <xsl:call-template name="makeStrict"/>
        }
        &cr;&cr;

    </xsl:template>


    <xsl:template name="required">
      ,"required": [
      <xsl:variable name="req" as="xsd:string*">
          <xsl:for-each select="(attribute|reference|composition)">
              <xsl:if test="number(multiplicity/minOccurs) = 1"> <!-- TODO need to think about array -->
                  <xsl:sequence select="concat($dq,name,$dq)"/>
              </xsl:if>
          </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($req,',')"/>
      ]
  </xsl:template>


  <xsl:template match="enumeration">
      ,<xsl:call-template name="defnName"/> :
    {
    <xsl:apply-templates select="description"/>
    ,"enum": [<xsl:value-of select="string-join(for $x in literal/name return concat($dq,$x,$dq),',')"/>]

    }
    &cr;&cr;

  </xsl:template>


  <xsl:template match="primitiveType">
      <xsl:if test="not(vf:hasMapping(vf:asvodmlref(current()),'json'))">
      ,<xsl:call-template name="defnName"/> : {
        "type": "object"
        ,"properties" : {
            "value" : "string"
         }
      }
      </xsl:if>
  </xsl:template>



  <xsl:template match="attribute[multiplicity/maxOccurs=1]" >
      , "<xsl:value-of select="name"/>" : {
       <xsl:value-of select="vf:jsonType(datatype/vodml-ref)"/>
       ,<xsl:apply-templates select="description"/>
    }
  </xsl:template>
    <!-- allow attributes with multiplicity > 1 -->
    <xsl:template match="attribute[multiplicity/maxOccurs!=1]" >
        , "<xsl:value-of select="name"/>" : {
        "type":"array"
        ,"items": {
        <xsl:value-of select="vf:jsonType(datatype/vodml-ref)"/>
        }
        ,<xsl:apply-templates select="description"/>
        }
    </xsl:template>

  <xsl:template match="multiplicity">
    <!--  only legal values: 0..1   1   0..*   1..* -->
    <xsl:if test="minOccurs">
      <xsl:attribute name="minOccurs"><xsl:value-of select="minOccurs"/></xsl:attribute>
    </xsl:if>
    <xsl:if test="maxOccurs">
      <xsl:attribute name="maxOccurs">
        <xsl:choose>
          <xsl:when test="maxOccurs &lt;= 0">
            <xsl:value-of select="'unbounded'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="maxOccurs"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

    <xsl:template match="composition[multiplicity/maxOccurs=1]" >
        ,"<xsl:value-of select="name"/>" : {
        "type":"object"
        <xsl:choose>
            <xsl:when test="vf:hasSubTypes(datatype/vodml-ref)">
                ,"anyOf": [
                <xsl:value-of select="string-join(for $v in vf:subTypeIds(datatype/vodml-ref) return concat('{',vf:jsonType($v),'}') ,',')"/>
                ]
            </xsl:when>
            <xsl:otherwise>
                ,<xsl:value-of select="vf:jsonType(datatype/vodml-ref)"/>
            </xsl:otherwise>
        </xsl:choose>
        }
    </xsl:template>

  <xsl:template match="composition" >
      ,"<xsl:value-of select="name"/>" : {
      "type":"array"
      ,"items": {
           <xsl:choose>
               <xsl:when test="vf:hasSubTypes(datatype/vodml-ref)">
                  "anyOf": [
                    <xsl:value-of select="string-join(for $v in vf:subTypeIds(datatype/vodml-ref) return concat('{',vf:jsonType($v),'}') ,',')"/>
                   ]
               </xsl:when>
               <xsl:otherwise>
                   <xsl:value-of select="vf:jsonType(datatype/vodml-ref)"/>
               </xsl:otherwise>
           </xsl:choose>
         }
      }
  </xsl:template>

    <!-- allow for "plain aggregation" of references-->
    <xsl:template match="reference[multiplicity/maxOccurs!=1]" >
        , "<xsl:value-of select="name"/>" : {
        "type":"array"
        ,"items": {
        <xsl:value-of select="vf:jsonReferenceType(datatype/vodml-ref)"/>
        }
        ,<xsl:apply-templates select="description"/>
        }
    </xsl:template>


    <xsl:template match="reference" > <!-- IMPL normally this will be just an integer reference to an existing instance - apart from first occurrence of contained reference
  IMPL - ideally this would just be a reference - however if there is a reference within a reference then the first instance might be the object-->
      , "<xsl:value-of select="name"/>" : {
      "oneOf" : [
      {<xsl:value-of select="vf:jsonReferenceType(datatype/vodml-ref)"/>},
      {<xsl:value-of select="vf:jsonType(datatype/vodml-ref)"/>}
      ]
      ,<xsl:apply-templates select="description"/>
      }
  </xsl:template>

</xsl:stylesheet>
