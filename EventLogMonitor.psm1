Function Global:Start-EventLogMonitor {
    <#  
    .SYNOPSIS  
        Allows you to define specific event IDs to monitor for on a define event log file.  
        
    .DESCRIPTION  
        Allows you to define specific event IDs to monitor for on a define event log file. An action that occurs when tripped can
        also be configured manually or an automated action will be generated.
        
    .PARAMETER Computername
        Name of computer or computers to configure the monitoring job

    .PARAMETER EventId
        Event IDs to monitor for (Mandatory if not using Query parameter)

    .PARAMETER Severity
        Event severity to monitor for (Mandatory if not using Query parameter)

    .PARAMETER LogName
        Event log to perform monitor against. (Mandatory if not using Query parameter)

    .PARAMETER Query
        Query used to configure the monitoring job.    
        
    .PARAMETER Action
        Scriptblock that defines a set action when monitor is tripped. If not defined, a hard-coded alert will be used.(Optional)
    
    .PARAMETER Persistent
        Allows for a persistent monitor of logs even if system specified is rebooted.
        
    .NOTES  
        Name: Start-EventLogMonitor
        Author: Boe Prox
        DateCreated: 06/9/2011
        Links:
        http://msdn.microsoft.com/en-us/library/aa394226(v=vs.85).aspx  

    .EXAMPLE
        Start-EventLogMonitor -Logname Application -EventID 1023
        
        Id              Name            State      HasMoreData     Location             Command
        --              ----            -----      -----------     --------             -------
        2               workstation...  NotStarted False                                ...
        
        06/10/2011 08:47:51: New Event Raised on Workstation1! Check the $alert variable for more information.
        
        C:\PS>$alert
        
        __GENUS          : 2
        __CLASS          : Win32_NTLogEvent
        __SUPERCLASS     :
        __DYNASTY        : Win32_NTLogEvent
        __RELPATH        : Win32_NTLogEvent.Logfile="Application",RecordNumber=290198
        __PROPERTY_COUNT : 16
        __DERIVATION     : {}
        __SERVER         :
        __NAMESPACE      :
        __PATH           :
        Category         : 0
        CategoryString   :
        ComputerName     : Workstation1
        Data             :
        EventCode        : 1023
        EventIdentifier  : 1023
        EventType        : 1
        InsertionStrings : {.NET Runtime version 2.0.50727.4211 - t}
        Logfile          : Application
        Message          : .NET Runtime version 2.0.50727.4211 - t
        RecordNumber     : 290198
        SourceName       : .NET Runtime
        TimeGenerated    : 20110610134751.000000-000
        TimeWritten      : 20110610134751.000000-000
        Type             : Error
        User             :

        Description
        -----------
        This command will monitor the Application log for event ID 1023. The action block is using the default setting which
        configures the $alert variable to be explored when an event is triggered. 
        
    .EXAMPLE
        $Action = {
        $account = $Event.SourceEventArgs.NewEvent.TargetInstance.InsertionStrings[0]
        $workstation = $Event.SourceEventArgs.NewEvent.TargetInstance.InsertionStrings[1]
        $dc = $Event.SourceEventArgs.NewEvent.TargetInstance.Computer
        Write-Host -Fore Green "$(Get-Date): $($DC) reported $($Account) has been locked out while attempting to log into $($Workstation)."   
        }
        Start-EventLogMonitor -Computer DC1,DC2,DC3 -Logname Security -EventID 4740 -Action $Action
        
        Id              Name            State      HasMoreData     Location             Command
        --              ----            -----      -----------     --------             -------
        2               DC1_EventLo...  NotStarted False                                ...
        4               DC2_EventLo...  NotStarted False                                ...
        6               DC3_EventLo...  NotStarted False                                ...
        
        06/10/2011 08:47:51: New Event Raised on DC2! Check the $alert variable for more information.
        
        Description
        -----------
        This command will monitor the Security logs on Domain Controllers DC1,DC2 and DC3 for Event ID 4740 (Account lockout). A manually
        defined Action statement shows that an alert will be displayed on the screen showing relevant information regarding the locked
        out account.

        
    .EXAMPLE
        $Query = "select * from __InstanceCreationEvent`
         where TargetInstance isa 'Win32_NtLogEvent' and TargetInstance.logfile = 'Security' and `
        (TargetInstance.EventCode = '4740')"
        Start-EventLogMonitor -Computer DC1,DC2,DC3 -Query $Query
        
        Id              Name            State      HasMoreData     Location             Command
        --              ----            -----      -----------     --------             -------
        2               DC1_EventLo...  NotStarted False                                ...
        4               DC2_EventLo...  NotStarted False                                ...
        6               DC3_EventLo...  NotStarted False                                ...
        
        06/10/2011 08:50:51: DC1 reported testuser has been locked out while attempting to log onto workstation1
        
        Description
        -----------
        This command will monitor the Security logs on Domain Controllers DC1,DC2 and DC3 for Event ID 4740 (Account lockout). A manually
        defined Query statement was used to look for the EventID and Logfile.
    
    .EXAMPLE
        $Query = select * from __InstanceCreationEvent
        where TargetInstance isa 'Win32_NtLogEvent' and TargetInstance.logfile = 'Security' and
        (TargetInstance.EventCode = '4624' and TargetInstance.Message LIKE '%joeuser%')   
        Start-EventLogMonitor -Computer DC1,DC2,DC3 -Query $Query
        
        Description
        -----------
        This command will monitor the domain controllers for any attempts by joeuser to log into any machine on the domain.       
    #> 
    [cmdletbinding()]
    Param (
        [parameter(Position=1,ParameterSetName = "ManualQuery")]
        [parameter(Position=1,ParameterSetName = "AutoQuery")]
        [string[]]$Computername = $Env:Computername,
        
        [parameter(Position=2,ParameterSetName="AutoQuery")]
        [Int32[]]$EventId,
        
        [parameter(Position=3,ParameterSetName="AutoQuery")]
        [ValidateSet("Information","Warning","Error","Security Audit Success","Security Audit Failure")]
        [String[]]$Severity,  
          
        [parameter(Position=4,ParameterSetName="AutoQuery")]
        [string]$LogName,
        
        [parameter(Position=5,ParameterSetName = "ManualQuery")]
        [string]$Query,  
         
        [parameter(Position=6,ParameterSetName = "ManualQuery")]
        [parameter(Position=6,ParameterSetName = "AutoQuery")]
        [scriptblock]$Action,
        [parameter(Position=7,ParameterSetName = "ManualQuery")]
        [parameter(Position=7,ParameterSetName = "AutoQuery")]
        [switch]$Persistent        
        )
    Begin {   
        $SplatTable = @{}  
        If ($PSBoundParameters['EventId']) {
            Write-Verbose "Looking for specific EventID's"
            $i = 1
            $count = $eventid.count
            ForEach ($id in $eventid) {
                If ([string]::IsNullOrEmpty($querystring)) {
                    Write-Verbose "Building inital query for EventID"
                    If ($i -eq $count) {
                        $i++
                        Write-Verbose "Closing Event Query"
                        $querystring = "and ((TargetInstance.EventCode = $id))"
                    } Else {
                        $i++
                        Write-Verbose "Building Event Query"
                        $querystring = "and ((TargetInstance.EventCode = $id)"
                    }
                } Else {
                    If ($i -eq $count) { 
                        $i++
                        Write-Verbose "Closing Event Query"
                        $querystring = $querystring + " or (TargetInstance.EventCode = `'$id`'))"
                    } Else {
                        $i++
                        Write-Verbose "Building Event Query"
                        $querystring = $querystring + " or (TargetInstance.EventCode = `'$id`')"
                    }
                }           
            }
        }
        #Determine if filtering for a specific severity level
        If ($PSBoundParameters['Severity']) {
            Write-Verbose "Looking for specific severities"
            $i=1
            $count = $severity.count
            ForEach ($severe in $severity) {
                If ([string]::IsNullOrEmpty($severityquery)) {
                    Write-Verbose "Building inital query for Severity"
                    If ($i -eq $count) {
                        $i++
                        Write-Verbose "Closing Event Query"
                        $severityquery = "and ((TargetInstance.Type = $severe))"
                    } Else {
                        $i++
                        Write-Verbose "Building Event Query"
                        $severityquery = "and ((TargetInstance.Type = $severe)"
                    }
                } Else {
                    If ($i -eq $count) { 
                        $i++
                        Write-Verbose "Closing Event Query"
                        $severityquery = $severityquery + " or (TargetInstance.Type = `'$severe`'))"
                     } Else {
                        $i++
                        Write-Verbose "Building Event Query"
                        $severityquery = $severityquery + " or (TargetInstance.Type = `'$severe`')"
                    }
                }                       
            }
        }        
        If ($PSBoundParameters['LogName']) {
            Write-Verbose "Defining query string using $logfile"
            $logquery = "select * from __InstanceCreationEvent where TargetInstance isa 'Win32_NtLogEvent' and TargetInstance.logfile = `'$LogName`' "
        }
        If ($PSBoundParameters['Query']) {
            Write-Verbose "Adding user defined query to splattable"
            $SplatTable['Query'] = $Query
        } Else {
            Write-Verbose "Adding auto generated query to splattable"
            $SplatTable['Query'] = "$logquery $querystring $severityquery"
        }
        If ($PSBoundParameters['Action']) {
            Write-Verbose "Adding user defined action scriptblock to splattable"
            $SplatTable['Action'] = $Action
        } Else {
            Write-Verbose "Adding auto generated action scriptblock to splattable"
            $SplatTable['Action'] = {
                [array]$Global:alert += (($event.sourceeventargs).newevent).TargetInstance
                Write-Host -foreground Green "$(Get-Date): New Event Raised on $($alert[$alert.count -1].Computername)! Check the `$alert variable for more information."                           
            }
        }
        Write-Verbose "Query: $($SplatTable['Query'])"
        Write-Verbose "Action: $($SplatTable['Action'])"
    }
    Process {
        ForEach ($computer in $computername) {
            Write-Verbose "Testing connection to $computer"
            If (Test-Connection -Computer $computer -Count 1 -Quiet) {
                Write-Verbose "Adding $computer to splattable"
                $SplatTable['ComputerName'] = $computer
                $SplatTable['SourceIdentifier'] = "$($computer)_Event"
                Write-Verbose "Creating monitoring event using defined parameters"
                $job = Register-WmiEvent @SplatTable
                Write-Verbose "Updating job name"
                $Job.Name = "$($Computer)_EventLogMonitor"
                
                If ($PSBoundParameters['Persistent']) {
                    #Configure the persistent job monitors
                    <#
                    Server connection monitor to restart jobs and events if server is rebooted
                    WMI eventing does not know how to restore connection if server is rebooted and 
                        does not throw an error if it drops connecton
                    #>
                    $J = Start-Job -Name "$($Computer)_Monitor" -ScriptBlock {
                        Param ($Server,$Active=$True,$Inactive=$True)
                        While ($Active) {
                            If (-Not (Test-Connection -ComputerName $Server -Count 1 -Quiet)) {
                                #Do not kill job yet until the server is back online to avoid unneeded job creations
                                While ($Inactive) {
                                    If ((Test-Connection -ComputerName $Server -Count 1 -Quiet)) {
                                        #Wait another 10 seconds for system to come up fully before creating WMI event job
                                        Start-Sleep -Seconds 10
                                        $Inactive = $False
                                    }
                                }
                                $Active = $False
                            } Else {
                                #Wait 5 seconds and check again
                                Start-Sleep -Seconds 5
                            }
                        }
                        Write-Output $Server
                    } -ArgumentList $Computer

                    Register-ObjectEvent -InputObject $j -EventName StateChanged -SourceIdentifier "$($Computer)_EventMonitor" -Action {
                        $Global:EventJob = $EventSubscriber
                        #Get servername
                        $Servername = $EventJob.SourceObject | Receive-Job
                        
                        #Pull information about server and its jobs
                        $Row = $Report | Where {
                            $_.Servername -eq $Servername
                        }
                        #Get query so we can re-use it in the new job
                        $WmiQuery = (Get-EventSubscriber -SourceIdentifier $Row.EventName).sourceobject.query.querystring
                        Unregister-Event -SourceIdentifier $Row.EventName
                        Remove-Job -Id $row.JobId
                        
                        #Perform cleanup
                        Write-Verbose ("Removing {0}" -f $EventJob.SourceObject)
                        Remove-Job $EventJob.SourceObject -Force
                        Write-Verbose ("Removing {0}" -f $EventJob.Action)
                        Remove-Job $EventJob.Action -Force
                        Write-Verbose ("Unregistering {0}" -f $EventJob.Action)
                        Unregister-Event $EventJob.SourceIdentifier
                        Write-Verbose ("Restarting event monitor for {0}" -f $Servername)
                         
                        Start-EventLogMonitor -Computername $Servername -Query $WmiQuery -Persistent                        
                    }                   
                }
                Write-Output $job
            } Else {
                Write-Warning ("{0}: Unable to connect!" -f $computer)
                If ($PSBoundParameters['Persistent']) {
                    $SplatTable['ComputerName'] = $computer
                    $SplatTable['Persistent'] = $True
                    Write-Verbose ("Attempting to restart job on {0}" -f $SplatTable['ComputerName'])
                    Start-Sleep -Seconds 5
                    Start-EventLogMonitor @SplatTable                
                    $SplatTable.Remove('Persistent')
                }
            }
        }#End ForEach     
    } #End Process
    End {
        Write-Verbose "Creating job report for event monitoring"   
        $Global:Report = New-JobStatusReport
    }
}#End Function
 
