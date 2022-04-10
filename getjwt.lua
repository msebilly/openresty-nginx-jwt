local cjson = require "cjson"
local jwt = require "resty.jwt"

local uid = ngx.req.get_headers()["X-Pro-Uuid"]

if uid == nil or string.len(uid) == 0 then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local jwt_token = jwt:sign(
    os.getenv("JWT_SECRET"),
    {
        header={typ="JWT", alg="HS256"},
        payload={uuid=uid}
    }
)

local response = { uuid=uid, jwt=jwt_token}
ngx.header.content_type = "application/json; charset=utf-8"
ngx.say(cjson.encode(response))

-- ngx.say(uid .. " # " .. jwt_token)
