-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@class LUI.Bags
local module = Opt.LUI:GetModule("ActionBars")
if not module or not module.registered then return end
local db = module.db.profile

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

local ActionBars = Opt:CreateModuleOptions("ActionBars", module, true)
ActionBars.args =  {

}
