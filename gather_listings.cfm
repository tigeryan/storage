<!---<cfquery name="GetListing" datasource="#request.dsn#">
	DELETE 
	FROM public_notices
</cfquery>  

44-187

<cfabort>--->

<cfhttp method="POST" url="http://www.publicnoticeads.com/NJ/search/results.asp?T=PN">
	<cfhttpparam type="FORMFIELD" name="lstcounties" value="Atlantic,Burlington,Camden,Cumberland,Gloucester" />
	<cfhttpparam type="FORMFIELD" name="LSTPUBLICATIONS" value="All" />
	<cfhttpparam type="FORMFIELD" name="SELECTNUMNOTICES" value="250" />
	<cfhttpparam type="FORMFIELD" name="TXTDATEFROM" value="" />
	<cfhttpparam type="FORMFIELD" name="TXTDATETO" value="" />
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSAND" value="Self Storage Facility Act" />
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSEXACT" value="" />
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSNOT" value="" />					
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSOR" value="" />
</cfhttp>

<cffile action="write" file="#ExpandPath("./pn.htm")#" output="#cfhttp.filecontent#">

<cfset html = cfhttp.filecontent /> 

<cffile action="read" file="#ExpandPath("./pn.htm")#" variable="html" />

<cfset month_list ="January|February|March|April|May|June|July|August|September|October|November|December" />

<cfset linkArray = reMatch("'view.*?'",html) />

<cfset counter = 1 />

