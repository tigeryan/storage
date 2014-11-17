<cfapplication name="gCal">

<cfset calendar = "http://www.google.com/calendar/feeds/tigeryan55@gmail.com/private/full">
	
<cfif not structKeyExists(application, "gCal") or structKeyExists(url, "reinit")>
	<cfset application.gCal = createObject("component", "GoogleCalendar").init("tigeryan55","jcmc07241993",-5)>
</cfif>

<cfset cals = application.gCal.getCalendars()>
<cfdump var="#cals#" label="Calendars" expand="false">	



<cfquery name="GetListing" datasource="#request.dsn#">
	SELECT noticeid,county,	newspaper,	message_detail	,sale_date	,sale_time	,facility	,njpa_noticeid	,date_added	,archive	,date_printed
	FROM public_notices
	WHERE noticeid = #Val(URL.noticeid)#
</cfquery> 


<!--- CreateDateTime(year, month, day, hour, minute, second) --->

<cfset start_hour = ListGetAt(GetListing.sale_time,1,":")>
<cfset start_minute = ListGetAt(ListGetAt(GetListing.sale_time,1," "),2,":")>





<cfset title = "Storage Auction">
<cfset description = "#GetListing.message_detail#">
<cfset authorName = "John Ceci">
<cfset authorEmail = "tigeryan55@gmail.com">
<cfset where = "Storage Location">
<cfset startTime = createDateTime(DateFormat(GetListing.sale_date,'yyyy'), DateFormat(GetListing.sale_date,'mm'), DateFormat(GetListing.sale_date,'dd'), start_hour, start_minute, 0)>
<cfset endTime = createDateTime(DateFormat(GetListing.sale_date,'yyyy'), DateFormat(GetListing.sale_date,'mm'), DateFormat(GetListing.sale_date,'dd'), start_hour+1, start_minute, 0)>

<cfoutput>#start_hour# - #start_minute# - #startTime# - #endTime#</cfoutput>



<cfinvoke component="#application.gcal#" method="addEvent" returnVariable="result">
<cfinvokeargument name="title" value="#title#">
<cfinvokeargument name="description" value="#description#">
<cfinvokeargument name="authorname" value="#authorname#">
<cfinvokeargument name="authormemail" value="#authoremail#">
<cfinvokeargument name="where" value="#where#">
<cfinvokeargument name="start" value="#starttime#">
<cfinvokeargument name="end" value="#endtime#">
</cfinvoke>

<cflocation url="view_listings.cfm" />