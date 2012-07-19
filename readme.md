# Get-Orphan-Drives

## Description
The overall goal of this script is to identify users home drives that don't have user permissions associated with them
There are a number of assumptions;
- the folder is named after the userID
- if a userID doesn't have permissions to a folder of the same name it is an orphan

## Logic
Here is a short brief on the logic:
- Imports a user provided CSV (generated from a ScriptLogic reporting tool)
- Inspects the CSV and makes a decision if that line of permissions has a matching user account associated with it
- splits true matches into one array and false matches into another
- sorts both these arrays and deletes duplicate entries based on userID
- checks if an entry in the false array exists in the true array - if so, discards that user as not orphan
- captures other userIDs that don't have a match in the true array and displays these as orphan users

## Required CSV file
The required CSV file is currently generated using a ScriptLogic tool.
Check the code to see which attributes are important and used - here is a sample line;

StartDate,DomainName,ComputerName,FullPath,AccountID,AccountType,AccountDisplayName,AceTypeText,AppliesTo,IsInherited,PermText,FullName,SAMAccountDomain
7/8/2012 9:55:49 PM,domain,server.domain,C:\vol111\home\USERID,long-number,G,\\Server\Permission group,Allow,"This folder, subfolders and files",False,Full Control,,\\Server