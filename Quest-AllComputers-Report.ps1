<#
	Quest-AllComputers-Report.ps1
	Created By - Kristopher Roy
	Created On - May 2017
	Modified On - 08 Jan 2020

	This Script Requires that the Quest_ActiveRolesManagementShellforActiveDirectory be installed https://www.powershelladmin.com/wiki/Quest_ActiveRoles_Management_Shell_Download
	Pulls a report of all non-server workstations that have logged in within 45days
#>


add-pssnapin quest.activeroles.admanagement
Import-Module activedirectory

$runtime = Get-Date -Format "yyyyMMMdd"

#deffinition for UAC codes
$lookup = @{4096="Workstation/Server"; 4098="Disabled Workstation/Server"; 4128="Workstation/Server No PWD"; 
4130="Disabled Workstation/Server No PWD"; 528384="Workstation/Server Trusted for Delegation"; 83955712="Workstation/Server Partial Secrests Account/Trusted For Delegation/PWD not Expire";
528416="Workstation/Server Trusted for Delegation"; 532480="Domain Controller"; 66176="Workstation/Server PWD not Expire"; 
66178="Disabled Workstation/Server PWD not Expire";512="User Account";514="Disabled User Account";66048="User Account PWD Not Expire";66050="Disabled User Account PWD Not Expire"}


$qadcomputers = Get-QADComputer -searchroot "dc=crowley,dc=com" -searchscope subtree -sizelimit 0 -includedproperties name,userAccountControl,whenCreated,whenChanged,lastlogondate,dayssincelogon,lastlogontimestamp,description,operatingSystem,operatingsystemservicepack|Select-Object -Property name,lastlogontimestamp,@{N='dayssincelogon';E={(new-timespan -start (get-date $_.LastLogonTimestamp -Hour "00" -Minute "00") -End (get-date -Hour "00" -Minute "00")).Days}},@{N='userAccountControl';E={$lookup[$_.userAccountControl]}},whenCreated,whenChanged,description,operatingSystem,operatingSystemVersion,operatingsystemservicepack|sort name

$qadcomputers|export-csv C:\Belltech\$runtime-qAD-AllComputerReport.csv -NoTypeInformation

$emailBody = "<h1>Crowley Weekly All Workstations Report</h1>"
$emailBody = $emailBody + "<p><em>"+(Get-Date -Format 'MMM dd yyyy HH:mm')+"</em></p>"
#$emailBody = $emailBody + '<h2><img style="font-size: 14px;" src="https://html-online.com/img/6-table-div-html.png" alt="html table div" width="45" /></h2>'

$htmlforEmail = $emailBody + @'
<h2>Included Fields:</h2>
<table style="height: 535px;" border="1" width="625">
<tbody>
<tr style="height: 47px;">
<td style="width: 304px; height: 25px;"><strong>name</strong></td>
<td style="width: 305px; height: 25px;"><em>&nbsp;Computer Name</em></td>
</tr>
<tr style="height: 47px;">
<td style="width: 304px; height: 25px;"><strong>lastLogonTimestamp</strong></td>
<td style="width: 305px; height: 25px;"><em>Last Recorded Timestamp for a logon</em></td>
</tr>
<tr style="height: 47px;">
<td style="width: 304px; height: 25px;"><strong>dayssincelogon</strong></td>
<td style="width: 305px; height: 25px;"><em>calculated from lastlogontimestamp</em></td>
</tr>
<tr style="height: 47px;">
<td style="width: 304px; height: 25px;"><strong>userAccountControl</strong></td>
<td style="width: 305px; height: 25px;"><em>User/Computer settings for AD</em></td>
</tr>
<tr style="height: 47px;">
<td style="width: 304px; height: 25px;"><strong>whenCreated</strong></td>
<td style="width: 305px; height: 25px;"><em>When account was created</em></td>
</tr>
<tr style="height: 29px;">
<td style="width: 304px; height: 25px;"><strong>whenChanged</strong></td>
<td style="width: 305px; height: 25px;"><em>Date AD changes were made to account</em></td>
</tr>
<tr style="height: 10px;">
<td style="width: 304px; height: 25px;"><strong>description</strong></td>
<td style="width: 305px; height: 25px;"><em>Description field from AD if populated</em></td>
</tr>
<tr style="height: 10px;">
<td style="width: 304px; height: 25px;"><strong>operatingSystem</strong></td>
<td style="width: 305px; height: 25px;"><em>&nbsp;OS Name</em></td>
</tr>
<tr style="height: 1px;">
<td style="width: 304px; height: 25px;"><strong>operatingSystemVersion</strong></td>
<td style="width: 305px; height: 25px;"><em>Version number of OS</em></td>
</tr>
<tr style="height: 24.3594px;">
<td style="width: 304px; height: 25px;"><strong>operatingSystemServicePack</strong></td>
<td style="width: 305px; height: 25px;"><em>OS Service Pack installed, if any</em></td>
</tr>
</tbody>
</table>
'@

$recipients = @("<WorkstationDataReporting@crowley.com>","Chris <cavery@belltechlogix.com>","Kristopher <kroy@belltechlogix.com>","Jason <jcooper1@belltechlogix.com>","Veneita <vwillis@belltechlogix.com>","Audrey <amatlala@belltechlogix.com>","Tim <twheeler@belltechlogix.com>","Jay <jhardcastle@belltechlogix.com>","Jay <Melvin.Davis@crowley.com>","James <James.Hudgens@crowley.com>")

#$recipients = "Jason <jcooper1@belltechlogix.com>"
Send-MailMessage -from ADReportsKRoy@crowley.com -to $recipients -subject "Crowley All Workstations Report" -smtpserver mail.crowley.com -BodyAsHtml $htmlforEmail -Attachments C:\Belltech\$runtime-qAD-AllComputerReport.csv


#Get-QADComputer -searchroot "dc=crowley,dc=com" -searchscope subtree -sizelimit 0 -includedproperties name,userAccountControl,whenCreated,whenChanged,lastlogondate,dayssincelogon,lastlogontimestamp,description,operatingSystem,operatingsystemservicepack|Select-Object -Property name,lastlogontimestamp,@{N='dayssincelogon';E={(new-timespan -start (get-date $_.LastLogonTimestamp -Hour "00" -Minute "00") -End (get-date -Hour "00" -Minute "00")).Days}},@{N='userAccountControl';E={$lookup[$_.userAccountControl]}},whenCreated,whenChanged,description,operatingSystem,operatingSystemVersion,operatingsystemservicepack|where{$_.operatingSystem -notlike "*server*"}|where{$_.dayssincelogon -le 45 -and $_.lastlogontimestamp -ne $null}|export-csv C:\belltech\07Nov18-WorkstationReport.csv
