$FileRetentionDefinitions = [PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Inbound\B2BOrders\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 30
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Inbound\B2COrders\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 14
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\B2BOrderStatus\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 14
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\B2BPricebook\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\Catalog\archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\Customyzer\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\Inventory\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\Invoices\archive"
    RetentionTimeSpan = New-TimeSpan -Days 60
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\OrderStatus\archive"
    RetentionTimeSpan = New-TimeSpan -Days 14
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\Pricebook\archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\EPS-DemandwareFTP\Outbound\Tax\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 60
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Inbound\B2BOrders\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 30
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Inbound\B2COrders\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 14
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\B2BOrderStatus\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 14
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\B2BPricebook\archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\Catalog\archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\Customyzer\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\Invoices\archive"
    RetentionTimeSpan = New-TimeSpan -Days 60
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\OrderStatus\archive"
    RetentionTimeSpan = New-TimeSpan -Days 14
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\PrdInventory\archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\Pricebook\archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\StgInventory\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 7
},
[PSCustomObject][Ordered]@{
    Path = "\\demandwareftp.tervis.com\PRD-DemandwareFTP\Outbound\Tax\Archive"
    RetentionTimeSpan = New-TimeSpan -Days 60
}