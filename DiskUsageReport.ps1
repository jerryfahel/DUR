# Configuration data
[String[]] $servers = @("Server0","Server1","Server2","Server3","Server4");
[long] $levelAlarm = 5368709120; # 5 GB
[string] $smtpServer  = "smtp.mail.com";
[string] $sender = "sender@mail.com";
[string] $receiver = "receiver@mail.com";
[string] $subject = "Disk Usage Report";
[string] $body = [String]::Empty;

function getHtmlTableHeader {
	[String] $header = [String]::Empty; 
	$header += "<table><tr> 
		<th>Drive</th> 
		<th>Volume Name</th> 
		<th>Free GB</th></tr>"; 
	return $header; 
}

function getHtmlTableRow {
	param([object[]] $rowData)
	[String] $textRow = [String]::Empty;
	$textRow += "<tr>
		<td>"  + $rowData[0].ToString() + "</td>
		<td>"  + $rowData[1].ToString() + "</td>
		<td>" + $rowData[3].ToString("N0") + "</td></tr>";
	return $textRow; 
}

$body += "<head><title>Disk usage report</title></head><body>"; 
foreach($server in $servers)  {
	$disks = Get-WmiObject -ComputerName $server -Class Win32_LogicalDisk -Filter "DriveType = 3";
	foreach ($disk in $disks) {
		if ($disk.FreeSpace -le $levelAlarm) {
			$body += ("<p><h2>{0}<h2></p>`n" -f $server);
			$body += getHtmlTableHeader;
			[Object[]] $data = @(
				$disk.DeviceID,
				$disk.VolumeName,
				[Math]::Round(($disk.Size / 1073741824), 2),
				[Math]::Round(($disk.FreeSpace / 1073741824), 2),
				[Math]::Round((100.0 * $disk.FreeSpace / $disk.Size), 1),
			)
			$body += getHtmlTableRow -rowData $data;
			$body += "</table>`n";
		}
	}
}
$body += "</body>";

# Init Mail
$smtpClient = New-Object Net.Mail.SmtpClient($smtpServer);
$emailFrom  = New-Object Net.Mail.MailAddress $sender, $sender;
$emailTo = New-Object Net.Mail.MailAddress $receiver , $receiver;
$mailMsg = New-Object Net.Mail.MailMessage($emailFrom, $emailTo, $subject, $body);
$mailMsg.IsBodyHtml = $true;
$smtpClient.Send($mailMsg)
