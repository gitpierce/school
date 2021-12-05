function Test-CloudFlare {

<#
.SYNOPSIS
Cmdlet to test network connection from a remote computer.

.DESCRIPTION
This cmdlet creates a remote session to one or more computers
on local network, then tests the remote computer(s) internet
connection and outputs the results.

.PARAMETER path
The desired filepath to set location to and export job
output file to.

.PARAMETER ComputerName
Mandatory parameter that sets a value for a computer name.

.PARAMETER Output
Mandatory parameter that decides how test results will be output.
Options are host (output in terminal), text (output in .txt file),
and csv (output in .csv file).

.EXAMPLE 
PS> Test-CloudFlare -ComputerName <IP or computer name>

Performs net test of specified computer.

.EXAMPLE
PS> Test-CloudFlare -Output <Output type>

Performs net test and outputs results according to ouput type entered.
Output types include: Text (.txt), CSV (.csv), or Host (Display in terminal)

.EXAMPLE
PS> Test-CloudFlare -path <File path>

Specifies a file path to perform test and place output file

.NOTES
Author: Pierce Shultz
Last Edit: 11-14-2021
Version 0.12

CHANGELOG:
-Created try/catch construct under ForEach to display error message if any part of test fails
-Added $params hash table for New-PSSession parameters
-Changed $OBJ to be created using PSCustomObject and inserting parameters originally defined by $props hash table
-Added write-host commands to tell user what processes are being run as the script runs

#>


    [CmdletBinding()]
    
    #Setting parameters
    param (
        [Parameter(mandatory=$True,
        ValueFromPipeline=$True)]
        [Alias('CN','Name')]
        [string[]]$ComputerName,
        [Parameter(mandatory=$true)]
        [ValidateSet('Host','Text','CSV')]
        [string]$Output,
        [Parameter(mandatory=$false)]
        [string]$path = $env:USERPROFILE
)#param


#Setting process for each computer listed in ComputerName parameter
    foreach ($computer in $ComputerName){
        try {
    $datetime=Get-Date
    $params=@{
        'ComputerName'=$computer
        'ErrorAction'='Stop'
    }
    Write-Host "Connecting to $Computer..." -ForegroundColor black -BackgroundColor yellow
    $session=New-PSSession @params
    Enter-PSSession $session
    Write-Host "Running connection test on $Computer..." -ForegroundColor black -BackgroundColor yellow
    $TestCF=test-netconnection -computername one.one.one.one -informationlevel detailed
    #Creating PSObject that contains properties to be listed in output
    Write-Host "Receiving results..." -ForegroundColor black -BackgroundColor yellow
    $OBJ=[PSCustomObject]@{
        'ComputerName'=$computer
        'PingSuccess'=$TestCF.PingSucceeded
        'NameResolve'=$TestCF.NameResolutionSucceeded
        'ResolvedAddresses'=$TestCF.ResolvedAddresses
    }
    Exit-PSSession
    Remove-PSSession $session
}#try
catch{
    Write-Host "Remote connection to $computer failed." -ForegroundColor Red
}#catch
}#foreach

Write-Host "Generating results in $Output..." -ForegroundColor black -BackgroundColor yellow
#Switch using $Output parameter to decide output method
switch ($Output) {
    "Host" {
        "Computer Tested: $Computer",
        "$datetime"
        $OBJ
    }
    "CSV" {
        $OBJ | Out-File $path\TestResults.txt
        Add-content -path $path\RemTestNet.csv -value (
            "Computer Tested: $Computer",
            "$datetime",
            (Get-Content $Path\TestResults.txt)
        )
        Start-Sleep 3
        rm $path\TestResults.txt
        notepad.exe $path\RemTestNet.csv
    }
    "Text" {
        $OBJ | Out-File $path\TestResults.txt
        Add-content -path $path\RemTestNet.txt -value (
            "Computer Tested: $Computer",
            "$datetime",
            (Get-Content $path\TestResults.txt)
        )
        Start-Sleep 3
        rm $path\TestResults.txt
        notepad.exe $path\RemTestNet.txt
    }
}#switch
Write-Host "Test complete." -ForegroundColor black -BackgroundColor yellow
}#function