
-- loganalytics
-- a simple wrapper around analytics service's bad api, that makes it into a decent api

local AnalyticsService = game:GetService("AnalyticsService")

type BaseAnalyticsInfo = {
	custom_fields: { [string]: string }?
}

type AnalyticsOnboardingFunnelStepInfo = BaseAnalyticsInfo & {
	step_name: string?,
	step: number,
}

type AnalyticsProgressionInfo = BaseAnalyticsInfo & {
	status: Enum.AnalyticsProgressionType,
	level_name: string,
	path_name: string,
	level: number,
	step: number?,
}

type AnalyticsEconomyInfo = BaseAnalyticsInfo & {
	transaction_type: Enum.AnalyticsEconomyTransactionType,
	flow_type: Enum.AnalyticsEconomyFlowType,
	ending_balance: number,
	currency_type: string,
	amount: number,
	item_sku: string?,
}


type AnalyticsFunnelStepInfo = BaseAnalyticsInfo & {
	funnel_name: string,
	sessionid: string?,
	step_name: string?,
	step: number?,
}

local CUSTOM_FIELDS = {
	[1] = Enum.AnalyticsCustomFieldKeys.CustomField01,
	[2] = Enum.AnalyticsCustomFieldKeys.CustomField02,
	[3] = Enum.AnalyticsCustomFieldKeys.CustomField03,
}

@native
local function DICT_TO_CUSTOM_FIELDS(info: BaseAnalyticsInfo): { [Enum.AnalyticsCustomFieldKeys]: string }?
	local custom_fields = info.custom_fields

	if custom_fields then
		local return_tbl = {}
		local index = 1

		for key, value in custom_fields do
			if index == 3 then
				error("[ANALYTICS] custom field dictionary cannot have more than 3 entries")
			else
				return_tbl[CUSTOM_FIELDS[index]] = `{key} - {value}`
				index += 1
			end
		end
		return return_tbl
	else
		return nil
	end
end

local function log_economy(player: Player, info: AnalyticsEconomyInfo)
	AnalyticsService:LogEconomyEvent(
		player, info.flow_type, info.currency_type, info.ending_balance, 
		info.transaction_type :: any, info.item_sku, DICT_TO_CUSTOM_FIELDS(info)
	)
end

local function log_funnel_step(player: Player, info: AnalyticsFunnelStepInfo)
	AnalyticsService:LogFunnelStepEvent(
		player, info.funnel_name, info.sessionid, info.step, 
		info.step_name, DICT_TO_CUSTOM_FIELDS(info)
	)
end

local function log_onboarding_funnel_step(player: Player, info: AnalyticsOnboardingFunnelStepInfo)
	AnalyticsService:LogOnboardingFunnelStepEvent(
		player, info.step, info.step_name, DICT_TO_CUSTOM_FIELDS(info)
	)
end

local function log_progression(player: Player, info: AnalyticsProgressionInfo)
	AnalyticsService:LogProgressionEvent(
		player, info.path_name, info.status, info.level,
		info.level_name, DICT_TO_CUSTOM_FIELDS(info)
	)
end

return table.freeze {
	onboarding_funnel_step = log_onboarding_funnel_step,
	progression = log_progression,
	funnel_step = log_funnel_step,
	economy = log_economy,
}