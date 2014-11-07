

# Below is a basic script to grab the API service catalog

$userid = "smbmarquee1" #place the user account here

$apiKey = "3158aea1394d20c5ada8353fa3465e31" #place the account’s API key here.

 

$identity = "https://identity.api.rackspacecloud.com/v2.0/tokens"

$creds = @{"auth" = @{"RAX-KSKEY:apiKeyCredentials" =  @{"username" = $userid; "apiKey" = $apiKey}}} | convertTo-Json –depth 2

$catalog = Invoke-RestMethod -Uri $identity -Method POST -Body $creds -ContentType "application/json"

$authToken = @{"X-Auth-Token"=$catalog.access.token.id}

$catalog.access.serviceCatalog #shows the list of current API endpoints.



# List Servers

$DCs = "DFW",'ORD','IAD','hkg','syd'
Foreach ($DC in $DCs)
    {
    $region = $DC
    write-host `n`n`n $DC
$Suri = (($catalog.access.serviceCatalog | where name -like "*ServersO*").endpoints | Where region -like $region ).publicURL + "/servers"
$Servers = irm -uri $Suri -Method get -Headers $authToken -ContentType application/json
$Servers.servers.name
    }
###

# List Flavors 
$Fimage = (($catalog.access.serviceCatalog | where name -like "*serversO*").endpoints | Where region -like "DFW" ).publicURL + "/flavors"
$Fla = (irm -Uri $Simage -Method get  -Headers $authToken).flavors 

$Simage = (($catalog.access.serviceCatalog | where name -like "*Images*").endpoints | Where region -like "DFW" ).publicURL + "/images"
$Img = (irm -Uri $Simage -Method get  -Headers $authToken).images | where name -like "*Windows*"


# Create Server in DFW
$Suri = (($catalog.access.serviceCatalog | where name -like "*ServersO*").endpoints | Where region -like "HKG" ).publicURL + "/servers"
$Sduri = (($catalog.access.serviceCatalog | where name -like "*ServersO*").endpoints | Where region -like "HKG" ).publicURL + "/servers/detail"
$region = "DFW"
$body = @{server = @{name = 'msw-test'; flavorRef = 'performance1-4'; imageRef = "f71b8606-582f-4f5c-8659-b7bc064b0e44" } } | convertto-json -Depth 30

$new = (irm -uri $Suri -method POST -body $Body -Headers $authToken -ContentType application/json)
$building =  ((irm -uri $Sduri -Method get -Headers $authToken -ContentType application/json).servers | Where id -like $new.server.id )
$new.server.id 


While ($building.status -ne "Active")
{
write-host Building
sleep 20
$building =  ((irm -uri $Suri -Method get -Headers $authToken -ContentType application/json).servers | Where id -like $new.server.id )
}
write-host $new.server.id `n $new.server.adminpass `n $new.server.name


# Create image of all msw-test servers

$Serverlist = ((irm -uri $Sduri -Method get -Headers $authToken -ContentType application/json).servers | Where name -like "msw-test" )

foreach ($server in $serverlist) 
    {
    $serverid = $server.id
    $SID = (($catalog.access.serviceCatalog | where name -like "*ServersO*").endpoints | Where region -like "HKG" ).publicURL + "/servers/$serverid/action"
    $imbody = @{createImage = @{name = "imagetest"} } | convertto-json -Depth 30
    irm -uri $SID -headers $authToken -Method POST -body $imbody -ContentType application/json 


    }
    $imgs = (($catalog.access.serviceCatalog | where name -like "*ServersO*").endpoints | Where region -like "HKG" ).publicURL + "/images/detail"
    $img = (irm -uri $imgs -headers $authToken -Method get -ContentType application/json) 
    ($Img.images | ? name -like "*test*").status


# Delete everything


 $ImgIDs = ($Img.images | ? name -like "*test*").id

 foreach ($ImgID in $ImgIDs)
    {
    $DelImgUri = (($catalog.access.serviceCatalog | where name -like "*ServersO*").endpoints | Where region -like "HKG" ).publicURL + "/images/" + $ImgID
    irm -uri $DelImgUri -headers $authToken -Method DELETE -ContentType application/json
    write-host Deleted $ImgID
    }

$Serverlist = ((irm -uri $Sduri -Method get -Headers $authToken -ContentType application/json).servers | Where name -like "msw-test" )

foreach ($server in $serverlist) 
    {
    $serverid = $server.id
    $SID = (($catalog.access.serviceCatalog | where name -like "*ServersO*").endpoints | Where region -like "HKG" ).publicURL + "/servers/$serverid"
    irm -uri $SID -headers $authToken -Method DELETE -ContentType application/json 
    }

