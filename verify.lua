local jwt = require "resty.jwt"
local jwt_token = ngx.var.arg_token

local auth_header = ngx.var.http_Authorization
if auth_header then
    _, _, jwt_token = string.find(auth_header, "Bearer%s+(.+)")
end

local jwt_obj = jwt:verify(os.getenv("JWT_SECRET"), jwt_token)

if not jwt_obj["verified"] then
    local site = ngx.var.scheme .. "://" .. ngx.var.http_host;
    local args = ngx.req.get_uri_args();

    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say(jwt_obj.reason)
    ngx.exit(ngx.HTTP_OK)
end

--local uid = ngx.req.get_headers()["X-Pro-Uuid"]
--local a, b = string.find(uid, jwt_obj["payload"].uuid)
--if a == nil then
--ngx.exit(ngx.HTTP_UNAUTHORIZED)
--end