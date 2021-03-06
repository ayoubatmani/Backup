#
# These examples show how to define a set of functions for manipulating
# a "database" of information about comic book characters

#
# Define the basic database
$characterData = @{
  "Linus" = @{ age = 8; human = $true}
  "Lucy" = @{ age = 8; human = $true}
  "Snoopy" = @{ age = 2; human = $true}
}

#
# A function to get information about a character using
# pattern matching on the characters name
#
function Get-Character ($name = "*")
{
  foreach ($entry in $characterData.GetEnumerator() | Write-Object)
  {
    if ($entry.Key -like $name)
    {
        $properties = @{ "Name" = $entry.Key } +
          $entry.Value
        New-Object PSCustomObject -Property $properties
     }
  }
}

#
# A function to set character information
# using objects read from the input pipe
#
function Set-Character {
  process {
    $characterData[$_.name] =
      @{
        age = $_.age
        human = $_.human
      }
   }
}

function Update-Character (
  [string] $name = '*',
  [int] $age,
  [bool] $human
)
{
  begin
  {
    if ($PSBoundParameters."name")
    {
      $name = $PSBoundParameters.name
      [void] $PSBoundParameters.Remove("name")
    }
  }
  process
  {  
    if ($_.name -like $name)
    {
      foreach ($p in $PSBoundParameters.GetEnumerator())
      {
        $_.($p.Key) = $p.value
      }
    }
    $_
  }
}


#
# Some examples showing how these functions would be used.
#
Get-Character | Format-Table -auto
Get-Character |
  Update-Character -name snoopy -human $false |
   Format-Table -auto

Get-Character | Format-Table -auto
Get-Character |
  Update-Character -name snoopy -human $false |
  Set-Character
  
Get-Character | Format-Table -auto
Get-Character L* | Format-Table -auto
Get-Character Linus |
  Update-Character -age 7 |
  Set-Character

Get-Character | Format-Table -auto
