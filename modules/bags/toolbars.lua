-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...

---@class BagsModule
local module = LUI:GetModule("Bags")

local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GetInventorySlotInfo = _G.GetInventorySlotInfo
local PickupBagFromSlot = _G.PickupBagFromSlot
local PutItemInBag = _G.PutItemInBag
local ResetCursor = _G.ResetCursor

--luacheck: globals PaperDollItemSlotButton_OnEvent PaperDollItemSlotButton_OnShow PaperDollItemSlotButton_OnHide
--luacheck: globals BagSlotButton_OnEnter BankFrameItemButton_OnEnter BankFrameItemButtonBag_OnClick

-- ####################################################################################################################
-- ##### Toolbar Mixin ################################################################################################
-- ####################################################################################################################
-- Toolbars is the generic names for any bar that will be around the main container frame.
-- The primary toolbars will be the BagBar and the Utility Bar

---@class ToolbarMixin
---@field slotList ItemButton[] @ Array containing all current slots for toolbar
---@field nextIndex number @ Index of the next slot to be created
---@field container ContainerMixin
---@field background Frame
local ToolbarMixin = {}

function ToolbarMixin:SetAnchors()
	local padding = self.container:GetOption("Padding")
	local spacing = self.container:GetOption("Spacing")
	local previousAnchor, firstAnchor
	for i = 1, #self.slotList do
		local slot = self.slotList[i]
		slot:ClearAllPoints()

		if not slot.hidden then
			slot:Show()
			if not previousAnchor then -- first slot
				slot:SetPoint("TOPLEFT", self, "TOPLEFT", padding, -padding)
				previousAnchor = slot
				firstAnchor = slot
			else
				slot:SetPoint("LEFT", previousAnchor, "RIGHT", spacing, 0)
				previousAnchor = slot
			end
		else
			slot:Hide()
		end
	end

	self.background:SetPoint("LEFT", firstAnchor, "LEFT", -padding, 0)
	self.background:SetPoint("TOP", firstAnchor, "TOP", 0, padding)
	self.background:SetPoint("BOTTOM", firstAnchor, "BOTTOM", 0, -padding)
	self.background:SetPoint("RIGHT", previousAnchor, "RIGHT", padding, 0)

	self:SetSize(self.background:GetWidth(), self.background:GetHeight())
	self:Show()
end

---	Simple function to add a new button to the toolbar.
---@param newButton Frame
function ToolbarMixin:AddNewButton(newButton)
	self.slotList[self.nextIndex] = newButton
	self.nextIndex = self.nextIndex + 1
end

function ToolbarMixin:ShowButton(button)
	button.hidden = false
	self:SetAnchors()
end

function ToolbarMixin:HideButton(button)
	button.hidden = true
	self:SetAnchors()
end

function ToolbarMixin:SetButtonTooltip(button, text)
	button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(button)
			GameTooltip:SetText(text)
			GameTooltip:Show()
		end)
	button:SetScript("OnLeave", _G.GameTooltip_Hide)
end

--- Create a toolbar for a given container
---@param container ContainerMixin
---@param name string
function module:CreateToolBar(container, name)
	local toolBar = CreateFrame("Frame", nil, container)
	toolBar:SetClampedToScreen(true)
	toolBar:SetSize(1,1)

	local bgFrame = CreateFrame("Frame", nil, toolBar, "BackdropTemplate")
	--Force it to the lowest frame level to prevent layering issues
	bgFrame:SetFrameLevel(toolBar:GetParent():GetFrameLevel())
	bgFrame:SetClampedToScreen(true)

	bgFrame:SetBackdrop(module.bagBackdrop)
	bgFrame:SetBackdropColor(module:RGBA("Background"))
	bgFrame:SetBackdropBorderColor(module:RGBA("Border"))

	toolBar.slotList = {}
	toolBar.nextIndex = 1
	toolBar.container = container
	toolBar.background = bgFrame
	container.toolbars[name] = toolBar
	if not container[name] then
		container[name] = toolBar
	end

	return Mixin(toolBar, ToolbarMixin)
end

--[[
	function PaperDollItemSlotButton_OnLoad(self)
		self:RegisterForDrag("LeftButton");
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		
		local slotName = PaperDollItemSlotButton_GetSlotName(self);
		local id, textureName, checkRelic = GetInventorySlotInfo(slotName);
		self:SetID(id);
		local texture = self.icon;
		texture:SetTexture(textureName);
		self.backgroundTextureName = textureName;
		self.checkRelic = checkRelic;
		self.UpdateTooltip = PaperDollItemSlotButton_OnEnter;
		itemSlotButtons[id] = self;
		self.verticalFlyout = VERTICAL_FLYOUTS[id];
		local popoutButton = self.popoutButton;
		if ( popoutButton ) then
			if ( self.verticalFlyout ) then
				popoutButton:SetHeight(16);
				popoutButton:SetWidth(38);
				popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0.5, 0);
				popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 1, 0.5);
				popoutButton:ClearAllPoints();
				popoutButton:SetPoint("TOP", self, "BOTTOM", 0, 4);
			else
				popoutButton:SetHeight(38);
				popoutButton:SetWidth(16);
				popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0);
				popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5);
				popoutButton:ClearAllPoints();
				popoutButton:SetPoint("LEFT", self, "RIGHT", -8, 0);
			end
		end
	end

function BaseBagSlotButtonMixin:OnLoadInternal()
	PaperDollItemSlotButton_OnLoad(self);
	self:RegisterForClicks("AnyUp");
	self:RegisterEvent("BAG_UPDATE_DELAYED");
	self:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	self.isBag = 1;
	self.maxDisplayCount = 999;
	self.UpdateTooltip = self.BagSlotOnEnter;
	self.Count:ClearAllPoints();
	self.Count:SetPoint("BOTTOMRIGHT", -2, 2);
	self:RegisterBagButtonUpdateItemContextMatching();
