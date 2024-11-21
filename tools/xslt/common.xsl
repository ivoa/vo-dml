<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="3.0"
                xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:uml="http://schema.omg.org/spec/UML/2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
              	xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
                xmlns:vf="http://www.ivoa.net/xml/VODML/functions"

>

<!-- 
  This XSLT script contains common  templates that depend only on a single instance of a VO-DML file being in scope.
-->

  <xsl:variable name="cr">
<xsl:text>
</xsl:text>
  </xsl:variable>
  <xsl:variable name="sq"><xsl:text>'</xsl:text></xsl:variable>
  <xsl:variable name="dq"><xsl:text>"</xsl:text></xsl:variable>
  <xsl:variable name='nl'><xsl:text>
</xsl:text></xsl:variable>
  <xsl:variable name='lt'><xsl:text disable-output-escaping="yes">&lt;</xsl:text></xsl:variable>
  <xsl:variable name='gt'><xsl:text disable-output-escaping="yes">&gt;</xsl:text></xsl:variable>

  <!-- templates -->
  <xsl:template name="upperFirst">
    <xsl:param name="val"/>

    <xsl:variable name="prem" select="substring($val,1,1)"/>
    <xsl:variable name="first" select="upper-case($prem)"/>
    <xsl:variable name="end" select="substring($val,2,string-length($val)-1)"/>
    <xsl:value-of select="concat($first,$end)"/>
  </xsl:template>


  <xsl:template name="trim">
    <xsl:param name="val"/>
    <xsl:sequence select=
         "if (string($val))
           then replace($val, '^\s*(.+?)\s*$', '$1')
           else ()
           "/>
  </xsl:template>

  <xsl:template name="constant">
    <xsl:param name="text"/>

    <xsl:variable name="v" select="replace($text, '-', '_')"/>
    <xsl:variable name="v0" select="replace($v, '0', 'ZERO')"/>
    <xsl:variable name="v1" select="replace($v0,   '1', 'ONE')"/>
    <xsl:variable name="v2" select="replace($v1,   '2', 'TWO')"/>
    <xsl:variable name="v3" select="replace($v2,   '3', 'THREE')"/>
    <xsl:variable name="v4" select="replace($v3,   '4', 'FOUR')"/>
    <xsl:variable name="v5" select="replace($v4,   '5', 'FIVE')"/>
    <xsl:variable name="v6" select="replace($v5,   '-', '_')"/>
    <xsl:value-of select="translate(upper-case($v6),' .:*','___N')"/>
  </xsl:template>




  <!-- Calculate the full path to the package identified by the packageid in the indicated model!
      Use the specified delimiter. -->
  <xsl:template name="package-path">
    <xsl:param name="model"/>
    <xsl:param name="packageid"/>
    <xsl:param name="delimiter"/>
    <xsl:param name="suffix"/>
<!--     <xsl:message>package-path: packageid=<xsl:value-of select="$packageid"/> suffix=<xsl:value-of select="$suffix"/> model=<xsl:value-of select="$model/name"/></xsl:message> -->
    <xsl:variable name="p" select="$model//package[vodml-id = $packageid]"/>
    <xsl:choose>
      <xsl:when test="name($p) = 'package'">
        <xsl:variable name="newsuffix">
          <xsl:choose>
            <xsl:when test="$suffix">
              <xsl:value-of select="concat($p/name,$delimiter,$suffix)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$p/name"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="package-path">
          <xsl:with-param name="model" select="$model" as="node()"/>
          <xsl:with-param name="packageid" select="$p/../vodml-id"/>
          <xsl:with-param name="suffix" select="$newsuffix"/>
          <xsl:with-param name="delimiter" select="$delimiter"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$suffix"/>
      </xsl:otherwise>
    </xsl:choose>
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

  <!-- Only counts whether this class or subclass is contained, not if a base class is contained -->
  <xsl:template match="*[@xmi:type='uml:Class']" mode="testrootelements">
    <xsl:param name="count" select="0"/>
    <xsl:variable name="xmiid" select="@xmi:id"/>

    <xsl:choose>
      <xsl:when test="//ownedMember/ownedAttribute[@xmi:type='uml:Property' and @association and @aggregation='composite' and @type = $xmiid]">
        <xsl:value-of select="number($count)+1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="childcount" >
          <xsl:choose>
            <xsl:when test="//ownedMember[@xmi:type='uml:Class' and generalization/@general = $xmiid]">
            <xsl:for-each select="//ownedMember[@xmi:type='uml:Class' and generalization/@general = $xmiid]">
              <xsl:apply-templates select="." mode="testrootelements">
                <xsl:with-param name="count" select="$count"/>
              </xsl:apply-templates>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="0"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="number($count)+number($childcount)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




  <xsl:template match="*[@xmi:type='uml:Class']" mode="dummy">
    <xsl:message><xsl:value-of select="@name"/></xsl:message>
    <xsl:value-of select="'0'"/>
  </xsl:template>



<!-- cut prefix off -->
  <xsl:template match="vodml-ref" mode="asvodmlid">
    <xsl:value-of select="substring-after(.,':')"/>
  </xsl:template>

  <xsl:template match="vodml-ref" mode="prefix">
    <xsl:value-of select="substring-before(.,':')"/>
  </xsl:template>
<!-- add prefix -->
  <xsl:template match="vodml-id" mode="asvodml-ref">
    <xsl:value-of select="concat(./ancestor::vo-dml:model/name,':',.)" />
  </xsl:template>

  <xsl:function name="vf:multiple" as="xsd:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="xsd:int($p/multiplicity/maxOccurs) ne 1"/>
  </xsl:function>

  <xsl:template match="multiplicity" mode="tostring">
    <xsl:variable name="lower">
      <xsl:choose>
        <xsl:when test="minOccurs"><xsl:value-of select="minOccurs"/></xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="upper">
      <xsl:choose>
        <xsl:when test="not(maxOccurs)"><xsl:value-of select="'1'"/></xsl:when>
        <xsl:when test="number(maxOccurs) lt 0"><xsl:value-of select="'*'"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="maxOccurs"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      <xsl:choose>
        <xsl:when test="$lower = $upper"><xsl:value-of select="$lower"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat($lower,'..',$upper)"/></xsl:otherwise>
      </xsl:choose>
  </xsl:template>
  <xsl:template match="vo-dml:model" mode="xsd-path">
    <xsl:param name="delimiter"/>
    <xsl:param name="suffix" select="''"/>
    <xsl:value-of select="concat(vodml-id,$suffix)"/>
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


</xsl:stylesheet>