Function Stop-EventLogMonitor {
<#  
.SYNOPSIS  
    Clears the monitoring of events.  
    
.DESCRIPTION  
    Clears the monitoring of events.
    
.NOTES  
    Name: Stop-Monitor
    Author: Boe Prox
    DateCreated: 06/9/2011

.EXAMPLE
    Stop-Monitor
    
    Description
    -----------
    This command will remove all jobs and event subscriptions.   
          
#> 
    [cmdletbinding()]
    Param()
    Try {
        Write-Verbose "Stopping Event subscribers"    
        Get-EventSubscriber | Unregister-Event -Force -ErrorAction stop
        }
    Catch {
        Write-Warning "$($Error[0])"
        }       
    Try {
        Write-Verbose "Removing jobs"
        Get-Job | Remove-Job -Force -ErrorAction stop
        }
    Catch {
        Write-Warning "Unable to remove jobs!"
        }    
    }

Function Global:New-JobStatusReport {
    [cmdletbinding()]
    Param ()
    Begin {   
        Write-Verbose "Creating empty collection" 
        $Report = @()
    }
    Process {
        ForEach ($job in @(Get-EventSubscriber | Where {$_.EventName -eq 'EventArrived'})) {
            $Temp = "" | Select EventName,JobId,ServerName
            $Temp.EventName = $job.SourceIdentifier
            $Temp.ServerName = ($job.SourceIdentifier -split "_")[0]
            $Temp.JobId = $job.action.id
            Write-Verbose ("Adding {0} to report." -f $job.SourceIdentifier)
            $Report += $Temp
        }
    }
    End {
        Write-Output $report
    }
}