<cfloop array="#linkArray#" index="myItem">

	<cfset myItem = Replace(myItem,"'","","ALL") />

	<cfset Attributes.guid = ListGetAt(myItem,3,"=") />
	
	<cfoutput>#Attributes.guid#<br /></cfoutput>
	
	<cfquery name="CheckItem" datasource="#request.dsn#">
		SELECT noticeid
		FROM public_notices
		WHERE njpa_noticeid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.guid#" />
	</cfquery>

	<cfif CheckItem.recordcount EQ 0>
		<cfset Attributes.county = "" />
		<cfset Attributes.paper = "" />
		<cfset Attributes.published_date = "" />
		<cfset Attributes.sale_date = "" />
		<cfset Attributes.message_detail = "" />
	
		<!--- Grab Record / Insert new record---->
		
		
		<cfhttp method="get" url="http://www.publicnoticeads.com/NJ/search/view.asp?T=PN&id=#Attributes.guid#"></cfhttp>
	
		<cfset write_html = Replace(cfhttp.filecontent,"&##47;","/","ALL") />
	
		<cffile action="write" file="#ExpandPath("./listing_cache/listing_#DateFormat(Now(),'yyyymmdd')#_#counter#.htm")#" output="#write_html#">
	
		<cfset listing_html = cfhttp.filecontent />

		
		<!--- <cffile action="read" file="#ExpandPath("./listing.htm")#" variable="listing_html" /> --->
		
		<cfset listing_html = Replace(listing_html,"#chr(13)##chr(10)#","","ALL") />
		<cfset listing_html = Replace(listing_html,"&##58;",":","ALL") />
		<cfset listing_html = Replace(listing_html,":00:00",":00","ALL") />
		<cfset listing_html = Replace(listing_html,"&##47;","/","ALL") />
		<cfset listing_html = ReplaceNoCase(listing_html,"o'clock ","","ALL") />
		<cfset listing_html = ReplaceNoCase(listing_html,"a.m.","am","ALL") />
		<cfset listing_html = ReplaceNoCase(listing_html,"p.m.","pm","ALL") />
		<cfset listing_html = ReplaceNoCase(listing_html,"day ","","ALL") />		
		
		<cfset pubArray = reMatch('<[dD][iI][vV].*?>.*?</[dD][iI][vV]>',listing_html) />

		<cfdump var="#pubArray#">
		
		<cfloop array="#pubArray#" index="myPub">
		
			<cfset pubItem = myPub />
			
			<!--- <cfoutput>#pubItem#<br /></cfoutput> --->
			
			<cfif FindNoCase('id="publicationInfo"',pubItem)>
				<cfset pubInfoArray = reMatch('</b>.*?</font>',pubItem) />
				
				<cfloop index="x" from="1" to="#ArrayLen(pubInfoArray)#">
					<cfset pubInfoItem = reReplace(pubInfoArray[x],"<.*?>","","ALL") />
					<cfif x EQ 1>
						<cfset Attributes.county = pubInfoItem />
					<cfelseif x EQ 2>
						<cfset Attributes.paper = pubInfoItem />					
					<cfelseif x EQ 3>
						<cfset Attributes.published_date = pubInfoItem />					
					</cfif>
				</cfloop>

			<cfelseif FindNoCase('id="NoticeText"',pubItem)>
				<!--- date formats
					19th of July 
					July 7, 2011
					June 25, 2011
					28th day of June 2011 
				--->
				<cfset dateArray = reMatch('[0-9]{1,2}(rd|st|th|nd) of (#month_list#)',pubItem) />

				<cfif ArrayLen(dateArray) GT 0>
					<cfset dateString = dateArray[1] />
					<cfset dateString = REReplaceNoCase(dateString,"[rdsth]{2} of","","ALL") />
					<cfset dateString = "#ListGetAt(dateString,2," ")# #ListGetAt(dateString,1," ")#" />
					<cfset dateArray[1] = "#dateString#, 2014" />
				</cfif>

				<cfif ArrayLen(dateArray) EQ 0>
					<cfset dateArray = reMatch('(#month_list#) [0-9]+',pubItem) />
					<cfif ArrayLen(dateArray) GT 0>
						THERE<br />
						<cfset dateString = dateArray[1] />
						<cfset dateArray[1] = "#dateString#, 2014" />
					</cfif>					
				</cfif>

				<cfif ArrayLen(dateArray) EQ 0>
					<cfset dateArray = reMatch('[0-9]{1,2}[dhnrst]{2} of [A-Z]{1}[a-z]+, [0-9]{4}',pubItem) />
					everywHERE<br />
				</cfif>
				<!--- ([0-9]{1,2}[dhnrst]{2} of [A-Z]{1}[a-z]+, [0-9]{4}) --->
				
				
				<cfdump var="#dateArray#">
				
				<cfif ArrayLen(dateArray) GT 0>
					<cfset Attributes.sale_date = dateArray[1] />
				</cfif>
				
				<cfset Attributes.saleArray = reMatch('[0-9]{1,2}:[0-9]{2} [ampAMP]{2}',pubItem) />
				
				
				<cfif ArrayLen(Attributes.saleArray)>
					<cfset Attributes.sale_time = Attributes.saleArray[1] />
				<cfelse>
					<cfset Attributes.saleArray = reMatch('[0-9]{1,2}:[0-9]{2} o''clock [ap]{1}.m.',pubItem) />
					<cfif ArrayLen(Attributes.saleArray)>
						<cfset Attributes.sale_time = Attributes.saleArray[1] />
					<cfelse>
						<cfset Attributes.sale_time = "" />
					</cfif>
				</cfif>
				
				<cfset Attributes.message_detail = pubItem />
			
			<cfelseif FindNoCase('Public Notice ID: ',pubItem)>
			
			</cfif>
			
		
		</cfloop>

		<cfset Attributes.sale_date = Replace(Attributes.sale_date,",","") />

		<cfset Attributes.sale_date = "#ListFind(month_list,ListGetAt(Attributes.sale_date,1," "),"|")#/#ListGetAt(Attributes.sale_date,2," ")#/#ListGetAt(Attributes.sale_date,3," ")#" />

		<cfset Attributes.sale_date = DateFormat(Attributes.sale_date,"yyyy-mm-dd") />
		
		<cfset Attributes.message_detail = Replace(Attributes.message_detail,"�","","ALL") />
		
		<cfdump var="#attributes#">
		
		<!--- <cfoutput>#listing_html#</cfoutput> --->

		<cfquery name="CheckItem" datasource="#request.dsn#">
			SELECT noticeid
			FROM public_notices
			WHERE message_detail = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deMoronize(Attributes.message_detail)#">
		</cfquery>		
		
		<cfif CheckItem.recordcount EQ 0>		
			<cfquery name="InsertListing" datasource="#request.dsn#">
				INSERT INTO public_notices(county,newspaper,message_detail,sale_date,sale_time,njpa_noticeid,date_printed)
				VALUES
				(
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.county#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.paper#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deMoronize(Attributes.message_detail)#">,				
					'#Attributes.sale_date#',	
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.sale_time#">,					
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.guid#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.published_date#">				
				)					
			</cfquery>
		</cfif>


		
	</cfif>
	
	<cfset counter = counter + 1 />
	
	<cfsleep time="1000">
	
