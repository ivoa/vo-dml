<?xml version="1.0" encoding="UTF-8"?>
<!-- 
This XSLT script transforms a data model from our
intermediate representation to a graphml representation with extensions that can
be read by https://www.yworks.com/products/yed to allow interactive editing.

derived from the vo-dml2gvd.xsl file
 -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				    xmlns:exsl="http://exslt.org/common"
                xmlns:vodml="http://www.ivoa.net/xml/VODML/v1" 
                xmlns="http://graphml.graphdrawing.org/xmlns/graphml"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:y="http://www.yworks.com/xml/graphml"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="vodml" >
  
  <xsl:import href="common.xsl"/>
  
  <xsl:output method="xml" encoding="UTF-8" indent="yes" xmlns="http://graphml.graphdrawing.org/xmlns/graphml" />
  
  <xsl:strip-space elements="*" />
  
  <xsl:key name="element" match="*//vodml-id" use="."/>
  <xsl:key name="package" match="*//package/vodml-id" use="."/>
  <xsl:key name="modelDocURLs" match="*//import/documentationURL" use="../name"/>

  <xsl:param name="project.name"/>
  <xsl:param name="usesubgraph" select="'F'"/>
    <xsl:variable name="imported">
        <xsl:for-each select="vodml:model/import">
            <xsl:message>importing <xsl:value-of select="url"/> </xsl:message>
            <xsl:copy-of select="document(url)/vodml:model"/>
        </xsl:for-each>
    </xsl:variable>
  
  <xsl:variable name="packages" select="//package/vodml-id"/>
  <xsl:variable name="sq"><xsl:text>'</xsl:text></xsl:variable>
  <xsl:variable name="dq"><xsl:text>"</xsl:text></xsl:variable>
  <xsl:variable name='nl'><xsl:text>
</xsl:text></xsl:variable>
  <xsl:variable name='lt'><xsl:text disable-output-escaping="yes">&lt;</xsl:text></xsl:variable>
  <xsl:variable name='gt'><xsl:text disable-output-escaping="yes">&gt;</xsl:text></xsl:variable>

  <xsl:template match="/">
  <xsl:message>Starting GML</xsl:message>
    <xsl:apply-templates select="vodml:model"/>
  </xsl:template>
  
  <xsl:template match="vodml:model">  
  <xsl:message>Found model</xsl:message>
  <xsl:element name="graphml" namespace="http://graphml.graphdrawing.org/xmlns/graphml" >
  <xsl:attribute name="schemaLocation" namespace="http://www.w3.org/2001/XMLSchema-instance">http://graphml.graphdrawing.org/xmlns http://www.yworks.com/xml/schema/graphml/1.0/ygraphml.xsd</xsl:attribute>
  
   <!-- todo - put all of the model metadata here.... -->
     <key attr.name="Title" attr.type="string" for="graph" id="t0">
       <default xml:space="preserve"><xsl:value-of select="name"/></default>
     </key>
      <key attr.name="description" attr.type="string" for="node" id="k1"/>
      <key id="k2" for="node" yfiles.type="nodegraphics"/>
      <key id="k3" for="edge" yfiles.type="edgegraphics"/>
      <key id="k4" for="graph" yfiles.type="postprocessors"/>
  
  <xsl:element name="graph" namespace="http://graphml.graphdrawing.org/xmlns/graphml">
  <xsl:attribute name="edgedefault">directed</xsl:attribute>
      <xsl:comment>nodes</xsl:comment>
     <xsl:apply-templates select="*"/>
      <xsl:comment>imported nodes</xsl:comment>
      <!-- TODO would be nice to have difference colours for the imported nodes -->
      <xsl:for-each  select="distinct-values((//extends|//reference/datatype|//composition/datatype)[substring-before(vodml-ref,':') != /vodml:model/name])">
          <xsl:message>imported ref to <xsl:value-of select="."/> </xsl:message>
          <xsl:apply-templates select="$imported/vodml:model[name=substring-before(current(),':')]//*[vodml-id = substring-after(current(),':')]"/>
      </xsl:for-each>

      <xsl:comment>edges</xsl:comment>

      <xsl:apply-templates select="//extends"/>
   <xsl:apply-templates select="//objectType/composition"/>
   <xsl:apply-templates select="//reference"/>
   
   <!-- unfortunately the postprocessor stuff only works automatically with the yFiles SDK not yed - so need to manually fit and do layout on opening.
     https://yed.yworks.com/support/qa/6902/capabilities-of-yfiles-graphml-post-processors  -->
        <data key="k4">
          <y:Postprocessors>
            <y:Processor class="yext.graphml.processor.NodeSizeAdapter">
              <y:Option name="IGNORE_WIDTHS" value="false"/>
              <y:Option name="IGNORE_HEIGHTS" value="false"/>
              <y:Option name="ADAPT_TO_MAXIMUM_NODE" value="false"/>
            </y:Processor>
            <y:Processor class="y.module.TreeLayoutModule">
              <y:Option name="GENERAL.LAYOUT_STYLE" value="AR"/>
              <y:Option name="AR.BEND_DISTANCE" value="20"/>
              <y:Option name="AR.VERTICAL_SPACE" value="10"/>
              <y:Option name="AR.ASPECT_RATIO" value="1.41"/>
              <y:Option name="AR.HORIZONTAL_SPACE" value="10"/>
              <y:Option name="AR.USE_VIEW_ASPECT_RATIO" value="true"/>
            </y:Processor>
          </y:Postprocessors>
        </data>
  </xsl:element>
  </xsl:element>
  </xsl:template>
  
  