##Specific Event ID Functions
Function Get-SecurityEventID4624 {
    <#
        .Synopsis
            Parse EventID 4624 to view information for Account Logon
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4624) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                	SID = $_.InsertionStrings[4]
                	UserName = $_.InsertionStrings[5]
                	Domain = $_.InsertionStrings[6]
                	SourceIP = $_.InsertionStrings[18]
                	SourcePort = $_.InsertionStrings[19]
                	SourceName = $_.InsertionStrings[17]
                	LogonProcess = $_.InsertionStrings[9]
                	AuthenticationPackage = $_.InsertionStrings[10]
                	LogonType = $_.InsertionStrings[8]
                    DomainController = $_.ComputerName
                    LogFile = $_.logfile
                    Category = $_.CategoryString                    
                }
            }
        }
    }
}

##Specific Event ID Functions
Function Get-SecurityEventID4720 {
    <#
        .Synopsis
            Parse EventID 4720 to view information for Account Create
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4720) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    AccountCreated = $_.insertionstrings[0]
                    Domain = $_.insertionstrings[1]
                    CreatedBy = $_.insertionstrings[4]
                    CreatedBySID = $_.insertionstrings[3]
                    AccountSID = $_.insertionstrings[2]
                    samAccountName = $_.insertionstrings[8]
                    DisplayName = $_.insertionstrings[9]
                    UserPrincipleName = $_.insertionstrings[10]
                    HomeDirectory = $_.insertionstrings[11]
                    HomeDrive = $_.insertionstrings[12]
                    UserWorkstations = $_.insertionstrings[13]
                    ProfilePath = $_.insertionstrings[14]
                    PrimaryGroupID = $_.insertionstrings[18]
                    UserAccountControl = $_.insertionstrings[21]
                    LogFile = $_.logfile
                    Category = $_.CategoryString                    
                }
            }
        }
    }
}

