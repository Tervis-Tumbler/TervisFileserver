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

$DemandwareFTPDFSRGroupDefinitions =[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Inbound\B2BOrders"
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Inbound\B2BOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Inbound\B2COrders"  
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Inbound\B2COrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Inbound\GMAOrders"  
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Inbound\GMAOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Inbound\PromoOrders"
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Inbound\PromoOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\B2BOrderStatus"
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\B2BOrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\B2BPricebook"  
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\B2BPricebook"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\Catalog"       
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\Catalog"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\Customyzer"    
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\Customyzer"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\Invoices"      
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\Invoices"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\OrderStatus"   
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\OrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\PrdInventory"  
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\PrdInventory"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\Pricebook"     
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\Pricebook"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\StgInventory"  
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\StgInventory"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\Stores"        
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\Stores"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\PRD-DemandwareFTP\Outbound\Tax"      
    DestinationPath = "\\tervis.prv\applications\Demandware\PRD\Outbound\Tax"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Inbound\B2BOrders"  
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Inbound\B2BOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Inbound\B2COrders"  
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Inbound\B2COrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Inbound\GMAOrders"  
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Inbound\GMAOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Inbound\PromoOrders"     
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Inbound\PromoOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\B2BOrderStatus"   
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\B2BOrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\B2BPricebook"     
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\B2BPricebook"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\Catalog"          
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\Catalog"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\Customyzer"       
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\Customyzer"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\DevB2BOrderStatus"
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\DevB2BOrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\DevOrderStatus"   
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\DevOrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\Inventory"        
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\Inventory"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\Invoices"         
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\Invoices"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\OrderStatus"      
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\OrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\Pricebook"        
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\Pricebook"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\Stores"           
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\Stores"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\EPS-DemandwareFTP\Outbound\Tax"        
    DestinationPath = "\\tervis.prv\applications\Demandware\SIT\Outbound\Tax"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Inbound\B2COrders" 
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Inbound\B2COrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Inbound\GMAOrders"  
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Inbound\GMAOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Inbound\PromoOrders"
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Inbound\PromoOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\B2BOrderStatus"
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\B2BOrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\B2BPricebook"  
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\B2BPricebook"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\Catalog"       
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\Catalog"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\Customyzer"    
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\Customyzer"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Inbound\B2BOrders"  
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Inbound\B2BOrders"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\Inventory"     
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\Inventory"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\Invoices"      
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\Invoices"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\OrderStatus"   
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\OrderStatus"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\PrdInventory"  
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\PrdInventory"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\Pricebook"     
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\Pricebook"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\StgInventory"  
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\StgInventory"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\Stores"        
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\Stores"
},
[PSCustomObject]@{
    SourcePath = "\\p-ftp\DLT-DemandwareFTP\Outbound\Tax"           
    DestinationPath = "\\tervis.prv\applications\Demandware\DEV\Outbound\Tax"
}