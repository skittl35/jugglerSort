<!--- ####################################################################################################
##########################################################################################################
The Process:
	1. Read the provided text file, putting circuits and jugglers into their own arrays.
	2. Loop through the juggler array starting from the top.  Check their preferences in 
	order 1st to last, attempt to assign them to said preference.  Most often, this will 
	take the user on one of three possible paths:
		Path A: No jugglers have yet to be assigned to this circuit, assign juggler and break from loop
		Path B: Jugglers have been assigned, assign current juggler to this circuit, placing them 
		in order of how well they match as compared to those already assigned.
		Path C: The circuit is already full.  This will in turn lead to two possible scenarios:
			Scenario A: The juggler isn't as well qualified as those already assigned, move on
			to their next preference.
			Scenario B: The juggler is better qualified than at least one juggler that is already assigned.
			Current juggler will be assigned to the circuit, displacing the worst juggler already assigned.
			Process will need to be repeated (start on step 2) to ensure all jugglers get assigned.
	3. In some cases, some jugglers are so bad a juggling they aren't better qualified than any other
	juggler already assigned to their preferences.  They get placed into the "poor jugglers" array,
	then get assigned to the remaining circuits based on merit (DP).
	4. With all jugglers assigned, construct the .txt file to be exported.
##########################################################################################################
######################################################################################################--->
<cfset resetVars = 1>
<cfset circuitPos = 1>
<cfset jugglerPos = 1>

<cfset circuitArray = ArrayNew(2)>
<cfset jugglerArray = ArrayNew(2)>
<cfset assignmentArray = ArrayNew(2)>
<cfset poorJugglerArray = ArrayNew(1)>
<cfset poorJugglerIndex = 1>