##Specific Event ID Functions
Function Get-SecurityEventID4726 {
    <#
        .Synopsis
            Parse EventID 4726 to view information for Account Delete
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4726) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    AccountDeleted = $_.InsertionStrings[0]
                    DeletedBy = $_.InsertionStrings[4]
                    Domain = $_.InsertionStrings[1]
                    DeletedBySID = $_.InsertionStrings[3]
                    DeletedAccountSID = $_.InsertionStrings[2]
                    LogonID = $_.InsertionStrings[6]
                    LogFile = $_.logfile
                    Category = $_.CategoryString                    
                }
            }
        }
    }
}

Function Get-SecurityEventID4724 {
    <#
        .Synopsis
            Parse EventID 4724 to view information for Reset Password
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4724) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    TargetAccount = $_.insertionstrings[0]
                    Domain = $_.insertionstrings[1]
                    TargetAccountSID = $_.insertionstrings[2]
                    CaughtAccountSID = $_.insertionstrings[3] 
                    CaughtAccount = $_.insertionstrings[4]
                    LogonId = $_.insertionstrings[6]
                    LogFile = $_.logfile
                    Category = $_.CategoryString                    
                }
            }
        }
    }
}

Function Get-SecurityEventID4740 {
    <#
        .Synopsis
            Parse EventID 4740 to view information for Account Lockout
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4740) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    TargetAccount = $_.insertionstrings[0]
                    SourceWorkstation = $_.insertionstrings[1]
                    TargetAccountSID = $_.insertionstrings[2]
                    AuthenticationServerSID = $_.insertionstrings[3]
                    AuthenticationServer = $_.insertionstrings[4]
                    LogonID = $_.insertionstrings[6]
                    LogFile = $_.logfile
                    Category = $_.CategoryString
                }
            }
        }
    }
}

