$dnsserver = ${194.0.1.18}
$recordlookup =  $args[0]

try{
    $ResolvedName = Resolve-DnsName -Server $dnsserver -Name $recordlookup -ErrorAction Stop
    if($ResolvedName)
    {
        $Address = $ResolvedName.IP4Address
        write-host "Message: $recordlookup returned the value $Address"
        write-host "Statistic: 1"
    }
}
catch{
    write-host "Message: $recordlookup failed DNS resolution"
    write-host "Statistic: 0"
}
