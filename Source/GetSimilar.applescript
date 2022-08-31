#!/usr/bin/osascript -l AppleScript

on run argv
	
	set query to argv as string
	
	set workflowFolder to do shell script "pwd"
	set wlib to load script POSIX file (workflowFolder & "/q_workflow.scpt")
	set wf to wlib's new_workflow()
	
	-- INITIALIZE THE ICONS and LINKS --
	set artistIcon to "artist.png"
	set lfmSimLink to (system attribute "lfm_similar_link")
	set apiKey to (system attribute "apiKey")
	
	tell application "System Events"
		
		set resultCount to 0
		set similarLimit to (system attribute "user_similar_limit")
		
		set queryString to query
		
		set queryStringEncode to wf's q_encode_url(queryString as string)
		set lfmSimLink to lfmSimLink & queryStringEncode & "&api_key=" & apiKey & "&limit=" & similarLimit
		set json to wf's request_json(lfmSimLink)
		set resultCount to count of artist of similarartists of json
		
		if resultCount is less than 1 then
			add_result of wf with isValid given theUid:"", theArg:"", theTitle:"No matches for: " & queryString, theAutocomplete:"", theSubtitle:"Check your spelling, or maybe you need less obscure taste in music.", theIcon:"", theType:"", theQuicklookurl:""
		else
			
			if resultCount is greater than similarLimit then
				set resultCount to similarLimit
			end if
			
			add_result of wf without isValid given theUid:"", theArg:"", theTitle:"Similar Artists for: " & queryString, theAutocomplete:"", theSubtitle:"Select below to open in your browser. Press Shift or Cmd+Y to view in Quicklook", theIcon:"", theType:"", theQuicklookurl:""
			
			set artistList to (artist of similarartists of json)
			repeat with i from 1 to similarLimit
				set thisResult to item i of artistList
				set thisName to |name| of thisResult
				set thisUrl to |url| of thisResult
				add_result of wf with isValid given theUid:"", theArg:thisUrl, theTitle:thisName, theAutocomplete:"", theSubtitle:"", theIcon:artistIcon, theType:"", theQuicklookurl:thisUrl
				
			end repeat
			
		end if
		
	end tell
	
	-- return XML data
	wf's to_xml("")
	
end run