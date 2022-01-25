<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:sm="http://www.sitemaps.org/schemas/sitemap/0.9"
                xmlns:rs="http://www.openarchives.org/rs/terms/"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns="http://schema.org/"
                exclude-result-prefixes="rs sm">

  <xsl:output method="xml" indent="yes" encoding="utf-8"/>

  <xsl:template match="/sm:urlset">
    <xsl:variable name="feedtype">
      <xsl:choose>
        <xsl:when test="rs:md[@capability='resourcelist']">CompleteDataFeed</xsl:when>
        <xsl:otherwise>DataFeed</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$feedtype}">
      <xsl:for-each select="rs:ln[@rel='self']">
        <xsl:attribute name="rdf:about">
          <xsl:value-of select="@href"/>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:for-each select="rs:md[@capability='resourcelist']/@at | rs:md[@capability='changelist']/@until">
        <dateModified><xsl:value-of select="."/></dateModified>
      </xsl:for-each>
      <xsl:apply-templates select="sm:url"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="sm:url">
    <dataFeedElement rdf:parseType="Resource">
      <item>
        <!-- TODO: if not(rs:ln[@rel='alternate']), apply as MediaObject -->
        <rdf:Description rdf:about="{sm:loc}">
          <xsl:for-each select="sm:lastmod">
            <dateModified><xsl:value-of select="."/></dateModified>
          </xsl:for-each>
          <xsl:for-each select="rs:ln[@rel='describes']">
            <mainEntity rdf:resource="{@href}"/>
          </xsl:for-each>
          <xsl:for-each select="rs:ln[@rel='alternate']">
            <encoding>
              <MediaObject rdf:about="{@href}">
                <xsl:for-each select="@type">
                  <encodingFormat><xsl:value-of select="."/></encodingFormat>
                </xsl:for-each>
                <xsl:for-each select="@hash[starts-with(., 'sha-256:')]">
                  <sha256><xsl:value-of select="substring-after(., 'sha-256:')"/></sha256>
                </xsl:for-each>
                <xsl:for-each select="@length">
                  <fileSize><xsl:value-of select="."/> B</fileSize>
                </xsl:for-each>
              </MediaObject>
            </encoding>
          </xsl:for-each>
        </rdf:Description>
      </item>
      <xsl:choose>
        <xsl:when test="rs:md[@change='deleted']">
          <dateDeleted><xsl:value-of select="rs:md/@datetime"/></dateDeleted>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="rs:md[@change='updated']/@datetime | rs:md/@at">
            <dateModified><xsl:value-of select="."/></dateModified>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </dataFeedElement>
  </xsl:template>

</xsl:stylesheet>