<xsl:template match="vodml:model/name">
</xsl:template>
<xsl:template match="vodml:model/description">
</xsl:template>
<xsl:template match="vodml:model/title">
</xsl:template>
<xsl:template match="vodml:model/author">
</xsl:template>
<xsl:template match="vodml:model/version">
</xsl:template>
<xsl:template match="vodml:model/lastModified">
</xsl:template>


<xsl:template match="vodml:model/import">
</xsl:template>


  <xsl:template match="package">
       <node id="{generate-id()}" yfiles.foldertype="group">
         <data key="k2">
            <y:GroupNode>
               <y:Fill color="#E8E9CA" transparent="false" />
               <y:BorderStyle color="#000000" raised="false"
         type="dashed" width="1.0" />
              <y:NodeLabel alignment="left" autoSizePolicy="node_width"
              modelName="sides" modelPosition="n"
              backgroundColor="#F2F0D8"
              ><xsl:value-of select="name"/></y:NodeLabel>
            </y:GroupNode>
         </data>
        <graph edgedefault="directed" id="G">
          <xsl:apply-templates select="child::node()"/>
       </graph>
       </node>
  </xsl:template>

  

  <xsl:template match="objectType|dataType|enumeration|primitiveType">
    <xsl:variable name="nodename">
        <xsl:apply-templates select="." mode="nodename"/>
    </xsl:variable>
    <xsl:variable name="label">
        <xsl:apply-templates select="." mode="nodelabel"/>
    </xsl:variable>
    <xsl:variable name="stereotype">
      <xsl:choose>
        <xsl:when test="self::enumeration|self::primitiveType"><xsl:value-of select="local-name()"/></xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
     <xsl:variable name="fontstyle">
        <xsl:choose>
          <xsl:when test="@abstract = 'true'">bolditalic</xsl:when>
          <xsl:otherwise>bold</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
   
    
    <xsl:element name="node" namespace="http://graphml.graphdrawing.org/xmlns/graphml">
       <xsl:attribute name="id"><xsl:value-of select="$nodename"/>
       </xsl:attribute>
       <xsl:element name="data" namespace="http://graphml.graphdrawing.org/xmlns/graphml">
       <xsl:attribute name="key">k1</xsl:attribute>
       <xsl:value-of select="$label"/>
       </xsl:element>
       <data key="k2">
        <y:UMLClassNode>
          <y:Fill color="#BDB992" transparent="false"/>
          <y:BorderStyle color="#000000" type="line" width="1.0"/>
          <y:NodeLabel alignment="center"
   autoSizePolicy="content" fontFamily="Dialog" fontSize="12"
   fontStyle="{$fontstyle}" hasBackgroundColor="false" hasLineColor="false"
   horizontalTextPosition="center" iconTextGap="4" modelName="internal"
   modelPosition="c" textColor="#000000" verticalTextPosition="bottom"
   visible="true" xml:space="preserve" y="3.0"
><xsl:value-of select="$label" /></y:NodeLabel>
          <y:UML clipContent="true" constraint="" hasDetailsColor="false" omitDetails="false" stereotype="{$stereotype}" use3DEffect="true">
            <y:AttributeLabel xml:space="preserve"><xsl:apply-templates select="attribute|literal"/></y:AttributeLabel>
            <y:MethodLabel xml:space="preserve"></y:MethodLabel>
          </y:UML>
        </y:UMLClassNode>
        </data>
    </xsl:element>
 </xsl:template>



