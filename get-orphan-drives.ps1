﻿# Import the CSV file first
Write-Host "Importing CSV file - please wait."
$HomeDrives = Import-Csv "C:\Files\home-drives-test.csv"

Write-Host "Measuring CSV file - please wait."
$TotalLines = Import-Csv "C:\Files\home-drives-test.csv" | Measure-Object
Write-Host $TotalLines.Count " entries detected."

# Create a report array
$HomeDriveInfo = @()
$MatchingDriveInfo = @()
$TrueArray = @()
$FalseArray = @()
$OrphanArray = @()

# We should set all our varialbes to null
$PreviousCompare = 0
$PreviousUser = 0
$LineCounter = 0

# Evaluate each line
Write-Host "Now evaluating each CSV entry"
foreach ($line in $HomeDrives){
	# Increment each line
	$LineCounter++
	
	# Display a progress bar to show progression through CSV file
	Write-Progress -Id 2 -activity "Analyzing each line" -status "Percent read: " -PercentComplete (($LineCounter / $TotalLines.Count)  * 100)
	
	# Lets split the FullPath to determine username
	$FullPathSplit = $line.FullPath.Split("\")
	# We want the last entry in the array as this will be the name of the home drive (and should reflect the userID)
	$UserID = $FullPathSplit[-1]
	
	# Use the match function to see if the UserID exists within the AccountDisplayName
	$CompareResult = $line.AccountDisplayName -match $UserID
	
	# Build two arrays based on the results of the compare
	# One array to contain all "True" matches
	# Another array to contain all "False" matches
	if ( $CompareResult -eq $true ) {
		$objTrueArray = New-Object System.Object
		
		$objTrueArray | Add-Member -MemberType NoteProperty -Name UserID -Value $UserID
		$objTrueArray | Add-Member -MemberType NoteProperty -Name Permission -Value $line.AccountDisplayName
		$objTrueArray | Add-Member -MemberType NoteProperty -Name Server -Value $line.ComputerName
		$objTrueArray | Add-Member -MemberType NoteProperty -Name Path -Value $line.FullPath
		$objTrueArray | Add-Member -MemberType NoteProperty -Name Match -Value $CompareResult
		
		$TrueArray += $objTrueArray
		
	} else {
		$objFalseArray = New-Object System.Object
		
		$objFalseArray | Add-Member -MemberType NoteProperty -Name UserID -Value $UserID
		$objFalseArray | Add-Member -MemberType NoteProperty -Name Permission -Value $line.AccountDisplayName
		$objFalseArray | Add-Member -MemberType NoteProperty -Name Server -Value $line.ComputerName
		$objFalseArray | Add-Member -MemberType NoteProperty -Name Path -Value $line.FullPath
		$objFalseArray | Add-Member -MemberType NoteProperty -Name Match -Value $CompareResult
		
		$FalseArray += $objFalseArray
	}
}

Write-Host "CSV file analysis complete. " $LineCounter " lines analysed"
Write-Host "Now identifying orphan home drives"

# Remove duplicate entries from the arrays
$SmallerTrueArray = $TrueArray | sort -unique -property UserID
$SmallerFalseArray = $FalseArray | sort -unique -property UserID

$UserCounter = 0

# Now traverse through the FalseArray and see if it has an entry in the TrueArray
foreach ( $FalseUser in $SmallerFalseArray ) {
	$GlobalMatch = $false
	$UserCounter++
	$TrueUserCounter = 0
	$PercentProcessed = (($UserCounter / $SmallerFalseArray.Length)  * 100)
	$PercentProcessed = "{0:N2}" -f $PercentProcessed
	
	Write-Progress -Id 3 -activity "Comparing each user" -status "Percent analysed: $PercentProcessed" -PercentComplete $PercentProcessed
	
	# Take the UserID and see if it exists in the TrueArray
	foreach ( $TrueUser in $SmallerTrueArray ) {
		$TrueUserCounter++
	
		# Test to see if each userID matches
		$UsersMatch = $TrueUser.UserID -match ($FalseUser.UserID)
	
		# If we have a match - lets set a global flag to say we have a match
		if ( $UsersMatch -eq $true ) {
			$GlobalMatch = $true
		}
	}
	
	# Check to see if the global flag was set for the user
	# If it wasn't - we have identified a user with an orphan account
	if ( $GlobalMatch -eq $false ) {
		# Add the orphan home drive info to an array only containing orphan users
		$FalseUser | select UserID,Server,Path
		$OrphanArray += $FalseUser
	}
}

# Show us the orphan accounts
$OrphanArray | FT