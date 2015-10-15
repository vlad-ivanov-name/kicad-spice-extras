<?xml version="1.0" encoding="ISO-8859-1"?>

<!DOCTYPE xsl:stylesheet [
  <!ENTITY nl "&#xd;&#xa;">
]>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

<xsl:variable name="spice_controller" select="export/components/comp/fields/field[@name='SPICE_CONTROLLER']" />

<xsl:template match="/export">
	<!-- file header -->
	<xsl:text>* </xsl:text>
	<xsl:value-of select="design/source" />
    <xsl:text>&nl;</xsl:text>
    <xsl:text>* Kicad to TINA netlist XSLT transformer &nl;&nl;</xsl:text>

    <!-- Components -->
    <xsl:apply-templates mode="components" select="components/comp" />
    
	<!-- Connect ground node -->
	<xsl:apply-templates mode="ground" select="nets/net[@name='GND']" />
	
	<!-- Process controllers -->
	<xsl:apply-templates mode="controller" select="$spice_controller"/>
	
	<!-- Process voltage probes -->
	<xsl:apply-templates mode="vprobe" select="nets/net" />

    <!-- Footer -->
    <xsl:text>&nl;.END&nl;</xsl:text>
</xsl:template>

<xsl:template match="nets/net" mode="vprobe">
	<xsl:if test="node[starts-with(@ref, 'VP')]">
		<xsl:text>.PRINT </xsl:text>
		<xsl:apply-templates mode="controller_name" select="$spice_controller"/>
		<xsl:apply-templates mode="vprobe_apply" select="node[starts-with(@ref, 'VP')]" />
		<xsl:text>&nl;</xsl:text>
	</xsl:if>
</xsl:template>

<xsl:template match="net/node" mode="vprobe_apply">
	<xsl:text> V(</xsl:text>
	<xsl:call-template name="net_name">
		<xsl:with-param name="net_code" select="../@code" />
		<xsl:with-param name="net_name" select="../@name" />
	</xsl:call-template>
	<xsl:text>) </xsl:text>
</xsl:template>

<xsl:template match="components/comp/fields/field" mode="controller">
	<xsl:text>.</xsl:text>
	<xsl:value-of select="." />
	<xsl:text> </xsl:text>
	<xsl:value-of select="../field[@name='SPICE_PARAMS']" />
	<xsl:text>&nl;</xsl:text>
</xsl:template>

<xsl:template match="components/comp/fields/field" mode="controller_name">
	<xsl:value-of select="." />
</xsl:template>

<!-- for each component -->
<xsl:template match="components/comp" mode="components">
    <xsl:variable name="ref" select="@ref" />
    
    <!-- Do not process spice-extras components -->
    <xsl:choose>
    	<xsl:when test="fields/field[@name='SPICE_EXTRA']"></xsl:when>
    	<xsl:otherwise>
			<xsl:value-of select="@ref"/>
		
		    <!-- Apply transformation to a list of nodes associated with this component-->
		    <xsl:apply-templates select="../../nets/net/node[@ref=$ref]">
		    	<xsl:sort select="@pin" />
		    	<xsl:with-param name="component">
		    		<xsl:value-of select="@ref"/>
		    	</xsl:with-param>
		    </xsl:apply-templates>
		    
		    <xsl:text>&nl;</xsl:text>
	    </xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template mode="ground" match="nets/net">
	<xsl:text>R_GND </xsl:text>
	<xsl:value-of select="@code" />
	<xsl:text>_</xsl:text>
	<xsl:value-of select="@name" />
	<xsl:text> 0 0&nl;&nl;</xsl:text>
</xsl:template>

<xsl:template match="net/node">
	<xsl:param name="component" />
	<xsl:text> </xsl:text>

	<xsl:call-template name="net_name">
		<xsl:with-param name="net_code" select="../@code" />
		<xsl:with-param name="net_name" select="../@name" />
	</xsl:call-template>
	
	<xsl:text> </xsl:text>
</xsl:template>

<xsl:template name="net_name">
	<xsl:param name="net_code" />
	<xsl:param name="net_name" />
	
	<!--  Check for default name -->
	<xsl:choose> 
		<xsl:when test="starts-with($net_name, 'Net-(')">
			<xsl:value-of select="$net_code" />
		</xsl:when>		
		<xsl:otherwise>
			<!-- For TINA, net name should start with a number -->
			<xsl:value-of select="$net_code" />
			<xsl:text>_</xsl:text>
			<xsl:value-of select="translate($net_name, '-/()', '')" />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
