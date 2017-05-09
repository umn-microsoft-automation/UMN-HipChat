# TODO: add permenent store for the api server variable for persistance between module loads.
# Global Variables
###
# Copyright 2017 University of Minnesota, Office of Information Technology

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
###

$HipChatAPIServer = "api.hipchat.com"

function Get-HipChatAPIServer {
	<#
		.SYNOPSIS
			Gets the value of the HipChatAPIServer variable in the module
		.DESCRIPTION
			Gets the value of the HipChatAPIServer variable in the module
		.EXAMPLE
			Get-HipChatAPIServer
	#>
	return $script:HipChatAPIServer
}

function Set-HipChatAPIServer {
	<#
		.SYNOPSIS
			Sets the value of the HipChatAPIServer variable in the module.
		.DESCRIPTION
			Takes in the HipChat API server name and sets it in the module.
		.EXAMPLE
			Set-HipChatAPIServer -HipChatAPIServer "api.hipchat.com"
		.PARAMETER HipChatAPIServer
			This is the name of the HipChat API server.
		.NOTES
			The variable set by this function will reset every time the module is imported.
	#>
	[CmdletBinding()]
	param(
		[String]$HipChatAPIServer
	)

	$script:HipChatAPIServer = $HipChatAPIServer
}

function Send-HipChat {
	<#
		.SYNOPSIS
			This is a function which sends a message to a HipChat room.
		.DESCRIPTION
			Takes in a message, apitoken and room and sends a message to that HipChat room.
		.PARAMETER Message
			The string you want to send to the room in hipchat
		.PARAMETER Color
			Background color of the HipChat message.  Can only be yellow, green, red, purple, gray or random.
			They must be lowercase.
			Default: gray
		.PARAMETER Notify
			A switch to indicate whether or not to ping everyone in the room about the message.
			Default: $false
		
		.PARAMETER APIToken
			The API token generated to send messages to the specific room.
			hipchat_server_address/rooms
		
		.PARAMETER Room
			The ID or html friendly name of the room.
			ID can be found on the hipchat_server_address/rooms page
		
		.PARAMETER Retry
			How many retries if there's a failure.
			Default: 0
		
		.PARAMETER RetrySeconds
			How many seconds to wait before retrying.
			Default: 30
		.NOTES
		Name: Send-HipChat
		Author: Jeff Bolduan
		LASTEDIT: 10/7/2016
		Based on code from: https://github.com/markwragg/Powershell-Hipchat
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $True)]
		[String]$Message,

		[Parameter(Mandatory = $False)]
		[ValidateSet('yellow', 'green', 'red', 'purple', 'gray', 'random')]
		[String]$Color = 'Gray',

		[Parameter(Mandatory = $False)]
		[Switch]$Notify = $false,

		[Parameter(Mandatory = $True)]
		[String]$APIToken,

		[Parameter(Mandatory = $True)]
		[String]$Room,

		[Parameter(Mandatory = $False)]
		[int]$Retry = 0,

		[Parameter(Mandatory = $False)]
		[int]$RetrySeconds = 30
	)

	# Create the message
	$MessageHash = @{
		"message" = $Message;
		"color" = $Color;
		"notify" = [String]$Notify
	}

	$URI = "https://$($script:HipChatAPIServer)/v2/room/$Room/notification?auth_token=$APIToken"
	$Body = ConvertTo-Json -InputObject $MessageHash
	#Write-Host $Body

	for($RetryCount = 0; $RetryCount -le $Retry; $RetryCount++) {
		try {
			$Response = Invoke-WebRequest -Method Post -Uri $URI -Body $Body -ContentType "application/json" -ErrorAction SilentlyContinue -UseBasicParsing

			#Write-Verbose "$Message has been sent"
			return $True
		} catch {
			Write-Error "Cound not send message: `r`n $($_.Exception.ToString())"

			if($RetryCount -lt $Retry) {
				Write-Warning -Message "Retrying in $RetrySeconds seconds..."
				Start-Sleep -Seconds $RetrySeconds
			}
		}
	}

	Write-Warning -Message "Could not send after $RetryCount tries."
	return $false
}