end
function BaseBagSlotButtonMixin:BagSlotOnEvent(event, ...)
	if event == "ITEM_PUSH" then
		local bagSlot, iconFileID = ...;
		if self:GetID() == bagSlot then
			self.AnimIcon:SetTexture(iconFileID);
			self.FlyIn:Play(true);
		end
	elseif event == "BAG_UPDATE_DELAYED" then
		PaperDollItemSlotButton_Update(self);
	elseif event == "INVENTORY_SEARCH_UPDATE" then
		self:SetMatchesSearch(not IsContainerFiltered(self:GetBagID()));
	else
		PaperDollItemSlotButton_OnEvent(self, event, ...);
	end
end
]]

-- ####################################################################################################################
-- ##### Templates: BagBar Slot Button ################################################################################
-- ####################################################################################################################
-- The end goal should be an identical button for Bags and Bank bars, without directly using Blizzard code.
-- This is to avoid potential taint. Bags and Bank use different APIs sometimes.
-- Note: Probably good idea to replace button with bagsSlot

--- Create an ItemButton specific to the BagBar
---@param index number
---@param id number
---@param name string
---@param parent Frame @ Should be a container's BagBar.
---@return ItemButton
function module:BagBarSlotButtonTemplate(index, id, name, parent)
	-- TODO: Clean up and make more uniform, stop relying on Blizzard API.
	local button = module:CreateSlot(name, parent)
	button.isBag = 1 -- Blizzard API support
	button.id = id
	button.index = index
	button.container = parent:GetParent().name

	button:RegisterForDrag("LeftButton")
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterBagButtonUpdateItemContextMatching()

	button:SetScript("OnClick", function(self) PutItemInBag(self.inventoryID) end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
		ResetCursor()
	end)

	--Try to have as few type-specific settings as possible
	if button.container == "Bags" then

		--(1)
		--PaperDollItemSlotButton_OnLoad
		--slotName uses id - 1 due to Bag1-4 are refered as Bag0-Bag3
		local slotName = string.format("BAG%dSLOT", index)
		LUI:Print("BagSlot", index, id, slotName)
		--local inventoryID, textureName = GetInventorySlotInfo(slotName)
		button.inventoryID = C_Container.ContainerIDToInventoryID(id)
		button:SetID(button.inventoryID)

		local texture = _G[name.."IconTexture"]
		local textureName = GetInventoryItemTexture("player", button.inventoryID)
		texture:SetTexture(textureName)
		button.backgroundTextureName = textureName

		--Rest of BagSlotTemplate OnLoad
		button:RegisterEvent("BAG_UPDATE_DELAYED")
		--button:RegisterEvent("INVENTORY_SEARCH_UPDATE")

		button.UpdateTooltip = BagSlotButton_OnEnter
		button.IconBorder:SetTexture("")
		button.IconBorder:SetSize(1,1)

		--TODO: Remove PaperDoll calls
		--BagSlotTemplate other events, unchecked.
		button:SetScript("OnEvent", function(self, event, ...)
			if event == "BAG_UPDATE_DELAYED" then
				_G.PaperDollItemSlotButton_Update(self)
				self:SetBackdropBorderColor(module:RGBA("Border"))
			else
				PaperDollItemSlotButton_OnEvent(self, event, ...)
			end
		end)
		-- OnShow/OnHide are just a bunch of update
		button:SetScript("OnShow", PaperDollItemSlotButton_OnShow)
		button:SetScript("OnHide", PaperDollItemSlotButton_OnHide)
		button:SetScript("OnDragStart", function(self) PickupBagFromSlot(self.inventoryID) end)
		button:SetScript("OnReceiveDrag", function(self) PutItemInBag(self.inventoryID) end)
		button:SetScript("OnEnter", BagSlotButton_OnEnter)
	elseif button.container == "Bank" then
		button:SetID(id-5)
		button.invSlotName = "BAG"..id-5
		button.GetInventorySlot = _G.ButtonInventorySlot;
		button.UpdateTooltip = _G.BankFrameItemButton_OnEnter
		button.inventoryID = button:GetInventorySlot()

		button:SetScript("OnEvent", function(self, event)
			if event == "BAG_UPDATE_DELAYED" then
				module:BankBagButtonUpdate(self)
			end
			-- Triggers when purchasing bank slots
			if event == "PLAYERBANKBAGSLOTS_CHANGED" then
				LUIBank:Layout()
			end
		end)
		button:SetScript("OnDragStart", _G.BankFrameItemButtonBag_Pickup)
		button:SetScript("OnReceiveDrag", _G.BankFrameItemButtonBag_OnClick)
		button:SetScript("OnEnter", _G.BankFrameItemButton_OnEnter)

		button:SetScript("OnShow", function(self)
			module:BankBagButtonUpdate(self)
		end)

		--BankFrameItemButton_Update(button)
		module:BankBagButtonUpdate(button)
		_G.BankFrameItemButton_UpdateLocked(button)
		button.tooltipText = button.tooltipText or ""
	end

	return button
end

function module:BankBagButtonUpdate(button)
	local texture = button.icon
	local textureName = GetInventoryItemTexture("player", button.inventoryID)
	LUI:Print("BankBagUpdate", "BAG"..button.invSlotName)
	local _, slotTextureName = GetInventorySlotInfo(button.invSlotName)

	if textureName then
		texture:SetTexture(textureName)
	elseif slotTextureName then
		--If no bag texture is found, show empty slot.
		texture:SetTexture(slotTextureName)
	end

	button:SetBackdropBorderColor(module:RGBA("Border"))

	texture:Show()
end