Function Get-SecurityEventID4767 {
    <#
        .Synopsis
            Parse EventID 4767 to view information for Account Unlock
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4767) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    LogFile = $_.logfile
                    Category = $_.CategoryString  
                    UnlockedAccount = $_.insertionstrings[0]                   
                    Domain = $_.insertionstrings[1]
                    SourceAccountSID = $_.insertionstrings[2]
                    UnlockedtAccountSID = $_.insertionstrings[3]
                    SourceAccount = $_.insertionstrings[4]
                    LogonID = $_.insertionstrings[6]

                }
            }
        }
    }
}

Function Get-SecurityEventID4725 {
    <#
        .Synopsis
            Parse EventID 4725 to view information for Account Disable
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4725) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    LogFile = $_.logfile
                    Category = $_.CategoryString  
                    Type = 'Account Disabled'
                    TargetAccount = $_.insertionstrings[0]                   
                    Domain = $_.insertionstrings[1]
                    SourceAccountSID = $_.insertionstrings[2]
                    TargetAccountSID = $_.insertionstrings[3]
                    SourceAccount = $_.insertionstrings[4]
                    LogonID = $_.insertionstrings[6]

                }
            }
        }
    }
}

Function Get-SecurityEventID4722 {
    <#
        .Synopsis
            Parse EventID 4722 to view information for Account Enabled
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4722) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    LogFile = $_.logfile
                    Category = $_.CategoryString  
                    Type = 'Account Enabled'
                    TargetAccount = $_.insertionstrings[0]                   
                    Domain = $_.insertionstrings[1]
                    SourceAccountSID = $_.insertionstrings[2]
                    TargetAccountSID = $_.insertionstrings[3]
                    SourceAccount = $_.insertionstrings[4]
                    LogonID = $_.insertionstrings[6]

                }
            }
        }
    }
}