</cfloop>

<!--- 
<cfquery name="GetListing" datasource="#request.dsn#">
	SELECT * 
	FROM public_notices
</cfquery> 
		
<cfdump var="#GetListing#"> --->


<cfabort>


 




<!--- <cfif IsDefined("form")>
<cfdump var="#form#">
</cfif>
 --->



<!--- <cfhttp method="POST" url="http://www.publicnoticeads.com/NJ/search/results.asp?T=PN">
	<cfhttpparam type="FORMFIELD" name="lstcounties" value="Atlantic,Burlington,Camden,Cumberland,Gloucester" />
	<cfhttpparam type="FORMFIELD" name="LSTPUBLICATIONS" value="All" />
	<cfhttpparam type="FORMFIELD" name="SELECTNUMNOTICES" value="250" />
	<cfhttpparam type="FORMFIELD" name="TXTDATEFROM" value="" />
	<cfhttpparam type="FORMFIELD" name="TXTDATETO" value="" />
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSAND" value="Self Storage Facility Act" />
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSEXACT" value="" />
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSNOT" value="" />					
	<cfhttpparam type="FORMFIELD" name="TXTSEARCHWORDSOR" value="" />
</cfhttp> 

<cffile action="write" file="#ExpandPath("./pn.htm")#" output="#cfhttp.filecontent#">

<cfset html = cfhttp.filecontent /> --->


<cffile action="read" file="#ExpandPath("./pn.htm")#" variable="html" />

<!--- <cfoutput>#cfhttp.filecontent#</cfoutput> --->


<cfset start = FindNoCase('<table border="0" cellPadding="1" cellSpacing="2" width=100%>',html) />
<cfset end = FindNoCase('</table>',html,start) />

<cfset content = Mid(html,start,end-start+8) />

<!--- <cfoutput>#content#</cfoutput> --->

<cfset link_list = hrefsToList(content) />

<!--- <cfoutput>#link_list#</cfoutput>  --->

<cfloop index="x" from="1" to="#ListLen(link_list)#">
	<cfset link = ListGetAt(link_list,x) />
	<cfoutput>#link#<br /></cfoutput>
</cfloop>

http://www.publicnoticeads.com/NJ/search

<!--- <cfquery name="GetListing" datasource="cfwheels">
	SELECT * 
	FROM public_notices
</cfquery> 

<cfdump var="#GetListing#">

--->

<!---
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Untitled</title>
</head>

<body>

