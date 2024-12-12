local cjson = require("cjson")
local utils = require("utils")

local _M = {}

function _M.handle_request()

    local authorization = ngx.req.get_headers()["Authorization"]
    if not authorization then
        return ngx.exit(401)
    end

    if not utils.check(authorization) then
        return ngx.exit(401)
    end

    -- 读取和验证请求体
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    if not body then
        return ngx.exit(400)
    end

    -- 解析 JSON
    local success, request = pcall(cjson.decode, body)
    if not success then
        return ngx.exit(400)
    end

    -- 获取并验证 provider
    local group = request.model
    local provider = utils.iterator(group)
    if not provider then
        return ngx.exit(404)
    end

    -- 修改请求
    request.model = provider.name
    ngx.req.set_body_data(cjson.encode(request))

    -- 设置上游信息
    ngx.var.upstream = provider.base
    ngx.req.set_header("Authorization", "Bearer " .. provider.key)
    ngx.ctx.group = group
end

function _M.handle_header()
    -- 初始化缓冲区
    ngx.ctx.response_buffer = {}
    -- 检测是否是流式响应
    ngx.ctx.is_stream = ngx.header.content_type == "text/event-stream"
    if ngx.ctx.is_stream then
        -- 设置流式响应的头部
        ngx.header.content_type = "text/event-stream"
        ngx.header.cache_control = "no-cache"
        ngx.header.connection = "keep-alive"
    else
        -- 对于非流式响应，不设置 Content-Length 头部
        ngx.header.content_length = nil
    end
end

function _M.handle_response()
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    -- 初始化 response_buffer
    if not ngx.ctx.response_buffer then
        ngx.ctx.response_buffer = {}
    end

    if ngx.ctx.is_stream then
        if chunk then
            -- 处理并修改每个流块
            local modified_chunk = chunk:gsub('("model":%s*")([^"]+)(")', 
                function(prefix, _, suffix)
                    return prefix .. ngx.ctx.group .. suffix
                end)
            ngx.arg[1] = modified_chunk
        end
        -- 对于流式响应，不设置 ngx.arg[2]，保持连接打开
        return
    else
        -- 缓冲非流式响应
        if chunk then
            table.insert(ngx.ctx.response_buffer, chunk)
        end

        if eof or #ngx.ctx.response_buffer > 0 then  -- 即使 eof 为 false, 如果 buffer 不为空, 也认为是 eof
            -- 处理完整响应
            local response = table.concat(ngx.ctx.response_buffer)
            local success, json_response = pcall(cjson.decode, response)
            if success then
                json_response.model = ngx.ctx.group
                local ok, encoded = pcall(cjson.encode, json_response)
                if ok then
                    response = encoded
                end
            end

            -- 设置响应体和 eof 标志
            ngx.arg[1] = response
            ngx.arg[2] = true
        else
            -- 对于非流式响应的中间块，不修改 ngx.arg，让数据继续传递到下一个 filter
            ngx.arg[1] = chunk
            ngx.arg[2] = false
        end
    end

    -- 清理 response_buffer (无论 eof 是否为 true)
    ngx.ctx.response_buffer = nil
end

return _M