Function Get-SecurityEventID4738 {
    <#
        .Synopsis
            Parse EventID 4738 to view information for Account Modification
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 4738) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    Type = 'Account Modified'
                    LogFile = $_.logfile
                    Category = $_.CategoryString 
                    TargetAccount = $_.insertionstrings[1]                   
                    TargetDomain = $_.insertionstrings[2]
                    TargetSID = $_.insertionstrings[3]
                    SourceSID = $_.insertionstrings[4]
                    SourceAccount = $_.insertionstrings[5]
                    SourceDomain = $_.insertionstrings[6]
                    LogonID = $_.insertionstrings[7]
                    PasswordLastSet = $_.insertionstrings[17]
                    DisplayName = $_.Insertionstrings[10]
                    ScriptPath = $_.Insertionstrings[14]
                    Expires = $_.Insertionstrings[18]
                    ProfilePath = $_.insertionstrings[15]
                }
            }
        }
    }
}

Function Get-SecurityEventID5136 {
    <#
        .Synopsis
            Parse EventID 5136 to view information for Directory Service Modified
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [System.Object]$InputObject
    )
    Process {
        $InputObject | ForEach {
            If ($_.EventCode -eq 5136) {
                New-Object PSObject -Property @{
                    EventId = $_.EventCode
                    TimeGenerated = (([wmiclass]"Root\Cimv2").ConvertToDateTime($_.TimeGenerated))
                    DomainController = $_.ComputerName
                    Type = 'Directory Service Modified'
                    LogFile = $_.logfile
                    Category = $_.CategoryString 
                    SourceAccount = $_.insertionstrings[3]
                    SourceSID = $_.insertionstrings[2]
                    SourceDomain = $_.insertionstrings[4]
                    LogonID = $_.insertionstrings[5]
                    DirectoryServiceName = $_.insertionstrings[6]
                    ObjectModified = $_.insertionstrings[8]
                    ObjectGUID = $_.insertionstrings[9]
                    ObjectClass = $_.insertionstrings[10]
                    LDAPDisplayName = $_.insertionstrings[11]
                    OIDSyntax = $_.insertionstrings[12]
                    Value = $_.insertionstrings[13]
                    ModificationType = Switch ($_.insertionstrings[14]) {
                        "%%14674" {"Value Added"}
                        "%%14675" {"Value Deleted"}
                        Default {$_}
                        }
                }
            }
        }
    }
}

#Export the functions from module
Export-ModuleMember -Function * 