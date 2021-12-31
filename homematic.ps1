#!/usr/bin/env pwsh

$culture = New-Object CultureInfo("en-US")
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture

$conf = Get-Content "/etc/check_mk/homematic-checkmk.conf" | ConvertFrom-Json

$doc = New-Object System.Xml.XmlDocument
$doc.Load($conf.XMLUrl)

$Output = New-Object System.Collections.ArrayList($null)

function Get-DeviceItem($name) {
  $deviceitem = $Output | Where-Object { $_.name -eq $name }

  if ($null -eq $deviceitem) {
    $Output.Add([PSCustomObject]@{
      "name" = $name
      "data" = @{}
    }) | Out-Null

    return Get-DeviceItem($name)
  } else {
    return $deviceitem
  }
}

# Parse for ACTUAL_TEMPERATURE
$doc.stateList.device | Select-Xml -XPath "channel/datapoint" | Where-Object { $_.Node.type -eq 'ACTUAL_TEMPERATURE' } | Foreach-Object {
  $channel1 = $_.Node
  $device = $channel1.ParentNode.ParentNode

  (Get-DeviceItem($device.name)).data += @{"ACTUAL_TEMPERATURE" = $channel1.value}
}

# Parse for SET_POINT_TEMPERATURE
$doc.stateList.device | Select-Xml -XPath "channel/datapoint" | Where-Object { $_.Node.type -eq 'SET_POINT_TEMPERATURE' } | Foreach-Object {
  $channel1 = $_.Node
  $device = $channel1.ParentNode.ParentNode

  (Get-DeviceItem($device.name)).data += @{"SET_POINT_TEMPERATURE" = $channel1.value}
}

# Parse for HUMIDITY
$doc.stateList.device | Select-Xml -XPath "channel/datapoint" | Where-Object { $_.Node.type -eq 'HUMIDITY' } | Foreach-Object {
  $channel1 = $_.Node
  $device = $channel1.ParentNode.ParentNode

  (Get-DeviceItem($device.name)).data += @{"HUMIDITY" = $channel1.value}
}

#Parse for OPERATING_VOLTAGE
$doc.stateList.device | Select-Xml -XPath "channel/datapoint" | Where-Object { $_.Node.type -eq 'OPERATING_VOLTAGE' } | Foreach-Object {
  $channel1 = $_.Node
  $device = $channel1.ParentNode.ParentNode

  (Get-DeviceItem($device.name)).data += @{"OPERATING_VOLTAGE" = $channel1.value}
}

#Parse for LOW_BAT
$doc.stateList.device | Select-Xml -XPath "channel/datapoint" | Where-Object { $_.Node.type -eq 'LOW_BAT' } | Foreach-Object {
  $channel1 = $_.Node
  $device = $channel1.ParentNode.ParentNode

  (Get-DeviceItem($device.name)).data += @{"LOW_BAT" = $channel1.value}
}

$date = Get-Date

$Output | ForEach-Object {
  $retval = 0
  $metrics = @()
  $values = @()
  $_.data.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
    $Property = $_
    switch -regex ($Property.Name) {
      "^(ACTUAL_TEMPERATURE|SET_POINT_TEMPERATURE|HUMIDITY|OPERATING_VOLTAGE)$" {
        $metrics += ("{0}={1:n1}" -f $Property.Name, [convert]::ToDouble($Property.Value))
        $values += ("{0}={1:n1}" -f $Property.Name, [convert]::ToDouble($Property.Value))
      }
      "^(LOW_BAT)$" {
        $values += ("{0}={1:s}" -f $Property.Name, $Property.Value)

        if ($Property.Name -eq "LOW_BAT" -And $Property.Value -eq "true") {
          $retval = 2
        }
      }
    }
  }
  # $metrics
  # $values
  # $values = ($_.data.GetEnumerator() | Sort-Object -Property Name | ForEach-Object { ("{0}={1:n1}" -f $_.Name, [convert]::ToDouble($_.Value)) })
  Write-Output ('{0} "{1}" {2} {3} - Data updated at: {4}' -f $retval, $_.name, ($metrics -join "|"), ($values -join " "), $date)
}