<!--- Extract values from the txt file --->
<cfloop file="E:\Inetpub\virtualwwwroot\CapturePointIntranet\jugglerSort\juggleFest.txt" index="currentLine">
    <cfif currentLine NEQ "">
	    <!--- Store the h/e/p values for the circuit or juggler being processed --->
	    <cfset hVal = #listGetAt(currentLine, 3, ' ')#>
		<cfset eVal = #listGetAt(currentLine, 4, ' ')#>
		<cfset pVal = #listGetAt(currentLine, 5, ' ')#>
		
		<!--- Determine whether a circuit or a juggler is being processed --->
	    <cfif #left(currentLine, 1)# EQ "C">
			<!--- Store a circuit's qualifying levels (integer only) --->
	    	<cfset circuitArray[#circuitPos#][1] = #removeChars(hVal, 1, 2)#>
	    	<cfset circuitArray[#circuitPos#][2] = #removeChars(eVal, 1, 2)#>
	    	<cfset circuitArray[#circuitPos#][3] = #removeChars(pVal, 1, 2)#>

	    	<cfset circuitPos += 1>
	    <cfelseif #left(currentLine, 1)# EQ "J">
			<!--- Store the juggler's qualifications (integer only) --->
	    	<cfset jugglerArray[#jugglerPos#][1] = #removeChars(hVal, 1, 2)#>
	    	<cfset jugglerArray[#jugglerPos#][2] = #removeChars(eVal, 1, 2)#>
	    	<cfset jugglerArray[#jugglerPos#][3] = #removeChars(pVal, 1, 2)#>

	    	<!--- Store the juggler's preferences (alphanumeric list) --->
	    	<cfset preferences = #listGetAt(currentLine, 6, ' ')#>
	    	<cfset jugglerArray[#jugglerPos#][4] = #listGetAt(currentLine, 6, ' ')#>

	    	<!--- Loop through each of the juggler's preferences, inserting their DP for each into the jugglerArray --->
	    	<cfloop from="1" to="#listLen(preferences)#" index="i">
	    		<cfset pref = #removeChars(#listGetAt(preferences, #i#, ',')#, 1, 1)#>
	    		<cfset prefDP = #jugglerArray[#jugglerPos#][1]#*#circuitArray[pref+1][1]#+
	    						#jugglerArray[#jugglerPos#][2]#*#circuitArray[pref+1][2]#+
	    						#jugglerArray[#jugglerPos#][3]#*#circuitArray[pref+1][3]#>
	    		<cfset jugglerArray[jugglerPos][i+4] = prefDP>
	    	</cfloop>

	    	<cfset jugglerPos += 1>
	    </cfif>
	</cfif>
</cfloop>

<!--- Determine how many jugglers are allowed in one circuit --->
<cfset totalCircuits = #arrayLen(circuitArray)#>
<cfset totalJugglers = #arrayLen(jugglerArray)#>
<cfset maxAllowed = totalJugglers/totalCircuits>

<!--- Assess jugglers and place them into the assignment array --->
<cfloop from="#arrayLen(jugglerArray)#" to="1" index="j" step="-1">
	<!--- Some variables that need to be reset each cycle --->
	<cfset allJugglersHandled = false>
	<cfset cycles = 0>
	<cfset currentJuggler = j>

	<!--- Output to track progress --->
	Now Starting Juggler <cfoutput>#j#</cfoutput><br />

	<!--- This loop is designed to ensure that all jugglers are handled (so long as they are qualified) --->
	<cfloop condition="allJugglersHandled EQ false">
		<cfset cycles += 1>

		<!--- Some jugglers will not qualify for any of their preferences.  They'll be stored in a separate array for later --->
		<cfif cycles EQ 100>
			<cfset poorJugglerArray[poorJugglerIndex] = currentJuggler>
			<cfset poorJugglerIndex += 1>
			<cfbreak>
		</cfif>

		<!--- Loop through each of a juggler's preferences, assigning them if they qualify --->
		<cfset preferences = #jugglerArray[currentJuggler][4]#>
		<cfloop from="1" to="10" index="i">
			
			<cfset assignmentIndex = #removeChars(#listGetAt(preferences, i, ',')#, 1, 1)#+1>
			<cfset numAssigned = #arrayLen(assignmentArray[assignmentIndex])#>
			<cfset currentJugglerDP = #jugglerArray[currentJuggler][i+4]#>
			
			<!--- ############################################################################################# --->
			<!--- Path A: No jugglers assigned yet, just put current juggler in and break from preference array --->
			<!--- ############################################################################################# --->
			<cfif numAssigned EQ 0>
				<cfset assignmentArray[#assignmentIndex#][1] = "#currentJuggler#:#currentJugglerDP#">

				<cfset allJugglersHandled = 1>
				<cfbreak>

			<!--- ############################################################################################# --->
			<!--- Path B: There are already jugglers assigned to this circuit, but it is not yet full 			--->
			<!--- ############################################################################################# --->
			<cfelseif numAssigned LT maxAllowed>
				
				<cfloop from="#numAssigned#" to="1" index="c" step="-1">
					<cfset assignedJugglerDP = #listGetAt(assignmentArray[assignmentIndex][c], 2, ":")#>

					<!--- If currentJuggler doesn't qualify well, place them on the very end --->
					<cfif assignedJugglerDP GTE currentJugglerDP>
						<cfset assignmentArray[#assignmentIndex#][c+1] = "#currentJuggler#:#currentJugglerDP#">
						<cfbreak>

					<!--- If currentJuggler qualifies on some level, displace assigned jugglers as necessary --->
					<cfelse>
						<cfset assignmentArray[#assignmentIndex#][c+1] = assignmentArray[#assignmentIndex#][c]>
						<cfset assignmentArray[#assignmentIndex#][c] = "#currentJuggler#:#currentJugglerDP#">
					</cfif>
				</cfloop>

				<!--- No jugglers had to be displaced, break from preference and all jugglers loop --->
				<cfset allJugglersHandled = 1>
				<cfbreak>

			<!--- ############################################################################################# --->
			<!--- Path C: This circuit is already full, will need to displace a juggler or move to next.		--->
			<!--- ############################################################################################# --->
			<cfelseif numAssigned EQ maxAllowed>
				<cfloop from="#maxAllowed#" to="1" index="c" step="-1">
					<cfset assignedJugglerDP = #listGetAt(assignmentArray[assignmentIndex][c], 2, ":")#>

					<!--- If currentJuggler is not better qualified than the worst already assigned, move to next preference--->
					<cfif assignedJugglerDP GTE currentJugglerDP>
						<cfbreak>

					<!--- Otherwise, displace assigned jugglers as needed --->
					<cfelse>
						<cfset resetVars = 1>
						<cfset assignmentArray[#assignmentIndex#][c+1] = assignmentArray[#assignmentIndex#][c]>
						<cfset assignmentArray[#assignmentIndex#][c] = "#currentJuggler#:#currentJugglerDP#">
					</cfif>
				</cfloop>

				<!--- Reset value of current juggler to displaced juggler, delete extra assignment --->
				<cfif resetVars NEQ 0>
					<cfset deleteIndex = maxAllowed+1>
					<cfset currentJuggler = #listGetAt(assignmentArray[assignmentIndex][deleteIndex], 1, ":")#>
					<cfset temp = #arrayDeleteAt(assignmentArray[assignmentIndex],deleteIndex)#>
					<cfset resetVars = 0>

					<!--- New juggler being processed, break from preference loop --->
					<cfbreak>
				</cfif>
			<cfelse>
				I should not be here, juggler <cfoutput>#currentJuggler# with numAssigned: #numAssigned# and maxAllowed:#maxAllowed#</cfoutput><cfabort>
			</cfif>
		</cfloop>
	</cfloop>
</cfloop>

Handling poor jugglers ...<br />

<!--- Create an array that will contain every circuit still not full along with how many spaces are available --->
<cfset openCircuitArray = arrayNew(2)>
<cfset insertIndex = 1>
<cfloop from="#arrayLen(circuitArray)#" to="1" index="a" step="-1">
	<cfif #arrayLen(assignmentArray[a])# LT maxAllowed>
		<cfset openCircuitArray[insertIndex][1] = a>
		<cfset openCircuitArray[insertIndex][2] = (maxAllowed - arrayLen(assignmentArray[a]))>
		<cfset insertIndex += 1>
	</cfif>
</cfloop>

<!--- Loop through the array of open circuits, assign remaining jugglers based on merit --->
<cfloop from="#arrayLen(openCircuitArray)#" to="1" index="i" step="-1">
	<cfset currentCircuit = openCircuitArray[i][1]>
	<cfset circuitSpots = openCircuitArray[i][2]>
	<cfset bestJuggler = 0>
	<cfset bestJugglerDP = 0>

	<!--- Circuits can have as many as three open spots remaining, using a variable to determine where to begin --->
	<cfset loopFrom = #arrayLen(assignmentArray[currentCircuit])#+1>

	<cfloop from="#loopFrom#" to="#maxAllowed#" index="s">
		<cfloop from="#arrayLen(poorJugglerArray)#" to="1" index="i" step="-1">
			<cfset jugglerDP = #jugglerArray[poorjugglerArray[i]][1]#*#circuitArray[currentCircuit][1]#+
								#jugglerArray[poorjugglerArray[i]][2]#*#circuitArray[currentCircuit][2]#+
								#jugglerArray[poorjugglerArray[i]][3]#*#circuitArray[currentCircuit][3]#>
			<cfif jugglerDP GT bestJugglerDP>
				<cfset bestJugglerDP = jugglerDP>
				<cfset bestJuggler = poorJugglerArray[i]>
			</cfif>
		</cfloop>

		<!--- Failsafe for writing the file, some trouble was being caused --->
		<cfif bestJuggler NEQ 0>
			<cfset assignmentArray[currentCircuit][s] = "#bestJuggler#:#bestJugglerDP#">	
		</cfif>
	</cfloop>
</cfloop>

Sending data to file ... <br />

<!--- fullString variable will contain full output to be sent to file --->
<cfset fullString = "">

<!--- Loop through the assignment array and construct fullString line by line --->
<cfloop from="#arrayLen(assignmentArray)#" to="1" index="i" step="-1">
	<cfset thisLine = "">
	<cfset circuitNum = i-1>
	<cfset circuitString = "C#circuitNum#">
	<cfset thisLine = thisline & circuitString>

	<!--- Loop through the jugglers in a given circuit, most to least qualified --->
	<cfloop from="1" to="#arrayLen(assignmentArray[i])#" index="j">
		<cfset jugglerNum = #listGetAt(#assignmentArray[i][j]#, 1, ':')#-1>
		<cfset jugglerString = " J#jugglerNum#">

		<cfif jugglerNum EQ -1>
			<cfdump var="#assignmentArray[i][j]#">
		</cfif>
		<cfset jugglerPreferences = #jugglerArray[jugglerNum+1][4]#>

		<!--- Output a juggler's preferences with their DP for each --->
		<cfloop from="1" to="#listLen(preferences)#" index="p">
    		<cfset pref = #removeChars(#listGetAt(jugglerPreferences, #p#, ',')#, 1, 1)#>
    		<cfset prefDP = #jugglerArray[jugglerNum+1][p+4]#>

    		<cfset jugglerString = jugglerString & " C#pref#:#prefDP#">
    	</cfloop>

    	<!--- Append either a comma or a line break, depending on how many jugglers remain --->
    	<cfif j NEQ arrayLen(assignmentArray[i])>
    		<cfset jugglerString = jugglerString & ",">
    	<cfelse>
    		<cfset jugglerString = jugglerString & Chr(13)>
    	</cfif>

    	<cfset thisLine = thisLine & jugglerString>
	</cfloop>
	<cfset fullString = fullString & thisLine>
</cfloop>

<!--- Write file --->
<cfset path="E:\Inetpub\virtualwwwroot\CapturePointIntranet\jugglerSort\juggleOutput.txt">
<cffile action="write" file="#path#" output="#fullString#" fixnewline="yes">

<!--- Confirm page has finished processing the input file --->
File Written: <cfoutput>#path#</cfoutput>
