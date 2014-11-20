

Add-Type @"
public class itemData
{
	public string Item {get;set;}
	public string Revision {get;set;}
	public string Title {get;set;}
	public string Category {get;set;}
	public string State {get;set;}
}
"@


function OnTabContextChanged_Item
{
	$xamlFile = [System.IO.Path]::GetFileName($VaultContext.UserControl.XamlFile)
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "Item.xaml")
	{
		$fileMasterId = $vaultContext.SelectedObject.Id
		$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
		$items = $vault.ItemService.GetItemsByFileId($file.Id)
		$item = $items[0]
		SetItemData -itemId $item.id
		SetItemBomData -itemId $item.id
	}
}

function SetItemData($itemId)
{
	$dsDiag.Trace(">> SetItemData($fileId)")
	
	$properyDefinitions = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("ITEM")
	$properties = $vault.PropertyService.GetPropertiesByEntityIds("ITEM",$itemId)
	$props = @{}
	foreach ($property in $properties) {
		$propDef = $properyDefinitions | Where-Object { $_.Id -eq $property.PropDefId }
		$props[$propDef.DispName] = $property.Val
	}
	$item = New-Object itemData
	$item.Item = $props["Number"]
	$item.Revision = $props["Revision"]
	$item.Title = $props["Title (Item,CO)"]
	$item.State = $props["State"]
	$item.Category = $props["Category Name"]
	
	$dsWindow.FindName("ItemData").DataContext = $item
	$dsDiag.Trace("<< SetItemData")
}


function SetItemBomData($itemId)
{
	$dsDiag.Trace("<< SetItemBomData($itemId)")
	$BOM = $vault.ItemService.GetItemBOMByItemIdAndDate($itemId, [DateTime]::MinValue, [Autodesk.Connectivity.WebServices.BOMTyp]::Tip, [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::Defaults)
	$assocs =  $BOM.ItemAssocArray | Where-Object { $_.ParItemId -eq $itemId }
	$childIds = $assocs | ForEach-Object { $_.CldItemId	}
	
	$properyDefinitions = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("ITEM")
	$properties = $vault.PropertyService.GetPropertiesByEntityIds("ITEM",$childIds)
	
	$data = @()
	foreach ($id in $childIds) {
		$props = @{}
		$ppys = $properties | Where-Object { $_.EntityId -eq $id }
		foreach ($property in $ppys) {
			$propDef = $properyDefinitions | Where-Object { $_.Id -eq $property.PropDefId }
			$props[$propDef.DispName] = $property.Val
		}
		
		$item = New-Object itemData
		$item.Item = $props["Number"]
		$item.Revision = $props["Revision"]
		$item.Title = $props["Title (Item,CO)"]
		$item.State = $props["State"]
		$item.Category = $props["Category Name"]
		$data += $item
	}
	$dsWindow.FindName("bomList").ItemsSource = $data
	$dsDiag.Trace("<< SetItemBomData")
}


