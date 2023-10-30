# Original Author: MJC
# Last Updated: MJC 7-5-23
# Forwards error logs to given address. This can be a user, list of users, or a distribution group.

# Email configuration for reports
$EMAIL_SMTP = 'smtp.johnshopkins.edu'
# If filled out, send error reports
$EMAIL_ERROR_REPORT_FROM = 'USS IT Services <ussitservices@jhu.edu>'
# Can be string or array of strings.
$EMAIL_ERROR_REPORT_TO = @('mcarras8@jhu.edu','ldibern1@jhu.edu','mbelisa1@jhu.edu','ussitservices@jhu.edu')
# Local filepath to last log file.
$LOGFILEPATH = "Logs\jamf2snipe_$(get-date -f yyyy-MM-dd).log"

# Also notify on warnings about error responses ($regexWarningError)
$NotifyOnErrorResponse = $true

# Regex to seach for in log file. Should start at beginning of line.
$regexError = "(Traceback |ERROR: |Error: )"
$regexErrorExclude = $null
$regexWarningError = "WARNING:[^\r\n]+error .+(?!\[502\])"
$regexWarningErrorExclude = "[502]" # Exclude 502 generic errors

# Split on these log boundaries and use the last one found.
$splitLogBoundaries = '** LOG START: '

# Combines regex into named captures.
[regex]$regexCombined = "(?<error>((^|[\r\n])$regexError[^\r\n]+))|(?<warningerror>((^|[\r\n])$regexWarningError[^\r\n]+))"

# Look in PsScriptRoot first. If not found, look in current directory.
if (Test-Path ".\$LOGFILEPATH" -PathType Leaf) {
    $LOGFILEPATH = "$PsScriptRoot\$LOGFILEPATH"
} else {
    $LOGFILEPATH = ".\$LOGFILEPATH"
}

if (Test-Path $LOGFILEPATH -PathType Leaf) {
    $rawText = Get-Content $LOGFILEPATH -Raw
    If ($rawText) {
        # Get the last entry starting with $splitLogBoundaries.
        $rawText = $rawText -split $splitLogBoundaries, 0, "simplematch" | Select -Last 1
        $matches = $regexCombined.matches($rawText)
        $errorCount = ($matches.Groups | where {$_.Success -eq $true -And $_.Name -eq 'error' -And ([string]::IsNullOrEmpty($regexErrorExclude) -Or $_.Value -notmatch $regexErrorExclude)}).Count
        $warningErrorCount = ($matches.Groups | where {$_.Success -eq $true -And $_.Name -eq 'warningerror' -And ([string]::IsNullOrEmpty($regexWarningErrorExclude) -Or $_.Value -notmatch $regexWarningErrorExclude)}).Count

        Write-Host("DEBUG: ErrorCount=$errorCount, WarningErrorCount=$warningErrorCount")

        If ($errorCount -gt 0 -Or ($warningErrorCount -gt 0 -And $NotifyOnErrorResponse)) {
            $params = @{
                "From" = $EMAIL_ERROR_REPORT_FROM
                "To" = $EMAIL_ERROR_REPORT_TO
                "SmtpServer" = $EMAIL_SMTP
                "Subject" = 'Errors from jamf2snipe'
                "Body" = "There were [{0}] errors and [{1}] warnings with errors from [jamf2snipe] running on [${ENV:COMPUTERNAME}]. See attached logfile for more details." -f $errorCount, $warningErrorCount
                "Priority" = "High"
                "DeliveryNotificationOption" = "OnSuccess", "OnFailure"
                "Attachments" = $LOGFILEPATH
            }

            # Email out notifications of any errors.
            try {
	            Send-MailMessage @params
            } catch {
	            $params['Attachments'] = $null
                $params['Body'] = "There were [{0}] errors and [{1}] warnings with errors from [jamf2snipe] running on [${ENV:COMPUTERNAME}]. See server log file for more detail." -f $errorCount, $warningErrorCount
	            Send-MailMessage @params
            }

            Add-Content -Path $LOGFILEPATH -Value ("[forward-errorlogs.ps1][{0}] Emailed error report to [{1}]" -f ((Get-Date).toString("yyyy/MM/dd HH:mm:ss")), ($EMAIL_ERROR_REPORT_TO -join ", ")) -PassThru
        }
    }
}