<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Copyright (c) 2026. Paul Harrison, University of Manchester
  -->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:bnd="http://www.ivoa.net/xml/vodml-binding/v0.9.1"
>

    <xsl:mode on-no-match="shallow-copy" />
    <xsl:template match="bnd:mappedModels/model[name='ivoa']/json">
        <json lax="true" polymorphism="property"/>
    </xsl:template>

</xsl:stylesheet>