param([string]$syndir) 
[string]$taskname = "SyncthingServer"

function AddTask{
	[string]$synexe = $syndir + "\syncthing.exe"
	[CimInstance]$act = New-ScheduledTaskAction -Execute $synexe -Argument "-no-console -no-browser"
	[CimInstance]$trig = New-ScheduledTaskTrigger -AtLogOn
	[CimInstance]$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -DontStopIfGoingOnBatteries -Hidden -RunOnlyIfNetworkAvailable -ExecutionTimeLimit 0
	[CimInstance]$task = New-ScheduledTask -Action $act -Trigger $trig -Settings $set
	$null = Register-ScheduledTask -TaskName $taskname -InputObject $task
}

function RmTask{
	Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
}

function TaskExist{
	return ((Get-ScheduledTask -Taskname $taskname -ErrorAction SilentlyContinue) -ne $null)
}

function AnsOK{
	param([string]$rep)
	return ($rep -eq "o" -or $rep -eq "n")
}

function askUser{
	param([string]$ask)
	[string]$rep = ""
	$rep = Read-Host -Prompt $ask
	if (-Not (AnsOK -rep $rep)){
		do {
			$rep = Read-Host -Prompt "La saisie n'est pas valide. Saisissez la lettre 'o' ou 'n'" 
		} until (AnsOK -rep $rep)
	}
	return ($rep -eq "o")
}

function WrapAction{
	param([string]$ask, [string]$action)
	[boolean]$todo = askUser -ask $ask
	if ($todo){
		&$action
		return $true
	}else{
		return $false
	}
}

function Main{
	Clear-Host
	if (TaskExist){
		[boolean]$order = WrapAction -ask "Voulez-vous supprimer le d�marrage automatique de Syncthing � l'ouverture de session ? (o/n)" -action RmTask
		if ($order) {
			Write-Output "Le d�marrage automatique de Syncthing a �t� supprim�."
		}else{
			Write-Output "Le d�marrage automatique de Syncthing a �t� conserv�."
		}
	}else{
		[boolean]$order = WrapAction -ask "Voulez-vous activer le d�marrage automatique de Syncthing � l'ouverture de session ? (o/n)" -action AddTask
		if ($order) {
			Write-Output "Le d�marrage automatique de Syncthing a �t� install�."
		}else{
			Write-Output "Le d�marrage automatique de Syncthing n'a pas �t� install�."
		}
	}
	Write-Output "****`r`nAppuyez sur n'importe quelle touche pour quitter."
	While ($KeyInfo.VirtualKeyCode -Eq $Null) {
		$KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
	}
}

function IsAdmin{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function CallAdmin{
	$args = "$PSCommandPath -syndir " + (Get-Location).tostring()
	start-process powershell -Verb runAs -argument $args
}

if (IsAdmin){Main} else {CallAdmin}