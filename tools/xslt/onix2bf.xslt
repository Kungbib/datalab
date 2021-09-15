<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:o="http://ns.editeur.org/onix/3.0/reference"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:foaf="http://xmlns.com/foaf/0.1/"
                xmlns="http://id.loc.gov/ontologies/bibframe/">

    <xsl:output method="xml" indent="yes" encoding="utf-8"/>

    <xsl:template match="/">
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <!--
    o:ONIXMessage
        @release
        o:Header
            o:Sender
                o:SenderIdentifier
                    o:SenderIDType
                    o:IDValue
                o:EmailAddress
            o:SentDateTime
            o:DefaultCurrencyCode
    -->

    <xsl:template match="o:Product">
        <xsl:variable name="base-uri">
            <xsl:value-of select="o:RecordReference"/>
        </xsl:variable>
        <xsl:variable name="type">
            <xsl:choose>
                <!-- TODO: https://onix-codelists.io/codelist/150 -->
                <xsl:when test="starts-with(o:DescriptiveDetail/o:ProductForm, 'E')">Electronic</xsl:when>
                <xsl:when test="starts-with(o:DescriptiveDetail/o:ProductForm, 'B')">Print</xsl:when>
                <xsl:otherwise>Instance</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$type}">
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="$base-uri"/>
                <xsl:text>#it</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="o:ProductIdentifier"/>
            <xsl:for-each select="o:DescriptiveDetail/o:TitleDetail">
                <xsl:variable name="title">
                    <xsl:apply-templates select="."/>
                </xsl:variable>
                <xsl:if test="$title != ''">
                    <title>
                        <xsl:copy-of select="$title"/>
                    </title>
                </xsl:if>
            </xsl:for-each>
            <!--
            o:DescriptiveDetail
                o:ProductComposition
                o:ProductForm
                o:ProductFormDetail
                o:Measure
                    o:MeasureType
                    o:Measurement
                    o:MeasureUnitCode
            -->
            <xsl:for-each select="o:DescriptiveDetail/o:Extent">
                <extent>
                    <Extent>
                        <!-- o:ExtentType -->
                        <unit rdf:resource="/unit/{o:ExtentUnit}"/>
                        <rdf:value><xsl:value-of select="o:ExtentValue"/></rdf:value>
                    </Extent>
                </extent>
            </xsl:for-each>
            <xsl:for-each select="o:DescriptiveDetail/o:Collection/o:TitleDetail[o:TitleType = '01']">
                <!--
                o:Collection
                    o:CollectionType
                    o:CollectionSequence
                        o:CollectionSequenceType
                        o:CollectionSequenceNumber
                -->
                <seriesStatement>
                    <xsl:value-of select="o:TitleElement[o:TitleElementLevel = '02']/o:TitleText"/>
                </seriesStatement>
            </xsl:for-each>
            <!--
            o:DescriptiveDetail

                o:EditionNumber

                o:ProductFormFeature
                    o:ProductFormFeatureType
                    o:ProductFormFeatureValue
                    o:ProductFormFeatureDescription

                o:CountryOfManufacture
                o:ProductFormDescription

                o:AncillaryContent
                    o:AncillaryContentType
                    o:AncillaryContentDescription
                    o:Number

            o:CollateralDetail
                o:SupportingResource
                    o:ResourceContentType
                    o:ContentAudience
                    o:ResourceMode
                    o:ResourceVersion
                        o:ResourceForm
                        o:ResourceLink
            -->
            <xsl:for-each select="o:PublishingDetail">
                <provisionActivity>
                    <xsl:apply-templates select="."/>
                </provisionActivity>
            </xsl:for-each>

            <administrativeMetadata>
                <xsl:call-template name="adminmeta">
                    <xsl:with-param name="base-uri" select="$base-uri"/>
                </xsl:call-template>
            </administrativeMetadata>
            <instanceOf>
                <xsl:call-template name="work">
                    <xsl:with-param name="base-uri" select="$base-uri"/>
                </xsl:call-template>
            </instanceOf>
            <xsl:for-each select="o:RelatedMaterial/o:RelatedProduct">
                <xsl:variable name="link">
                    <xsl:choose>
                        <xsl:when test="o:ProductRelationCode = 'TODO'">TODO</xsl:when>
                        <xsl:otherwise>relatedTo</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:element name="{$link}">
                    <xsl:apply-templates select="."/>
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each select="o:ProductSupply/o:SupplyDetail">
                <hasItem>
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="base-uri" select="$base-uri"/>
                    </xsl:apply-templates>
                </hasItem>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template match="o:TitleDetail[o:TitleType='01']">
        <Title>
            <mainTitle>
                <!--
                o:TitleElement/o:TitleElementLevel
                -->
                <xsl:value-of select="o:TitleElement/o:TitleText"/>
            </mainTitle>
        </Title>
    </xsl:template>

    <xsl:template match="o:TitleDetail[o:TitleType='03']">
        <OriginalTitle>
            <mainTitle>
                <xsl:value-of select="o:TitleElement/o:TitleText"/>
            </mainTitle>
        </OriginalTitle>
    </xsl:template>

    <xsl:template match="o:TitleDetail[o:TitleType='10']">
    </xsl:template>

    <xsl:template match="o:Contributor[o:PersonNameInverted]">
        <Person>
            <!--
            o:NamesBeforeKey
            o:KeyNames
            -->
            <xsl:for-each select="o:NamesBeforeKey">
                <foaf:givenName>
                    <xsl:value-of select="."/>
                </foaf:givenName>
            </xsl:for-each>
            <xsl:for-each select="o:KeyNames">
                <foaf:familyName>
                    <xsl:value-of select="."/>
                </foaf:familyName>
            </xsl:for-each>
            <!--
            <xsl:for-each select="o:PersonNameInverted">
                <rdfs:label>
                    <xsl:value-of select="."/>
                </rdfs:label>
            </xsl:for-each>
            -->
        </Person>
    </xsl:template>

    <xsl:template match="o:Contributor[o:CorporateName]">
        <Organization>
            <name>
                <xsl:value-of select="o:CorporateName"/>
            </name>
        </Organization>
    </xsl:template>

    <xsl:template match="o:Contributor">
        <Agent>
        <!--
        o:Website
            o:WebsiteRole
            o:WebsiteLink
        o:NameType
        -->
        </Agent>
    </xsl:template>

    <xsl:template match="o:PublishingDetail[o:Publisher/o:PublishingRole = '01']">
        <Publication>
            <xsl:call-template name="provisionactivity"/>
        </Publication>
    </xsl:template>

    <xsl:template match="o:PublishingDetail[o:Publisher/o:PublishingRole = '04']">
        <!-- TODO: originalVersion  -->
        <Publication>
            <xsl:call-template name="provisionactivity"/>
        </Publication>
    </xsl:template>

    <xsl:template match="o:PublishingDetail[o:Publisher/o:PublishingRole = '17']">
        <Manufacture>
            <xsl:call-template name="provisionactivity"/>
        </Manufacture>
    </xsl:template>

    <xsl:template name="provisionactivity">
        <!--
        o:PublishingStatus = '04' => Active
        o:PublishingStatus = '08' => Inactive
        -->
        <xsl:for-each select="o:Publisher">
            <agent>
                <xsl:apply-templates select="."/>
            </agent>
        </xsl:for-each>
        <xsl:for-each select="o:PublishingDate[o:PublishingDateRole = '01' or o:PublishingDateRole = '09']">
            <xsl:apply-templates select="o:Date"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="o:Date[@dateformat = '12']">
        <label><xsl:value-of select="."/></label>
    </xsl:template>

    <xsl:template match="o:Date">
        <date><xsl:value-of select="."/></date>
    </xsl:template>

    <xsl:template match="o:Publisher">
        <Agent>
            <!--
            o:Publisher
                o:PublisherIdentifier
                    o:PublisherIDType
                    o:IDTypeName
                    o:IDValue
                o:Website
                    o:WebsiteRole
                    o:WebsiteLink
            -->
            <name><xsl:value-of select="o:PublisherName"/></name>
        </Agent>
    </xsl:template>

    <xsl:template name="work">
        <xsl:param name="base-uri"/>
        <xsl:variable name="type">
            <xsl:choose>
                <!-- TODO: https://onix-codelists.io/codelist/150 -->
                <xsl:when test="starts-with(o:DescriptiveDetail/o:ProductForm, 'A')">Audio</xsl:when>
                <xsl:when test="starts-with(o:DescriptiveDetail/o:ProductForm, 'B')">Text</xsl:when>
                <xsl:when test="starts-with(o:DescriptiveDetail/o:ProductForm, 'C')">Cartography</xsl:when>
                <xsl:otherwise>Work</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$type}">
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="$base-uri"/>
                <xsl:text>#work</xsl:text>
            </xsl:attribute>
            <xsl:for-each select="o:DescriptiveDetail/o:Contributor">
                <contribution>
                    <Contribution>
                        <!--
                        o:SequenceNumber
                        o:ContributorDate
                            o:ContributorDateRole
                            o:Date
                                @dateformat
                        -->
                        <xsl:for-each select="o:ContributorRole">
                            <role>
                                <xsl:attribute name="rdf:resource">
                                    <xsl:text>/role/</xsl:text>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </xsl:attribute>
                            </role>
                        </xsl:for-each>
                        <agent>
                            <xsl:apply-templates select="."/>
                        </agent>
                    </Contribution>
                </contribution>
            </xsl:for-each>
            <xsl:for-each select="o:DescriptiveDetail">
                <xsl:for-each select="o:Language">
                    <!-- o:LanguageRole -->
                    <language>
                        <xsl:attribute name="rdf:resource">
                            <xsl:text>/language/</xsl:text>
                            <xsl:value-of select="normalize-space(o:LanguageCode)"/>
                        </xsl:attribute>
                    </language>
                </xsl:for-each>
                <xsl:for-each select="o:Subject">
                    <subject>
                        <skos:Concept>
                            <xsl:if test="o:SubjectSchemeIdentifier and o:SubjectCode">
                                <xsl:attribute name="rdf:about">
                                    <xsl:text>/scheme/</xsl:text>
                                    <xsl:value-of select="normalize-space(o:SubjectSchemeIdentifier)"/>
                                    <xsl:text>/</xsl:text>
                                    <xsl:value-of select="normalize-space(o:SubjectCode)"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:for-each select="o:SubjectSchemeIdentifier">
                                <skos:inScheme>
                                    <xsl:attribute name="rdf:resource">
                                        <xsl:text>/scheme/</xsl:text>
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </xsl:attribute>
                                </skos:inScheme>
                            </xsl:for-each>
                            <xsl:for-each select="o:SubjectCode">
                                <code><xsl:value-of select="."/></code>
                            </xsl:for-each>
                            <xsl:for-each select="o:SubjectHeadingText">
                                <rdfs:label><xsl:value-of select="."/></rdfs:label>
                            </xsl:for-each>
                        </skos:Concept>
                    </subject>
                </xsl:for-each>
                <xsl:for-each select="o:NameAsSubject">
                    <subject>
                        <Person>
                            <xsl:for-each select="o:PersonNameInverted">
                                <rdfs:label><xsl:value-of select="."/></rdfs:label>
                            </xsl:for-each>
                        </Person>
                    </subject>
                </xsl:for-each>
                <xsl:if test="o:Illustrated = '02'">
                    <illustrativeContent>
                        <Illustration/>
                    </illustrativeContent>
                </xsl:if>
                <xsl:for-each select="o:AudienceRange">
                    <xsl:variable name="precision">
                        <xsl:choose>
                            <xsl:when test="o:AudienceRangePrecision = '01'">exact</xsl:when>
                            <xsl:when test="o:AudienceRangePrecision = '03'">from</xsl:when>
                            <xsl:when test="o:AudienceRangePrecision = '04'">to</xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="qualifier">
                        <xsl:choose>
                            <xsl:when test="o:AudienceRangeQualifier = '16'">months</xsl:when>
                            <xsl:when test="o:AudienceRangeQualifier = '17' or o:AudienceRangeQualifier = '18'">years</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="o:AudienceRangeQualifier"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <intendedAudience rdf:resource="/audience/{$precision}/{o:AudienceRangeValue}/{$qualifier}"/>
                </xsl:for-each>
                <!--
                o:Audience
                    o:AudienceCodeType
                    o:AudienceCodeValue
                -->
            </xsl:for-each>
            <!--
            o:CollateralDetail
                o:TextContent
                    o:TextType
                    o:ContentAudience
                    o:Text
                o:Prize
                    o:PrizeName
            -->
            <xsl:for-each select="o:CollateralDetail/o:TextContent[
                          o:TextType = '02' and o:ContentAudience = '00']">
                <sumary>
                    <Summary>
                        <rdfs:label>
                            <xsl:apply-templates select="o:Text"/>
                        </rdfs:label>
                    </Summary>
                </sumary>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template match="o:ProductSupply/o:SupplyDetail">
        <xsl:param name="base-uri"/>
        <Item>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="$base-uri"/>
                <xsl:text>#item-</xsl:text>
                <xsl:value-of select="generate-id(.)"/>
            </xsl:attribute>
            <xsl:for-each select="o:Supplier">
                <heldBy>
                    <Agent>
                        <!--
                        o:SupplierRole
                        o:SupplierIdentifier
                            o:SupplierIDType
                            o:IDTypeName
                            o:IDValue
                        -->
                        <name><xsl:value-of select="o:SupplierName"/></name>
                    </Agent>
                </heldBy>
            </xsl:for-each>
        <!--
        o:ProductAvailability
        o:Stock
            o:OnHand
        o:Price
            o:PriceType
            o:PriceAmount
            o:Tax
                o:TaxType
                o:TaxRatePercent
            o:PriceQualifier
            o:PriceDate
                o:PriceDateRole
                o:Date
                    @dateformat
            o:PriceCoded
                o:PriceCodeType
                o:PriceCode
            o:UnpricedItemType
        o:SupplyDate
            o:SupplyDateRole
            o:Date
        -->
        </Item>
    </xsl:template>

    <xsl:template name="adminmeta">
        <xsl:param name="base-uri"/>
        <AdministrativeMetadata>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="$base-uri"/>
                <xsl:text>#meta</xsl:text>
            </xsl:attribute>
            <xsl:for-each select="o:RecordReference">
                <identifiedBy>
                    <Identifier>
                        <rdf:value><xsl:value-of select="."/></rdf:value>
                    </Identifier>
                </identifiedBy>
            </xsl:for-each>
            <!--
            o:NotificationType
            -->
        </AdministrativeMetadata>
    </xsl:template>

    <xsl:template match="o:RelatedProduct">
        <Instance>
            <xsl:apply-templates select="o:ProductIdentifier"/>
        </Instance>
    </xsl:template>

    <xsl:template match="o:ProductIdentifier">
        <identifiedBy>
            <xsl:variable name="type">
                <xsl:choose>
                    <xsl:when test="o:ProductIDType = '15'">Isbn</xsl:when>
                    <xsl:when test="o:ProductIDType = '03'">Isbn</xsl:when>
                    <xsl:otherwise>Identifier</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:element name="{$type}">
                <rdf:value><xsl:value-of select="o:IDValue"/></rdf:value>
            </xsl:element>
        </identifiedBy>
    </xsl:template>

</xsl:stylesheet>
