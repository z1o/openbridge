local cjson = require("cjson")

local _M = {}

local providers = {}
local security = {}
local groups = {}

function _M.bootstrap()
    local filename = "/app/config.json"
    local file = io.open(filename, "r")
    if not file then
        ngx.log(ngx.ERR, "Failed to open config file: " .. filename)
        return
    end

    local content = file:read("*all")
    file:close()

    local config = cjson.decode(content)

    for _, provider in ipairs(config.providers) do
        if not providers[provider.group] then
            providers[provider.group] = {}
        end
        table.insert(providers[provider.group], provider)
    end

    for _, token in ipairs(config.security) do
        security[token] = true
    end
end

function _M.iterator(group)
    if not providers[group] then
        return nil
    end

    if not groups[group] then
        groups[group] = 0
    end

    groups[group] = groups[group] + 1
    if groups[group] > #providers[group] then
        groups[group] = 1
    end

    return providers[group][groups[group]]
end

function _M.check(authorization)
    if not authorization then
        return false
    end

    local token = authorization:match("^Bearer%s+(.+)$")
    if not token then
        return false
    end

    return security[token] == true
end

function _M.init()
    _M.bootstrap()
    ngx.timer.every(60, _M.bootstrap)
end

return _M 