<form name="frm" method="post" action="public_notice.cfm">
<center>
<font face="verdana" size=3><strong>Search Public Notices in New Jersey Newspapers</strong></font>
			<table bgcolor="#dcdcdc" border=0 cellpadding=0 cellspacing=2 width=100%>
				<tr bgcolor="#990000">
					<td colspan=4><font face="verdana" size=3 color="#ffffff"><b>County/Publication</b></font></td>
				</tr>
				<tr>
					<td align=right valign="top"><font face="verdana" size=2 color="#000000"><b>County/Parish:</b><br>(Hold Ctl Key to select multiple.)</font>&nbsp;</td>

					<td colspan=3><select name="lstCounties" size=4 multiple><option value="All">All Counties/Parishes</option><option value="Atlantic">Atlantic</option><option value="Bergen">Bergen</option><option value="Burlington">Burlington</option><option value="Camden">Camden</option><option value="Cape May">Cape May</option><option value="Cumberland">Cumberland</option><option value="Essex">Essex</option><option value="Gloucester">Gloucester</option><option value="Hudson">Hudson</option><option value="Hunterdon">Hunterdon</option><option value="Mercer">Mercer</option><option value="Middlesex">Middlesex</option><option value="Monmouth">Monmouth</option><option value="Morris">Morris</option><option value="Ocean">Ocean</option><option value="Passaic">Passaic</option><option value="Salem">Salem</option><option value="Somerset">Somerset</option><option value="Sussex">Sussex</option><option value="Union">Union</option><option value="Warren">Warren</option></select></td>

				</tr>
				<tr>
					<td align=right><font face="verdana" size=2 color="#000000"><b>Publication:</b></font>&nbsp;</td>
					<td colspan=3><select name="lstPublications" size=1><option selected value="All">All Newspapers</option><option value="Aim Community News, Newfoundland">Aim Community News, Newfoundland</option><option value="Asbury Park Press, Neptune">Asbury Park Press, Neptune</option><option value="Atlantic County Record, Mays Landing">Atlantic County Record, Mays Landing</option><option value="Atom Tabloid & Citizen-Gazette, Edison">Atom Tabloid & Citizen-Gazette, Edison</option><option value="Beach Haven Times, Manahawkin">Beach Haven Times, Manahawkin</option><option value="Beacon, Lambertville">Beacon, Lambertville</option><option value="Beacon, Manahawkin">Beacon, Manahawkin</option><option value="Belleville Post">Belleville Post</option><option value="Belleville Times, Nutley">Belleville Times, Nutley</option><option value="Bernardsville News, Bernardsville">Bernardsville News, Bernardsville</option><option value="Bloomfield Life, Nutley">Bloomfield Life, Nutley</option><option value="Bound Brook Spectator">Bound Brook Spectator</option><option value="Bridgeton News, Bridgeton">Bridgeton News, Bridgeton</option><option value="Burlington County Times, Willingboro">Burlington County Times, Willingboro</option><option value="Cape May County Herald Times">Cape May County Herald Times</option><option value="Cape May Star & Wave, Cape May">Cape May Star & Wave, Cape May</option><option value="Central Record, Medford">Central Record, Medford</option><option value="Chatham Courier, Chatham">Chatham Courier, Chatham</option><option value="Citizen of Morris County, Denville">Citizen of Morris County, Denville</option><option value="Coast Star, Manasquan">Coast Star, Manasquan</option><option value="Coaster, Asbury Park">Coaster, Asbury Park</option><option value="Community News, Browns Mills">Community News, Browns Mills</option><option value="Courier News, Bridgewater">Courier News, Bridgewater</option><option value="Courier-Post, Cherry Hill">Courier-Post, Cherry Hill</option><option value="Cranbury Press, Cranbury">Cranbury Press, Cranbury</option><option value="Cranford Chronicle, Cranford">Cranford Chronicle, Cranford</option><option value="Daily Journal, Vineland">Daily Journal, Vineland</option><option value="Daily Record, Parsippany">Daily Record, Parsippany</option><option value="Dateline Journal">Dateline Journal</option><option value="Delaware Valley News, Frenchtown">Delaware Valley News, Frenchtown</option><option value="Eagle, Clark and Cranford">Eagle, Clark and Cranford</option><option value="East Orange Record">East Orange Record</option><option value="Echo Leader, Mountainside and Springfield">Echo Leader, Mountainside and Springfield</option><option value="Echoes-Sentinel, Warren">Echoes-Sentinel, Warren</option><option value="Egg Harbor News, Mays Landing">Egg Harbor News, Mays Landing</option><option value="Elizabeth Reporter">Elizabeth Reporter</option><option value="Florham Park Eagle, Florham">Florham Park Eagle, Florham</option><option value="Franklin Township Sentinel, Franklinville">Franklin Township Sentinel, Franklinville</option><option value="Gazette Leader of Hillside and Elizabeth">Gazette Leader of Hillside and Elizabeth</option><option value="Glen Ridge Paper">Glen Ridge Paper</option><option value="Glen Ridge Voice, Nutley">Glen Ridge Voice, Nutley</option><option value="Gloucester County Times, Woodbury">Gloucester County Times, Woodbury</option><option value="Haddon Herald, Haddonfield">Haddon Herald, Haddonfield</option><option value="Hammonton News, Hammonton">Hammonton News, Hammonton</option><option value="Hanover Eagle & Regional Weekly News">Hanover Eagle & Regional Weekly News</option><option value="Herald News, West Paterson">Herald News, West Paterson</option><option value="Hillsborough Beacon">Hillsborough Beacon</option><option value="Home News Tribune, East Brunswick">Home News Tribune, East Brunswick</option><option value="Hopewell Valley News, Hopewell">Hopewell Valley News, Hopewell</option><option value="Hunterdon County Democrat, Flemington">Hunterdon County Democrat, Flemington</option><option value="Hunterdon Review, Clinton">Hunterdon Review, Clinton</option><option value="Independent Press of Bloomfield">Independent Press of Bloomfield</option><option value="Irvington Herald">Irvington Herald</option><option value="Jersey Journal, Jersey City">Jersey Journal, Jersey City</option><option value="Lacey Beacon, Manahawkin">Lacey Beacon, Manahawkin</option><option value="Lawrence Ledger, Lawrenceville">Lawrence Ledger, Lawrenceville</option><option value="Leader, Kenilworth">Leader, Kenilworth</option><option value="Madison Eagle, Madison">Madison Eagle, Madison</option><option value="Mainland Journal, Pleasantville">Mainland Journal, Pleasantville</option><option value="Manville News">Manville News</option><option value="Maple Shade Progress">Maple Shade Progress</option><option value="Medford Central Record">Medford Central Record</option><option value="Messenger Press, Allentown">Messenger Press, Allentown</option><option value="Morris Newsbee, Morris Plains">Morris Newsbee, Morris Plains</option><option value="Mount Olive Chronicle, Budd Lake">Mount Olive Chronicle, Budd Lake</option><option value="New Egypt Press, New Egypt">New Egypt Press, New Egypt</option><option value="New Jersey Herald, Newton">New Jersey Herald, Newton</option><option value="New Jersey Jewish News, Whippany">New Jersey Jewish News, Whippany</option><option value="New Jersey Law Journal, Newark">New Jersey Law Journal, Newark</option><option value="News Record/Patriot, Elizabeth">News Record/Patriot, Elizabeth</option><option value="News Report, Turnersville">News Report, Turnersville</option><option value="News Weekly, Moorestown">News Weekly, Moorestown</option><option value="News-Record">News-Record</option><option value="Nutley Journal">Nutley Journal</option><option value="Observer, Hasbrouck Heights">Observer, Hasbrouck Heights</option><option value="Observer, Mountainside, Springfield and Summit">Observer, Mountainside, Springfield and Summit</option><option value="Observer-Tribune, Chester">Observer-Tribune, Chester</option><option value="Ocean City Sentinel">Ocean City Sentinel</option><option value="Ocean Star, Point Pleasant Beach">Ocean Star, Point Pleasant Beach</option><option value="Orange Transcript">Orange Transcript</option><option value="Pennington Post, Pennington">Pennington Post, Pennington</option><option value="Plain Dealer, Turnersville">Plain Dealer, Turnersville</option><option value="Press Journal, Palisades Park">Press Journal, Palisades Park</option><option value="Princeton Packet, Princeton">Princeton Packet, Princeton</option><option value="Progress, Caldwell">Progress, Caldwell</option><option value="Progress, Union">Progress, Union</option><option value="Rahway Progress, Rahway">Rahway Progress, Rahway</option><option value="Randolph Reporter, Mount Freedom">Randolph Reporter, Mount Freedom</option><option value="Record Breeze, Turnersville">Record Breeze, Turnersville</option><option value="Record Press, Westfield">Record Press, Westfield</option><option value="Register News, Bordentown">Register News, Bordentown</option><option value="Retrospect, Collingswood">Retrospect, Collingswood</option><option value="Roxbury Register, Budd Lake">Roxbury Register, Budd Lake</option><option value="Sentinel, East Brunswick">Sentinel, East Brunswick</option><option value="Sentinel, Edison and Metuchen">Sentinel, Edison and Metuchen</option><option value="Sentinel, North and South Brunswick">Sentinel, North and South Brunswick</option><option value="Sentinel, Woodbridge">Sentinel, Woodbridge</option><option value="South Brunswick Post, Dayton">South Brunswick Post, Dayton</option><option value="Spectator Leader, Roselle and Linden">Spectator Leader, Roselle and Linden</option><option value="Star-Gazette, Hackettstown">Star-Gazette, Hackettstown</option><option value="Suburban Trends, Kinnellon">Suburban Trends, Kinnellon</option><option value="Suburban, Old Bridge">Suburban, Old Bridge</option><option value="Summit Observer, Summit">Summit Observer, Summit</option><option value="Sun Bulletin, Palisades Park">Sun Bulletin, Palisades Park</option><option value="The Chronicle">The Chronicle</option><option value="The Item of Millburn and Short Hills, Millburn">The Item of Millburn and Short Hills, Millburn</option><option value="The Montclair Times, Montclair">The Montclair Times, Montclair</option><option value="The Nutley Sun, Nutley">The Nutley Sun, Nutley</option><option value="The Press of Atlantic City, Pleasantville">The Press of Atlantic City, Pleasantville</option><option value="The Record, Hackensack">The Record, Hackensack</option><option value="The Ridgewood News, Ridgewood">The Ridgewood News, Ridgewood</option><option value="The Star-Ledger, Newark">The Star-Ledger, Newark</option><option value="The Times, Trenton">The Times, Trenton</option><option value="The Trentonian, Trenton">The Trentonian, Trenton</option><option value="Times at the Jersey Shore, Ocean Grove">Times at the Jersey Shore, Ocean Grove</option><option value="Times of Scotch Plains/Fanwood">Times of Scotch Plains/Fanwood</option><option value="Today Newspapers, West Paterson">Today Newspapers, West Paterson</option><option value="Today�s Sunbeam, Salem">Today�s Sunbeam, Salem</option><option value="Tri-Town News, Jackson">Tri-Town News, Jackson</option><option value="Tuckerton Beacon, Manahawkin">Tuckerton Beacon, Manahawkin</option><option value="Two River Times, Red Bank">Two River Times, Red Bank</option><option value="Union Leader">Union Leader</option><option value="Vailsburg Leader">Vailsburg Leader</option><option value="Verona/Cedar Grove Times, Cedar Grove">Verona/Cedar Grove Times, Cedar Grove</option><option value="West Essex Tribune, Livingston">West Essex Tribune, Livingston</option><option value="West Orange Chronicle">West Orange Chronicle</option><option value="Westfield Leader, Westfield">Westfield Leader, Westfield</option><option value="Wildwood Leader">Wildwood Leader</option><option value="Windsor-Hights Herald, Hightstown">Windsor-Hights Herald, Hightstown</option></select></td>

				</tr>
				
				
				
				<tr bgcolor="#dcdcdc">
					<td colspan=4><img src="http://www.publicnoticeads.com/NJ/images/pixel.gif" width=1 height=1 border=0></td>
				</tr>
				<tr bgcolor="#990000">
					<td colspan=4><font face="verdana" size=3 color="#ffffff"><b>Search Notices</b></font></td>
				</tr>
				<tr>

					<td align=right nowrap valign="top"><font face="verdana" size=2 color="#000000"><b>Search Notices:</b></font>&nbsp;</td>
					<td valign="top"><a href="javascript:LaunchTutorialWindow();"><font face="Verdana" size="1"><b>View Search Tutorial</b></font></a></td>
				</tr>
				<tr>
					<td align=right nowrap valign="top"><font face="verdana" size=2 color="#000000">With <b>all</b> these words:</font>&nbsp;</td>
					<td valign="top"><input type="text" name="txtSearchWordsAnd" value="" size=25></td>

				</tr>
				<tr>
					<td align=right nowrap valign="top"><font face="verdana" size=2 color="#000000">With this <b>exact</b> phrase:</font>&nbsp;</td>
					<td valign="top"><input type="text" name="txtSearchWordsExact" value="" size=25></td>
				</tr>
				<tr>
					<td align=right nowrap valign="top"><font face="verdana" size=2 color="#000000">With <b>at least one</b> of these words:</font>&nbsp;</td>

					<td valign="top"><input type="text" name="txtSearchWordsOr" value="" size=25></td>
				</tr>
				<tr>
					<td align=right nowrap valign="top"><font face="verdana" size=2 color="#000000">Exclude notices with these <b>words</b>:</font>&nbsp;</td>
					<td valign="top"><input type="text" name="txtSearchWordsNot" value="" size=25></td>
				</tr>
				<tr>

					<td align=right nowrap valign="top"><font face="verdana" size=2 color="#000000">Number of Notices to Return:</font>&nbsp;</td>
					<td valign="top">
					    <select id="selectNumNotices" name="selectNumNotices" style="font-size:12">
		                    <option value="250">250</option>
		                    <option value="1000">1000</option>
		                    <option value="2000">2000</option>
		                </select>

					</td>
				</tr>
				
				<tr>
					<td align=right valign="top"><font face="verdana" size=2 color="#000000"><b>Date Range</b>:</font>&nbsp;</td>
					<td valign="bottom"><font face="verdana" size=2 color="#000000">From</font> <input type="text" name="txtDateFrom" value="" size=8> <font face="verdana" size=2 color="#000000">to</font> <input type="text" name="txtDateTo" value="" size=8> <font face="verdana" size=2 color="#000000">(mm/dd/yy)</font></td>

				</tr>
				<tr>
					<td></td>
					<td valign="bottom"><font face="verdana" size=2 color="#000000"><a href=http://archive.publicnoticeads.com/NJ/search/searchnotices.asp>Click Here to search Notices older than March 28</a></td>
				</tr>
				
				<tr bgcolor="#dcdcdc">
					<td colspan=4><img src="http://www.publicnoticeads.com/NJ/images/pixel.gif" width=1 height=1 border=0></td>
				</tr>

				<tr bgcolor="#dcdcdc">
					<td align="center" colspan=4>
					<!--<input type="submit" value="Search" name="cmdSearch">&nbsp;<input type=reset name="reset">-->
					<!--<a href="javascript:SubmitForm()" ONMOUSEOVER="changeImages('SearchRollOver', 'http://www.publicnoticeads.com/NJ/images/GoRollOver_01-over.gif'); return true;" ONMOUSEOUT="changeImages('SearchRollOver', 'http://www.publicnoticeads.com/NJ/images/GoRollOver_01.gif'); return true;"><img NAME="SearchRollOver" SRC="http://www.publicnoticeads.com/NJ/images/GoRollOver_01.gif" WIDTH="32" HEIGHT="32" BORDER="0"></a>-->
					<a href="javascript:SubmitForm()"><img NAME="SearchRollOver" SRC="http://www.publicnoticeads.com/NJ/images/GoRollOver_01.gif" WIDTH="32" HEIGHT="32" BORDER="0"></a>
					   <input type="submit" value="go" />
					</td>
				</tr>	
			</table>

</center>

</form>


</body>
</html>
--->