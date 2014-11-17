<!-- nothing to see here -->
<cfset request.dsn = "sixfoottiger" />


<cfscript>
/**
 * Fixes text using Microsoft Latin-1 &quot;Extentions&quot;, namely ASCII characters 128-160.
 * ASCII8217 mod by Tony Brandner
 * 
 * @param text      Text to be modified. (Required)
 * @return Returns a string. 
 * @author Shawn Porter (sporter@rit.net) 
 * @version 2, September 2, 2010 
 */
function deMoronize (text) {
    var i = 0;

// map incompatible non-ISO characters into plausible 
    // substitutes
    text = Replace(text, Chr(128), "&euro;", "All");

    text = Replace(text, Chr(130), ",", "All");
    text = Replace(text, Chr(131), "<em>f</em>", "All");
    text = Replace(text, Chr(132), ",,", "All");
    text = Replace(text, Chr(133), "...", "All");
        
    text = Replace(text, Chr(136), "^", "All");

    text = Replace(text, Chr(139), ")", "All");
    text = Replace(text, Chr(140), "Oe", "All");

    text = Replace(text, Chr(145), "`", "All");
    text = Replace(text, Chr(146), "'", "All");
    text = Replace(text, Chr(147), """", "All");
    text = Replace(text, Chr(148), """", "All");
    text = Replace(text, Chr(149), "*", "All");
    text = Replace(text, Chr(150), "-", "All");
    text = Replace(text, Chr(151), "--", "All");
    text = Replace(text, Chr(152), "~", "All");
    text = Replace(text, Chr(153), "&trade;", "All");

    text = Replace(text, Chr(155), ")", "All");
    text = Replace(text, Chr(156), "oe", "All");

    // remove any remaining ASCII 128-159 characters
    for (i = 128; i LTE 159; i = i + 1)
        text = Replace(text, Chr(i), "", "All");

    // map Latin-1 supplemental characters into
    // their &name; encoded substitutes
    text = Replace(text, Chr(160), "&nbsp;", "All");

    text = Replace(text, Chr(163), "&pound;", "All");

    text = Replace(text, Chr(169), "&copy;", "All");

    text = Replace(text, Chr(176), "&deg;", "All");

    // encode ASCII 160-255 using ? format
    for (i = 160; i LTE 255; i = i + 1)
        text = REReplace(text, "(#Chr(i)#)", "&###i#;", "All");

    for (i = 8216; i LTE 8218; i = i + 1) text = Replace(text, Chr(i), "'", "All");
      
// supply missing semicolon at end of numeric entities
    text = ReReplace(text, "&##([0-2][[:digit:]]{2})([^;])", "&##\1;\2", "All");
    
// fix obscure numeric rendering of &lt; &gt; &amp;
    text = ReReplace(text, "&##038;", "&amp;", "All");
    text = ReReplace(text, "&##060;", "&lt;", "All");
    text = ReReplace(text, "&##062;", "&gt;", "All");

    // supply missing semicolon at the end of &amp; &quot;
    text = ReReplace(text, "&amp(^;)", "&amp;\1", "All");
    text = ReReplace(text, "&quot(^;)", "&quot;\1", "All");

    return text;
}
</cfscript>

<cfscript>
/**
 * Extracts all links from a given string and puts them into a list.
 * 
 * @param inputString      String to parse. (Required)
 * @param delimiter      Delimiter for returned list. Defaults to a comma. (Optional)
 * @return Returns a list. 
 * @author Marcus Raphelt (cfml@raphelt.de) 
 * @version 1, February 22, 2006 
 */
function hrefsToList(inputString) {
    var pos=1;
    var tmp=0;
    var linklist = "";
    var delimiter = ",";
    var endpos = "";
    
    if(arrayLen(arguments) gte 2) delimiter = arguments[2];
        
    while(1) {
        tmp = reFindNoCase("<a[^>]*>[^>]*</a>", inputString, pos);
        if(tmp) {
            pos = tmp;
            endpos = findNoCase("</a>", inputString, pos)+4;
            linkList = listAppend(linkList, mid(inputString, pos, endpos-pos), delimiter);
            pos = endpos;
        }
        else break;
    }

    return linkList;
}
</cfscript>