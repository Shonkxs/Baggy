local ADDON_NAME, ns = ...

local Currencies = {}
ns.Currencies = Currencies

Currencies.MAX_TRACKED = 8

local function toNumberOrNil(value)
    if type(value) == "number" then
        return value
    end

    local numeric = tonumber(value)
    if type(numeric) == "number" then
        return numeric
    end

    return nil
end

local function safeGetCurrencyInfo(currencyID)
    if not (_G.C_CurrencyInfo and _G.C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end

    local ok, info = pcall(_G.C_CurrencyInfo.GetCurrencyInfo, currencyID)
    if not ok then
        return nil
    end

    return info
end

function Currencies.NormalizeTrackedCurrencyIDs(ids)
    local result = {}
    local seen = {}

    if type(ids) ~= "table" then
        return result
    end

    for _, value in ipairs(ids) do
        local numeric = toNumberOrNil(value)
        if numeric then
            numeric = math.floor(numeric)
            if numeric > 0 and not seen[numeric] then
                seen[numeric] = true
                result[#result + 1] = numeric
                if #result >= Currencies.MAX_TRACKED then
                    break
                end
            end
        end
    end

    return result
end

function Currencies.GetCurrencyEntry(currencyID)
    local numericID = toNumberOrNil(currencyID)
    if not numericID then
        return nil
    end

    numericID = math.floor(numericID)
    if numericID <= 0 then
        return nil
    end

    local info = safeGetCurrencyInfo(numericID)
    if type(info) ~= "table" then
        return nil
    end

    local quantity = toNumberOrNil(info.quantity) or 0
    if quantity < 0 then
        quantity = 0
    end

    local name = info.name
    if type(name) ~= "string" or name == "" then
        name = string.format("Currency %d", numericID)
    end

    return {
        currencyID = numericID,
        name = name,
        iconFileID = info.iconFileID,
        quantity = math.floor(quantity),
    }
end

local function getListAPI()
    local api = _G.C_CurrencyInfo or {}

    local listSize = api.GetCurrencyListSize or _G.GetCurrencyListSize
    local listInfo = api.GetCurrencyListInfo or _G.GetCurrencyListInfo
    local expandList = api.ExpandCurrencyList or _G.ExpandCurrencyList
    local listLink = api.GetCurrencyListLink or _G.GetCurrencyListLink
    local idFromLink = api.GetCurrencyIDFromLink or _G.GetCurrencyIDFromLink

    if not (listSize and listInfo) then
        return nil
    end

    return {
        GetCurrencyListSize = listSize,
        GetCurrencyListInfo = listInfo,
        ExpandCurrencyList = expandList,
        GetCurrencyListLink = listLink,
        GetCurrencyIDFromLink = idFromLink,
    }
end

local function collapseHeaders(expandedHeaders)
    if type(expandedHeaders) ~= "table" then
        return
    end

    local listAPI = getListAPI()
    if not (listAPI and listAPI.ExpandCurrencyList) then
        return
    end

    for index = #expandedHeaders, 1, -1 do
        pcall(listAPI.ExpandCurrencyList, expandedHeaders[index], false)
    end
end

function Currencies.GetSelectableCurrencies()
    local listAPI = getListAPI()
    if not listAPI then
        return {}
    end

    local expandedHeaders = {}
    local entriesByID = {}
    local okSize, sizeValue = pcall(listAPI.GetCurrencyListSize)
    local listSize = okSize and (toNumberOrNil(sizeValue) or 0) or 0
    local index = 1

    while index <= listSize do
        local okInfo, info = pcall(listAPI.GetCurrencyListInfo, index)
        if not okInfo then
            break
        end

        if type(info) ~= "table" then
            break
        end

        if info.isHeader then
            if listAPI.ExpandCurrencyList and not info.isHeaderExpanded then
                expandedHeaders[#expandedHeaders + 1] = index
                pcall(listAPI.ExpandCurrencyList, index, true)
                local okRefreshSize, refreshSizeValue = pcall(listAPI.GetCurrencyListSize)
                if okRefreshSize then
                    listSize = toNumberOrNil(refreshSizeValue) or listSize
                end
            end
        else
            local currencyID = toNumberOrNil(info.currencyTypesID)

            if not currencyID and listAPI.GetCurrencyListLink and listAPI.GetCurrencyIDFromLink then
                local okLink, link = pcall(listAPI.GetCurrencyListLink, index)
                if okLink and link then
                    local okID, resolvedID = pcall(listAPI.GetCurrencyIDFromLink, link)
                    if okID then
                        currencyID = toNumberOrNil(resolvedID)
                    end
                end
            end

            if currencyID then
                currencyID = math.floor(currencyID)
                if currencyID > 0 and not entriesByID[currencyID] then
                    local entry = Currencies.GetCurrencyEntry(currencyID)
                    if entry then
                        entriesByID[currencyID] = entry
                    end
                end
            end
        end

        index = index + 1
    end

    collapseHeaders(expandedHeaders)

    local result = {}
    for _, entry in pairs(entriesByID) do
        result[#result + 1] = entry
    end

    table.sort(result, function(a, b)
        local aName = string.lower(a.name or "")
        local bName = string.lower(b.name or "")
        if aName ~= bName then
            return aName < bName
        end
        return (a.currencyID or 0) < (b.currencyID or 0)
    end)

    return result
end
