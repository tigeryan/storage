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
		WHERE njpa_noticeid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.guid#-1" />
	</cfquery>

	<cfif CheckItem.recordcount EQ 0>
		<cfset Attributes.county = "" />
		<cfset Attributes.paper = "" />
		<cfset Attributes.published_date = "" />
		<cfset Attributes.sale_date = "" />
		<cfset Attributes.message_detail = "" />
	
		<!--- Grab Record / Insert new record---->
		
		
		<!---
		<cfhttp method="get" url="http://www.publicnoticeads.com/NJ/search/view.asp?T=PN&id=#Attributes.guid#"></cfhttp>
	
		<cffile action="write" file="#ExpandPath("./listing_#DateFormat(Now(),'yyyymmdd')#_#counter#.htm")#" output="#cfhttp.filecontent#">
		
		<cfset listing_html = cfhttp.filecontent />
		---->
		
		<cffile action="read" file="#ExpandPath("./listing_#DateFormat(Now(),'yyyymmdd')#_#counter#.htm")#" variable="listing_html" />
		
		<!--- <cffile action="read" file="#ExpandPath("./listing.htm")#" variable="listing_html" /> --->
		
		<cfset listing_html = Replace(listing_html,"#chr(13)##chr(10)#","","ALL") />
		<cfset listing_html = Replace(listing_html,"&##58;",":","ALL") />
		<cfset listing_html = Replace(listing_html,":00:00",":00","ALL") />
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
					<cfset dateArray[1] = "#dateString#, 2011" />
				</cfif>

				<cfif ArrayLen(dateArray) EQ 0>
					<cfset dateArray = reMatch('(#month_list#) [0-9]+',pubItem) />
					<cfif ArrayLen(dateArray) GT 0>
						THERE<br />
						<cfset dateString = dateArray[1] />
						<cfset dateArray[1] = "#dateString#, 2011" />
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

		<cfdump var="#Attributes#">	

		<cfset Attributes.message_detail = Replace(Attributes.message_detail,"�","","ALL") />
		
		<!--- <cfquery name="InsertListing" datasource="#request.dsn#">
			INSERT INTO public_notices(county,newspaper,message_detail,sale_date,njpa_noticeid)
			VALUES
			(
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.county#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.paper#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deMoronize(Attributes.message_detail)#">,				
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.sale_date#">,	
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attributes.guid#">
			)					
		</cfquery> --->
		


	</cfif>
	
	<cfset counter = counter + 1 />
	
</cfloop>

<cfquery name="GetListing" datasource="#request.dsn#">
	SELECT * 
	FROM public_notices
</cfquery> 
		
<cfdump var="#GetListing#">
