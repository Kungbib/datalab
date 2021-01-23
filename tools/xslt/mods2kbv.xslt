<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mods="http://www.loc.gov/mods/v3" 
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns="https://id.kb.se/vocab/"
                extension-element-prefixes="str"
                xmlns:str="http://exslt.org/strings">

    <xsl:template match="mods:mods">
        <Electronic rdf:about="{mods:identifier[@type='local']}">
            <meta>
                <Record>
                    <xsl:for-each select="mods:relatedItem[@type='host' and mods:genre = 'project']">
                        <inDataset rdf:resource="{mods:identifier[@type='uri']}"/>
                    </xsl:for-each>
                </Record>
            </meta>
            <xsl:for-each select="mods:identifier[not(@type='local')]">
                <sameAs rdf:resource="{.}"/>
            </xsl:for-each>
            <xsl:for-each select="mods:relatedItem[@type='host' and mods:genre = 'newspaper']/mods:identifier[@type='uri']">
                <hasSeries rdf:resource="{.}"/>
            </xsl:for-each>
            <instanceOf>
                <xsl:call-template name="thing">
                    <xsl:with-param name="body">
                        <xsl:apply-templates select="mods:language"/>
                    </xsl:with-param>
                </xsl:call-template>
            </instanceOf>
            <xsl:apply-templates select="mods:titleInfo|mods:physicalDescription"/>
            <xsl:variable name="originInfo">
                <xsl:apply-templates select="mods:originInfo"/>
            </xsl:variable>
            <xsl:for-each select="mods:relatedItem[@type='original']">
                <reproductionOf>
                    <xsl:call-template name="thing">
                        <xsl:with-param name="body">
                            <xsl:copy-of select="$originInfo"/>
                            <xsl:apply-templates/>
                        </xsl:with-param>
                    </xsl:call-template>
                </reproductionOf>
            </xsl:for-each>
        </Electronic>
    </xsl:template>

    <xsl:template name="thing">
        <xsl:param name="body"/>
        <xsl:variable name="worktype">
            <xsl:choose>
                <xsl:when test="mods:physicalDescription/mods:form[@authority='marcform'] = 'print'">Print</xsl:when>
                <xsl:when test="mods:typeOfResource[. = 'text']">Text</xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="mods:typeOfResource"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$worktype}">
            <xsl:copy-of select="$body"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="mods:titleInfo">
        <hasTitle>
            <Title>
                <mainTitle><xsl:value-of select="mods:title"/></mainTitle>
            </Title>
        </hasTitle>
    </xsl:template>

    <xsl:template match="mods:languageTerm[@authority='iso639-2b' and @type='code']">
        <language rdf:resource="{$terms}/language/{.}"/>
    </xsl:template>

    <xsl:template match="mods:edition">
        <editionStatement><xsl:value-of select="."/></editionStatement>
    </xsl:template>

    <xsl:template match="mods:dateIssued">
        <publication>
            <PrimaryPublication>
                <date><xsl:value-of select="."/></date>
            </PrimaryPublication>
        </publication>
    </xsl:template>

    <xsl:template match="mods:physicalDescription">
        <xsl:apply-templates select="mods:note[@type='reproduction']"/>
    </xsl:template>

    <xsl:template match="mods:note[@type='reproduction']">
        <production>
            <Reproduction>
                <label><xsl:value-of select="."/></label>
            </Reproduction>
        </production>
    </xsl:template>

    <xsl:template match="mods:identifier[@type='local']">
        <identifiedBy>
            <Local>
                <value><xsl:value-of select="."/></value>
            </Local>
        </identifiedBy>
    </xsl:template>

</xsl:stylesheet>
