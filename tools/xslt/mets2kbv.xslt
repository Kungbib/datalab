<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mets="http://www.loc.gov/METS/" 
                xmlns:marc="http://www.loc.gov/MARC21/slim" 
                xmlns:mix="http://www.loc.gov/mix/v20" 
                xmlns:mods="http://www.loc.gov/mods/v3" 
                xmlns:premis="info:lc/xmlns/premis-v2" 
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns="https://id.kb.se/vocab/"
                extension-element-prefixes="str"
                xmlns:str="http://exslt.org/strings">

    <xsl:import href="mods2kbv.xslt"/>

    <xsl:variable name="vocab">https://id.kb.se/vocab/</xsl:variable>
    <xsl:variable name="terms">https://id.kb.se/term/</xsl:variable>

    <xsl:key name="file" match="mets:file" use="@ID"/>
    <xsl:key name="techMD" match="mets:techMD" use="@ID"/>
    <xsl:key name="dmdSec" match="mets:dmdSec" use="@ID"/>

    <xsl:template match="/mets:mets">
        <rdf:RDF>
            <FilePackage rdf:about="{@OBJID}">
                <xsl:apply-templates select="mets:metsHdr"/>
                <xsl:for-each select="mets:fileSec//mets:file">
                    <includes rdf:resource="{mets:FLocat/@xlink:href}"/>
                </xsl:for-each>
            </FilePackage>
            <xsl:apply-templates select="mets:fileSec"/>
            <xsl:apply-templates select="mets:structMap"/>
            <xsl:apply-templates select="mets:dmdSec/mets:mdWrap[@LABEL = 'Primary']"/>
            <xsl:apply-templates select="mets:dmdSec/mets:mdWrap[@LABEL = 'Local']"/>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="mets:metsHdr">
        <xsl:if test="@CREATEDATE">
            <created>
                <xsl:value-of select="@CREATEDATE"/>
            </created>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="mets:metsHdr/*">
    </xsl:template>

    <xsl:template match="mets:metsHdr/mets:altRecordID[@TYPE='DELIVERYTYPE']">
    </xsl:template>

    <xsl:template match="mets:metsHdr/mets:agent">
        <xsl:variable name="role">
            <xsl:apply-templates select="@ROLE"/>
        </xsl:variable>
        <xsl:element name="{$role}">
            <xsl:choose>
                <xsl:when test="starts-with(mets:note, 'http')">
                    <xsl:attribute name="rdf:resource">
                        <xsl:value-of select="mets:note"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>
                        <xsl:text>TODO: bnode from:&#10;</xsl:text>
                        <xsl:copy-of select="."/>
                    </xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="mets:agent/@ROLE[. = 'ARCHIVIST']">
        <xsl:text>archivist</xsl:text>
    </xsl:template>

    <xsl:template match="mets:agent/@ROLE[. = 'CREATOR']">
        <xsl:text>creator</xsl:text>
    </xsl:template>

    <xsl:template match="mets:dmdSec/mets:mdWrap[@LABEL = 'Primary']">
        <xsl:apply-imports select="mets:xmlData"/>
    </xsl:template>

    <xsl:template match="mets:dmdSec/mets:mdWrap[@LABEL = 'Local']">
    </xsl:template>

    <xsl:template match="mets:structMap[@TYPE='physical']/mets:div[@TYPE='files']/mets:div[@TYPE='issue']">
        <Representation rdf:about="{@ID}">
            <genreForm rdf:resource="{$vocab}Issue"/>
            <meta rdf:parseType="Resource">
                <derivedFrom rdf:resource="{/mets:mets/@OBJID}"/>
            </meta>
            <representationOf rdf:resource="{key('dmdSec', @DMDID)/mets:mdWrap/mets:xmlData/mods:mods/mods:identifier[@type='local']}"/>
            <!-- TODO: put on package?
            <publisher rdf:resource="TODO"/>
            <supplier rdf:resource="TODO"/>
            -->
            <xsl:apply-templates select="mets:div" mode="includes"/>
        </Representation>
    </xsl:template>

    <xsl:template match="mets:div[@TYPE]" mode="includes">
        <includes>
            <xsl:apply-templates select="."/>
        </includes>
    </xsl:template>

    <xsl:template match="mets:div[@TYPE='section']">
        <Representation rdf:about="{@ID}">
            <genreForm rdf:resource="{$vocab}Section"/>
            <xsl:apply-templates select="mets:div" mode="includes"/>
        </Representation>
    </xsl:template>

    <xsl:template match="mets:div[@TYPE='supplement']">
        <Representation rdf:about="{@ID}">
            <genreForm rdf:resource="{$vocab}Supplement"/>
            <xsl:apply-templates select="mets:div" mode="includes"/>
        </Representation>
    </xsl:template>

    <xsl:template match="mets:div[@TYPE='newsbill']">
        <Representation rdf:about="{@ID}">
            <genreForm rdf:resource="{$vocab}Newsbill"/>
            <xsl:apply-templates select="mets:div" mode="includes"/>
        </Representation>
    </xsl:template>

    <xsl:template match="mets:div[@TYPE='page']">
        <Representation rdf:about="{@ID}">
            <genreForm rdf:resource="{$vocab}Page"/>
            <number>
                <xsl:value-of select="@ORDER"/>
            </number>
            <xsl:for-each select="mets:fptr">
                <hasRepresentation rdf:resource="{key('file', @FILEID)/mets:FLocat/@xlink:href}"/>
            </xsl:for-each>
        </Representation>
    </xsl:template>

    <xsl:template match="mets:file">
        <File rdf:about="{mets:FLocat/@xlink:href}">
            <url rdf:resource="{@OWNERID}"/>
            <mediaFormat rdf:resource="{$terms}mimetype/{@MIMETYPE}"/>
            <fileSize>
                <xsl:value-of select="@SIZE"/>
            </fileSize>
            <xsl:apply-templates select="key('techMD', @ADMID)"/>
        </File>
    </xsl:template>

    <xsl:template match="mets:techMD">
        <xsl:apply-templates select="mets:mdWrap/mets:xmlData/premis:object/premis:objectCharacteristics"/>
    </xsl:template>

    <xsl:template match="premis:compositionLevel[text() != '0']">
        <compositionLevel>
            <xsl:value-of select="."/>
        </compositionLevel>
    </xsl:template>

    <xsl:template match="premis:fixity">
        <checksum>
            <xsl:element name="{premis:messageDigestAlgorithm}">
                <value><xsl:value-of select="premis:messageDigest"/></value>
                <creatorRole rdf:resource="{$vocab}{premis:messageDigestOriginator}"/>
            </xsl:element>
        </checksum>
    </xsl:template>

    <xsl:template match="mix:Compression">
        <compression><xsl:value-of select="mix:compressionScheme"/></compression>
    </xsl:template>

    <xsl:template match="mix:imageWidth">
        <width><xsl:value-of select="."/></width>
    </xsl:template>

    <xsl:template match="mix:imageHeight">
        <height><xsl:value-of select="."/></height>
    </xsl:template>

    <xsl:template match="mix:PhotometricInterpretation">
        <digitalCharacteristic>
            <ColorCharacteristic>
                <xsl:apply-templates/>
            </ColorCharacteristic>
        </digitalCharacteristic>
    </xsl:template>

    <xsl:template match="mix:colorSpace">
        <colorSpace><xsl:value-of select="."/></colorSpace>
    </xsl:template>

    <xsl:template match="mix:ColorProfile/mix:IccProfile">
        <colorProfile>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="$terms"/>
                <xsl:text>colors/icc/</xsl:text>
                <xsl:value-of select="mix:iccProfileName"/>
                <xsl:text>/</xsl:text>
                <xsl:value-of select="mix:iccProfileVersion"/>
            </xsl:attribute>
        </colorProfile>
    </xsl:template>

    <xsl:template match="mix:ImageCaptureMetadata">
        <production>
            <Production>
                <xsl:apply-templates select="mix:GeneralCaptureInformation"/>
                <xsl:apply-templates select="mix:ScannerCapture"/>
            </Production>
        </production>
    </xsl:template>

    <xsl:template match="mix:GeneralCaptureInformation">
        <date>
            <xsl:value-of select="mix:dateTimeCreated"/>
        </date>
        <agent rdf:parseType="Resource">
            <name>
                <xsl:value-of select="mix:imageProducer"/>
            </name>
        </agent>
    </xsl:template>

    <xsl:template match="mix:ScannerCapture">
        <tool rdf:resource="{$terms}scanner/{str:encode-uri(mix:scannerManufacturer, true())}/{str:encode-uri(mix:ScannerModel/mix:scannerModelName, true())}">
        </tool>
        <xsl:for-each select="mix:ScanningSystemSoftware">
            <tool rdf:resource="{$terms}scanner/{str:encode-uri(mix:scanningSoftwareName, true())}/{str:encode-uri(mix:scanningSoftwareVersionNo, true())}">
            </tool>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
