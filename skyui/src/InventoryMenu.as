﻿import gfx.io.GameDelegate;
import Shared.GlobalFunc;
import gfx.ui.NavigationCode;

class InventoryMenu extends ItemMenu
{
	// TODO: Use real types once we include them
	var bMenuClosing:Boolean;
	var bFadedIn:Boolean;
	var bPCControlsReady = true;

	var EquipButtonArt:Object;
	var AltButtonArt:Object;
	var ChargeButtonArt:Object;
	var ItemCardListButtonArt:Object;
	var PrevButtonArt:Object;
	var InventoryLists_mc:MovieClip;
	var BottomBar_mc:MovieClip;
	var ItemCard_mc:MovieClip;
	
	
	function InventoryMenu()
	{
		super();
		bMenuClosing = false;
		EquipButtonArt = {PCArt:"M1M2", XBoxArt:"360_LTRT", PS3Art:"PS3_LBRB"};
		AltButtonArt = {PCArt:"E", XBoxArt:"360_A", PS3Art:"PS3_A"};
		ChargeButtonArt = {PCArt:"T", XBoxArt:"360_RB", PS3Art:"PS3_RT"};
		ItemCardListButtonArt = [{PCArt:"Enter", XBoxArt:"360_A", PS3Art:"PS3_A"}, {PCArt:"Tab", XBoxArt:"360_B", PS3Art:"PS3_B"}];
		PrevButtonArt = undefined;
	}

	function InitExtensions()
	{
		super.InitExtensions();
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu InitExtensions()");
		GlobalFunc.AddReverseFunctions();
		InventoryLists_mc.ZoomButtonHolderInstance.gotoAndStop(1);
		BottomBar_mc.SetButtonArt(ChargeButtonArt,3);
		GameDelegate.addCallBack("AttemptEquip",this,"AttemptEquip");
		GameDelegate.addCallBack("DropItem",this,"DropItem");
		GameDelegate.addCallBack("AttemptChargeItem",this,"AttemptChargeItem");
		GameDelegate.addCallBack("ItemRotating",this,"ItemRotating");

		ItemCard_mc.addEventListener("itemPress",this,"onItemCardListPress");
	}

