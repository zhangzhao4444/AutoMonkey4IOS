<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
		<html>
		<body leftmargin="20" rightmargin="20">
		
			<h1 >IOS MONKEY TEST SUMMARY</h1>
			<h3 >APPLICATION LEVEL</h3>
			<hr />
			<h3>ABSTRACT</h3>
			<table border="0" cellspacing="0">
			<tr bgcolor="#C9BBAD">
			</tr>
			<xsl:for-each select="items/sysitem">
				<xsl:choose>
					<xsl:when test="(position() mod 2) = 1">
					<tr bgcolor="#C9BBAD">
					<td>
						<xsl:value-of select="text" />
					</td>
					<td>
						<xsl:value-of select="link" />
					</td>
					</tr>
					</xsl:when>
					<xsl:otherwise>
						<tr bgcolor="#E3E1E8">
							<td>
								<xsl:value-of select="text" />
							</td>
							<td>
								<xsl:value-of select="link" />
							</td>
						</tr>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			</table>
			<br />
			<h3>RESULTS</h3>
			<table width="30%" border="-1">
			<xsl:for-each select="items/resultitem">
				<xsl:choose>
				<xsl:when test="position() = 1">
					<tr bgcolor="#76EFE1">
					<td width="50%">
						<xsl:value-of select="text" />
					</td>
					<td>
						<xsl:value-of select="No" />
					</td>
					</tr>
				</xsl:when>
				<xsl:when test="position() = 2">
					<tr bgcolor="#3BBF4D">
					<td width="50%">
						<xsl:value-of select="text" />
					</td>
					<td>
						<xsl:value-of select="No" />
					</td>
					</tr>
				</xsl:when>
				<xsl:when test="position() = 3">
					<tr bgcolor="#E47377">
					<td width="50%">
						<xsl:value-of select="text" />
					</td>
					<td>
						<xsl:value-of select="No" />
					</td>
					</tr>
				</xsl:when>
				<xsl:when test="position() = 4">
					<tr bgcolor="#AD9E9F">
					<td width="50%">
						<xsl:value-of select="text" />
					</td>
					<td>
						<xsl:value-of select="No" />
					</td>
					</tr>
				</xsl:when>
				<xsl:when test="position() = 5">
					<tr bgcolor="#EBD4A4">
					<td width="50%">
						<xsl:value-of select="text" />
					</td>
					<td>
						<xsl:value-of select="No" />
					</td>
					</tr>
				</xsl:when>
			</xsl:choose>
			</xsl:for-each>
			</table>
			<br />
			<h3>DETAILS</h3>
			<table width="100%" border="1" cellspacing="0">
				<tr bgcolor="#AAA4E0">
					<th>Package</th>
					<th>Version</th>
					<th>Test Duration</th>
					<th>Crash</th>
					<th>Total Error</th>
					<th>1st Error</th>
					<th>MTBF</th>
					<th>Result</th>
				</tr>
				<xsl:for-each select="items/appitem">
				<xsl:sort select="mg"/>
				<xsl:sort order="descending" select="tf"/>
				<xsl:choose>
					<xsl:when test="(position() mod 2) = 0">
						<tr bgcolor="#C9BBAD">
							<xsl:choose>
							<xsl:when test="mg = 'fail'">
							<td>
								<xsl:variable name="href"><xsl:value-of select="app"/></xsl:variable>
                                <a href="{$href}/"><xsl:value-of select="app"/></a>
							</td>
							</xsl:when>
							<xsl:otherwise>
							<td >
								<xsl:value-of select="app" />
							</td>
							</xsl:otherwise>
							</xsl:choose>
							<td>	
								<xsl:value-of select="version" />
							</td>
							<td align= "center">
								<xsl:value-of select="td" />
							</td>
							<td align= "center">
								<xsl:value-of select="fc" />
							</td>
							<td align= "center">
								<xsl:value-of select="tf" />
							</td>
							<td align= "center">
								<xsl:value-of select="firsterr" />
							</td>
							<td align= "center">
								<xsl:value-of select="mttf" />
							</td>
							<xsl:choose>
							<xsl:when test="mg = 'fail'">
							<td align= "center" bgcolor="#FA5858">
								<xsl:value-of select="mg" />
							</td>
							</xsl:when>
							<xsl:otherwise>
							<td align= "center" bgcolor="#3BBF4D">
								<xsl:value-of select="mg" />
							</td>
							</xsl:otherwise>
							</xsl:choose>
							<td align= "center">
								<a />
							</td>
						</tr>
					</xsl:when>
					<xsl:otherwise>
						<tr>
							<xsl:choose>
							<xsl:when test="mg = 'fail'">
							<td>
								<xsl:variable name="href"><xsl:value-of select="app"/></xsl:variable>
                                <a href="{$href}/"><xsl:value-of select="app"/></a>
							</td>
							</xsl:when>
							<xsl:otherwise>
							<td >
								<xsl:value-of select="app" />
							</td>
							</xsl:otherwise>
							</xsl:choose>
							<td>
								<xsl:value-of select="version" />
							</td>
							<td align= "center">
								<xsl:value-of select="td" />
							</td>
							<td align= "center">
								<xsl:value-of select="fc" />
							</td>
							<td align= "center">
								<xsl:value-of select="tf" />
							</td>
							<td align= "center">
								<xsl:value-of select="firsterr" />
							</td>
							<td align= "center">
								<xsl:value-of select="mttf" />
							</td>
							<xsl:choose>
							<xsl:when test="mg ='fail'">
							<td align= "center" bgcolor="#FA5858">
								<xsl:value-of select="mg" />
							</td>
							</xsl:when>
							<xsl:otherwise>
							<td align= "center" bgcolor="#3BBF4D">
								<xsl:value-of select="mg" />
							</td>
							</xsl:otherwise>
							</xsl:choose>
							<td align= "center">
								
							</td>
						</tr>
					</xsl:otherwise>
				</xsl:choose>
				</xsl:for-each>
			</table>
			
			<h3>FAILED REASON</h3>
			
			<table width="100%" border="1" cellspacing="0">
			  <tr bgcolor="#AAA4E0">
			    <th>PACKAGE</th>
			    <th>TOTAL FAILURES</th>
		            <th>DETAIL INFO</th>
			  </tr>
			  <xsl:for-each select="items/failreason">
			  	<xsl:variable name="package"><xsl:value-of select="app"/></xsl:variable>
			    <tr>
			      <td align="left" class="rowtitle">
                        <xsl:variable name="href"><xsl:value-of select="app"/></xsl:variable>
                        <a href="{$href}/"><xsl:value-of select="app"/></a>
                  </td>
			      <td align="center" width="5%">
                        <xsl:value-of select="tf" />
                  </td>
			      <td align="left">
                        <UL>
                            <xsl:for-each select="at">
                                <LI>
                                	<xsl:variable name="errorinfo"><xsl:value-of select="failure"/></xsl:variable>
                                	<a href="{$package}/{$errorinfo}"><xsl:value-of select="failure"/></a>
                                </LI>
                            </xsl:for-each>
                        </UL>
                  </td>
			    </tr>
            </xsl:for-each>
			</table>
		</body>
		</html>
</xsl:template>

</xsl:stylesheet>
