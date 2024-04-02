
<#------------- CONNECT TO SWIS -------------#>
# load the snappin if it's not already loaded (step 1)
if (!(Get-PSSnapin | Where-Object { $_.Name -eq "SwisSnapin" })) {
    Add-PSSnapin "SwisSnapin"
}

#define target host and credentials

$hostname = 'localhost'
#$user = "admin"
#$password = "password"
# create a connection to the SolarWinds API
#$swis = connect-swis -host $hostname -username $user -password $password -ignoresslerrors
$swis = Connect-Swis -Hostname $hostname -Trusted



<#------------- ACTUAL SCRIPT -------------#>
##### Phase 1 - Create groups tree #######



#########get SiteCode list
$SiteCode = get-swisdata $swis @"
select distinct n.CustomProperties.SiteCode
from orion.nodes n 
left join orion.Container c on c.name = n.CustomProperties.SiteCode
where n.CustomProperties.SiteCode is not null and n.CustomProperties.SiteCode not in ('') 
order by n.CustomProperties.SiteCode
"@

foreach($site in $SiteCode)
    {
    #get groupid for parent folder
    $parent = get-swisdata $swis "select top 1 containerid from orion.container where name='SiteCode'"

    $sitecheck = get-swisdata $swis "select containerid from orion.container where name = '$site'"
    if(!$sitecheck)         {
            "   Creating group for $site"
            $members = @(
    	        )
            $siteid = (invoke-swisverb $swis "orion.container" "CreateContainerWithParent" @(
            "$parent",
            "$site",
            "Core",
            300,
            0,
            "$site"
            "true",
            ([xml]@("<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>",
	        [string]($members |% {
    	        "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
    		        } 
            ),
            "</ArrayOfMemberDefinitionInfo>"
            )).DocumentElement 
            )).innertext 
        }
    else
        {
            "   $site already exists"
        }




############get components list
$roles = @("IBX")

    foreach($role in $roles)
   	    {

        #get groupid for parent folder
        $parent = get-swisdata $swis "select top 1 containerid from orion.container where name='$site'"

        $rolecheck = get-swisdata $swis "select containerid from orion.container where name = '$site $role'"
        if($rolecheck.length -eq 0)
            {
                
                "    Creating group for $role"
                $members = @(
    	    	    @{ Name = "$role Nodes"; Definition = "filter:/Orion.Nodes[Contains(Caption,'$role') AND Contains(Caption,'$site')]" }
    	        )
                $envid = (invoke-swisverb $swis "orion.container" "CreateContainerWithParent" @(
                "$parent",
                "$site $role",
                "Core",
                300,
                0,
                "$site $role",
                "true",
                ([xml]@("<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>",
	            [string]($members |% {
    	            "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
    		            } 
                ),
                "</ArrayOfMemberDefinitionInfo>"
                )).DocumentElement 
                )).innertext 
            }
        else
            {
                "    $site $role already exists"
            }
        }
    }