	function handleInput(details, pathToFocus)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu handleInput()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("InventoryMenu handleInput() details = " + details.navEquivalent + ", object = " + details);
		if (bFadedIn && !pathToFocus[0].handleInput(details, pathToFocus.slice(1)))
		{
			if (GlobalFunc.IsKeyPressed(details))
			{
				if (details.navEquivalent == NavigationCode.TAB)
				{
					StartMenuFade();
					GameDelegate.call("CloseTweenMenu",[]);
				}
			}
		}
		return true;
	}

	function onExitMenuRectClick()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onExitMenuRectClick()");
		StartMenuFade();
		GameDelegate.call("ShowTweenMenu",[]);
	}

	function StartMenuFade()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu StartMenuFade()");
		InventoryLists_mc.HideCategoriesList();
		ToggleMenuFade();
		SaveIndices();
		bMenuClosing = true;
	}

	function onFadeCompletion()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onFadeCompletion()");
		if (bMenuClosing)
		{
			GameDelegate.call("CloseMenu",[]);
		}
	}

	function onShowItemsList(event)
	{
		super.onShowItemsList(event);
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onShowItemsList()");
		if (event.index != -1)
		{
			UpdateBottomBarButtons();
		}
	}

	function onItemHighlightChange(event)
	{
		super.onItemHighlightChange(event);
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemHighlightChange()");
		if (event.index != -1)
		{
			UpdateBottomBarButtons();
		}
	}

	function UpdateBottomBarButtons()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu UpdateBottomBarButtons()");
		BottomBar_mc.SetButtonArt(AltButtonArt,0);
		switch (ItemCard_mc.itemInfo.type)
		{
			case InventoryDefines.ICT_ARMOR :
				{
					BottomBar_mc.SetButtonText("$Equip",0);
				break;
			} ;
			case InventoryDefines.ICT_BOOK :
				{
					BottomBar_mc.SetButtonText("$Read",0);
				break;
			} ;
			case InventoryDefines.ICT_POTION :
				{
					BottomBar_mc.SetButtonText("$Use",0);
				break;
			} ;
			case InventoryDefines.ICT_FOOD :
			case InventoryDefines.ICT_INGREDIENT :
				{
					BottomBar_mc.SetButtonText("$Eat",0);
				break;
			} ;
			default :
				{
					BottomBar_mc.SetButtonArt(EquipButtonArt,0);
					BottomBar_mc.SetButtonText("$Equip",0);
				break;
			}
		};

		BottomBar_mc.SetButtonText("$Drop",1);
		if ((InventoryLists_mc.ItemsList.selectedEntry.filterFlag & InventoryLists_mc.CategoriesList.entryList[0].flag) != 0)
		{
			BottomBar_mc.SetButtonText("$Unfavorite",2);
		}
		else
		{
			BottomBar_mc.SetButtonText("$Favorite",2);
		}

		if (ItemCard_mc.itemInfo.charge != undefined && ItemCard_mc.itemInfo.charge < 100)
		{
			BottomBar_mc.SetButtonText("$Charge",3);
		}
		else
		{
			BottomBar_mc.SetButtonText("",3);
		}
	}

	function onHideItemsList(event)
	{
		super.onHideItemsList(event);
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onHideItemsList()");
		BottomBar_mc.UpdatePerItemInfo({type:InventoryDefines.ICT_NONE});
	}

	function onItemSelect(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemSelect()");
		if (event.entry.enabled && event.keyboardOrMouse != 0)
		{
			GameDelegate.call("ItemSelect",[]);
		}
	}

	function AttemptEquip(aiSlot, abCheckOverList)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu AttemptEquip()");
		var _loc2 = abCheckOverList != undefined ? (abCheckOverList) : (true);
		if (ShouldProcessItemsListInput(_loc2) && ConfirmSelectedEntry())
		{
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("InventoryMenu AttemptEquip() ItemSelect");
			GameDelegate.call("ItemSelect",[aiSlot]);
		}
	}

	// Added to prevent clicks on the scrollbar from equipping/using stuff
	function ConfirmSelectedEntry():Boolean
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu ConfirmSelectedEntry()");
		// only confirm when using mouse
		if (iPlatform != 0) {
			return true;
		}
		
		for (var e = Mouse.getTopMostEntity(); e && e != undefined; e = e._parent) {
			if (e.itemIndex == InventoryLists_mc.ItemsList.selectedIndex) {
				return true;
			}
		}
		return false;
	}

	function DropItem()
	{
                if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu DropItem()");
		if (ShouldProcessItemsListInput(false) && InventoryLists_mc.ItemsList.selectedEntry != undefined) {
			if (InventoryLists_mc.ItemsList.selectedEntry.count <= InventoryDefines.QUANTITY_MENU_COUNT_LIMIT) {
						onQuantityMenuSelect({amount:1});
			} else {
				ItemCard_mc.ShowQuantityMenu(InventoryLists_mc.ItemsList.selectedEntry.count);
			}
		}
	}

	function AttemptChargeItem() {
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu AttemptChargeItem()");
		if (ShouldProcessItemsListInput(false) && ItemCard_mc.itemInfo.charge != undefined && ItemCard_mc.itemInfo.charge < 100)
		{
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("InventoryMenu AttemtChargeItem() GameDelegate.call ShowSoulGemList");
			GameDelegate.call("ShowSoulGemList",[]);
		}
	}

	function onQuantityMenuSelect(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onQuantityMenuSelect()");
		GameDelegate.call("ItemDrop",[event.amount]);
		
		// Bug Fix: ItemCard does not update when attempting to drop quest items through the quantity menu
		//			so let's request an update even though it may be redundant.
		GameDelegate.call("RequestItemCardInfo",[],this,"UpdateItemCardInfo");
	}

	function onMouseRotationFastClick(aiMouseButton)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onMouseRotationFastClick()");
		GameDelegate.call("CheckForMouseEquip",[aiMouseButton],this,"AttemptEquip");
	}

	function onItemCardListPress(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemCardListPress()");
		GameDelegate.call("ItemCardListCallback",[event.index]);
	}

	function onItemCardSubMenuAction(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemCardSubMenuAction()");
		super.onItemCardSubMenuAction(event);
		GameDelegate.call("QuantitySliderOpen",[event.opening]);
		if (event.menu == "list")
		{
			if (event.opening == true)
			{
				PrevButtonArt = BottomBar_mc.GetButtonsArt();
				BottomBar_mc.SetButtonsText("$Select","$Cancel");
				BottomBar_mc.SetButtonsArt(ItemCardListButtonArt);
			}
			else
			{
				BottomBar_mc.SetButtonsArt(PrevButtonArt);
				PrevButtonArt = undefined;
				GameDelegate.call("RequestItemCardInfo",[],this,"UpdateItemCardInfo");
				UpdateBottomBarButtons();
			}
		}
	}

	function SetPlatform(aiPlatform, abPS3Switch)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu SetPlatform()");
		InventoryLists_mc.ZoomButtonHolderInstance.gotoAndStop(1);
		InventoryLists_mc.ZoomButtonHolderInstance.ZoomButton._visible = aiPlatform != 0;
		InventoryLists_mc.ZoomButtonHolderInstance.ZoomButton.SetPlatform(aiPlatform,abPS3Switch);
		super.SetPlatform(aiPlatform,abPS3Switch);
	}

	function ItemRotating()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu ItemRotating()");
		InventoryLists_mc.ZoomButtonHolderInstance.PlayForward(InventoryLists_mc.ZoomButtonHolderInstance._currentframe);
	}
}
