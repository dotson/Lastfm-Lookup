#!/usr/bin/osascript -l AppleScript

on run argv
	
	set query to argv as string
	set nowPlayingQuery to ""
	
	set workflowFolder to do shell script "pwd"
	set wlib to load script POSIX file (workflowFolder & "/q_workflow.scpt")
	set wf to wlib's new_workflow()
	
	-- INITIALIZE THE ICONS and LINKS --
	set artistIcon to "artist.png"
	set lfmSearchLink to (system attribute "lfm_search_link")
	set apiKey to (system attribute "apiKey")
	
	set title to "Last.fm Similar Artist Look-Up"
	set subtitle to "Start typing to search for an artist"

	if length of query is less than 2 then
		-- check for currently playing artist in Music app
		if application "Music" is running then
			tell application "Music"
				if player state is playing then
					set thisSong to current track
					set nowPlayingQuery to (get artist of thisSong)
					set query to nowPlayingQuery
					set title to "Current Artist: " & query
					set subtitle to "Select below to explore similar artists in Alfred window."
				end if
			end tell
		end if
		add_result of wf without isValid given theUid:"", theArg:"", theTitle:title, theAutocomplete:"", theSubtitle:subtitle, theIcon:"", theType:"", theQuicklookurl:""
	end if
	
	if length of query is greater than 1 then
		tell application "System Events"
			
			set resultCount to 0
			
			set queryString to wf's q_encode_url(query as string)
			set lfmSearchLink to lfmSearchLink & queryString & "&api_key=" & apiKey
			set json to wf's request_json(lfmSearchLink)
			set results to results of json
			set itemsPerPage to |opensearch:itemsPerPage| of results as integer
			set totalResults to |opensearch:totalResults| of results as integer
			
			if totalResults is less than itemsPerPage then
				set resultCount to totalResults
			else
				set resultCount to itemsPerPage
			end if
			if query is nowPlayingQuery then set resultCount to 1
			
			if resultCount is less than 1 then
				add_result of wf with isValid given theUid:"", theArg:"", theTitle:"No matches for: " & query, theAutocomplete:"", theSubtitle:"Check your spelling, or maybe you need less obscure taste in music.", theIcon:"", theType:"", theQuicklookurl:""
			else
				
				set artistMatches to artistMatches of results
				set artistList to (artist of artistMatches)
				repeat with i from 1 to resultCount
					set thisResult to item i of artistList
					set thisName to |name| of thisResult
					set thisUrl to |url| of thisResult
					set thisListeners to (listeners of thisResult) as integer
					set thisListeners to do shell script "echo " & thisListeners & " | perl -lpe'1 while s/^([-+]?\\d+)(\\d{3})/$1,$2/'"
					
					add_result of wf with isValid given theUid:"", theArg:thisName, theTitle:thisName, theAutocomplete:thisName, theSubtitle:thisListeners & " Listeners", theIcon:artistIcon, theType:"", theQuicklookurl:thisUrl
					
				end repeat
			end if
		end tell
		
	end if
	
	-- return XML data
	wf's to_xml("")
	
end run