<!--  NOTE keep starting an ending <xsl:text> elements -->
  <xsl:template match="attribute">
  <xsl:text>+</xsl:text> <xsl:value-of select="name"/> : <xsl:value-of select="concat(datatype/vodml-ref,$nl)"/>
  </xsl:template>




  <xsl:template match="literal">
  <xsl:text>+</xsl:text> <xsl:value-of select="concat(name,$nl)"/>
  </xsl:template>



  <xsl:template match="extends">
    <xsl:variable name="fromnode">
        <xsl:apply-templates select=".." mode="nodename">
    </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="tonode">
        <xsl:apply-templates select="vodml-ref" mode="nodename">
    </xsl:apply-templates>
    </xsl:variable>
     <edge id="{generate-id()}" source="{$fromnode}" target="{$tonode}">
      <data key="k3">
        <y:PolyLineEdge>
          <y:LineStyle color="#FF0000" type="line" width="2.0"/>
          <y:Arrows source="none" target="white_delta"/>
          <y:BendStyle smoothed="false"/>
        </y:PolyLineEdge>
      </data>
    </edge>
    
  </xsl:template>


  <xsl:template match="composition|reference">
    <xsl:variable name="fromnode">
        <xsl:apply-templates select=".." mode="nodename">
    </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="tonode">
        <xsl:apply-templates select="datatype/vodml-ref" mode="nodename"/>
    </xsl:variable>
     <edge id="{generate-id()}" source="{$fromnode}" target="{$tonode}">
      <data key="k3">
        <y:PolyLineEdge>
        <xsl:choose>
          <xsl:when test="self::composition">
            <y:LineStyle color="#9393FF" type="line" width="2.0"/>
            <y:Arrows source="diamond" target="standard"/>
          </xsl:when>
          <xsl:otherwise>
            <y:LineStyle color="#00FF00" type="line" width="2.0"/>
            <y:Arrows source="none" target="standard"/>
          </xsl:otherwise>
        </xsl:choose>
          <y:BendStyle smoothed="false"/>
   <y:EdgeLabel alignment="center"
      configuration="AutoFlippingLabel" distance="2.0"
      fontFamily="Dialog" fontSize="12" fontStyle="plain"
      hasBackgroundColor="false" hasLineColor="false"
      horizontalTextPosition="center"
      iconTextGap="4" modelName="six_pos" modelPosition="head"
      preferredPlacement="centered" ratio="0.5" textColor="#000000"
      verticalTextPosition="bottom" visible="true" 
      xml:space="preserve" 
   ><xsl:value-of select="name"/><y:PreferredPlacementDescriptor
      angle="0.0" angleOffsetOnRightSide="0" angleReference="absolute"
      angleRotationOnRightSide="co" distance="-1.0" placement="center"
      side="on_edge" sideReference="relative_to_edge_flow" />
   </y:EdgeLabel>
   <y:EdgeLabel alignment="center"
      configuration="AutoFlippingLabel" distance="2.0"
      fontFamily="Dialog" fontSize="12" fontStyle="plain"
      hasBackgroundColor="false" hasLineColor="false"
      horizontalTextPosition="center"
      iconTextGap="4" modelName="six_pos" modelPosition="thead"
      preferredPlacement="target_on_edge" ratio="0.5"
      textColor="#000000" verticalTextPosition="bottom" visible="true"
      xml:space="preserve"
      ><xsl:apply-templates select="multiplicity" mode="tostring"/><y:PreferredPlacementDescriptor
      angle="0.0" angleOffsetOnRightSide="0" angleReference="absolute"
      angleRotationOnRightSide="co" distance="-1.0" placement="target"
      side="anywhere" sideReference="relative_to_edge_flow" />
      </y:EdgeLabel>


        </y:PolyLineEdge>
      </data>
    </edge>
    
    
<!-- 
    <xsl:value-of select="$fromnode"/> -> <xsl:value-of select="$tonode"/> [headlabel="<xsl:apply-templates select="multiplicity" mode="tostring"/>",label="<xsl:value-of select="name"/>",labelfontsize=10] ;
 -->
  </xsl:template>


 
  <xsl:template match="objectType|dataType|primitiveType|enumeration" mode="nodename">
  <xsl:variable name="vodml-ref"><xsl:apply-templates select="vodml-id" mode="asvodml-ref"/> </xsl:variable>
    <xsl:value-of select="$vodml-ref"/>
   </xsl:template>

  <!--  name of a node for a certain vodml-ref.   -->
  <xsl:template match="vodml-ref" mode="nodename">
      <xsl:value-of select="."/>
<!-- 
    <xsl:variable name="prefix" select="substring-before(.,':' )"/>
    <xsl:variable name="id" select="substring-after(.,':' )"/>
    <xsl:choose>
    <xsl:when test="$prefix=/vodml:model/name">
       <xsl:value-of select="concat('&quot;',$id,'&quot;')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat('&quot;',.,'&quot;')"/>
    </xsl:otherwise>
    </xsl:choose>
 -->
   </xsl:template>

  <xsl:template name="hyperlink">
    <xsl:param name="vodmlref"/>
    <xsl:variable name="prefix" select="substring-before($vodmlref,':')"/>
    <xsl:variable name="vodml-id" select="substring-after($vodmlref,':')"/>
    <xsl:if test="$prefix != /vodml:model/name">
        <xsl:variable name="docURL" select="/vodml:model/import[name = $prefix]/documentationURL"/>
        <a><xsl:attribute name="href" select="concat($docURL,'#',$vodml-id)"/><xsl:value-of select="$vodml-id"/></a>
    </xsl:if>
  </xsl:template>

  <xsl:template match="objectType|dataType|primitiveType|enumeration" mode="nodelabel">
<!--       <xsl:value-of select="concat('&quot;',/vodml:model/name,':',./vodml-id,'&quot;')"/>   -->
<!--       <xsl:value-of select="concat(//vodml:model/name,':',./vodml-id)"/>  -->
    <xsl:call-template name="package-path">
    <xsl:with-param name="model" select="ancestor::vodml:model"/>
    <xsl:with-param name="packageid" select="../vodml-id"/>
    <xsl:with-param name="delimiter" select="'/'"/>
    <xsl:with-param name="suffix" select="name"/>
    </xsl:call-template>
   </xsl:template>

</xsl:stylesheet>