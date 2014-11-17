<cfif IsDefined("URL.action")>

	<cfif URL.action EQ "archive">
		
		<cfquery name="ArchiveListing" datasource="#request.dsn#">
			UPDATE public_notices
			SET archive = 1
			WHERE noticeid = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#URL.noticeid#" />
		</cfquery>
		
	</cfif>
	
</cfif>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Untitled</title>
</head>

<body>

<cfquery name="GetListing" datasource="#request.dsn#">
	SELECT noticeid,county,	newspaper,	message_detail	,sale_date	,sale_time	,facility	,njpa_noticeid	,date_added	,archive	,date_printed
	FROM public_notices
	WHERE sale_date > '#DateFormat(DateAdd('d',-4,Now()),'yyyy-mm-dd')#' and archive = 0
	ORDER BY sale_date
</cfquery> 
		
		
<table>
	<tr>
		<td>Sale Date</td>
		<td>Sale Time</td>
		<td>Sale Ad</td>
		<td>&nbsp;</td>
	</tr>
	<cfoutput query="GetListing">
	<tr <cfif (GetListing.currentrow mod 2) EQ 0>bgcolor="eeeeee"</cfif>>
		<td valign="top" width="100">#DateFormat(GetListing.sale_date,'dddd mm/dd/yyyy')#</td>
		<td valign="top" width="100">#GetListing.sale_time#</td>
		<td>#GetListing.message_detail#</td>
		<td valign="top" width="100">
			<a target="_new" href="http://www.publicnoticeads.com/NJ/search/view.asp?T=PN&id=#GetListing.njpa_noticeid#">view listing</a><br />
			
			<!--- <a href="http://www.google.com/calendar/event?action=TEMPLATE&text=Auction&dates=#DateFormat(GetListing.sale_date,'yyyymmdd')#T000000Z/#DateFormat(GetListing.sale_date,'yyyymmdd')#T050000Z&details=#HtmlEditFormat("http://www.publicnoticeads.com/NJ/search/view.asp?T=PN&id=#GetListing.njpa_noticeid#")#&location=Auction&trp=false&sprop=&sprop=name:" target="_blank"><img src="http://www.google.com/calendar/images/ext/gc_button1.gif" border=0></a><br /> --->
			<a href="addtocalendar.cfm?noticeid=#GetListing.noticeid#">Add to Google Calendar</a><br />			
			<a href="view_listings.cfm?noticeid=#GetListing.noticeid#&action=archive">archive</a>			
		</td>
	</tr>	
	</cfoutput>
</table>
<!--- <cfdump var="#GetListing#"> --->


</body>
</html>
