openresty-nginx-jwt
===
[![](https://images.microbadger.com/badges/image/ubergarm/openresty-nginx-jwt.svg)](https://microbadger.com/images/ubergarm/openresty-nginx-jwt) [![](https://images.microbadger.com/badges/version/ubergarm/openresty-nginx-jwt.svg)](https://microbadger.com/images/ubergarm/openresty-nginx-jwt) [![License](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/ubergarm/openresty-nginx-jwt/blob/master/LICENSE)

JWT Bearer Token authorization with `nginx`, `openresty`, and `lua-resty-jwt`.

An easy way to setup JWT Bearer Token authorization for any API endpoint, reverse proxy service, or location block without having to touch your server-side code.

## Run
This example uses the secret, token, and claims from [jwt.io](https://jwt.io/):

Server:
```bash
docker run --rm \
           -it \
           -e JWT_SECRET=secret \
           -v `pwd`/nginx.conf:/nginx.conf \
           -v `pwd`/bearer.lua:/bearer.lua \
           -v `pwd`/guard.lua:/guard.lua \
           -v `pwd`/redjwt.lua:/redjwt.lua \
           -v `pwd`/getjwt.lua:/getjwt.lua \
           -v `pwd`/verify.lua:/verify.lua \
           -p 8080:8080 \
           ubergarm/openresty-nginx-jwt
```

Client:
```bash
# apt-get install httpie || brew install httpie
http --print HBhb localhost:8080/secure/ "Authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ"
# token as url argument
http --print HBhb localhost:8080/secure/?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
# token as cookie
http --print HBhb localhost:8080/secure/ "Cookie:token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ"

http --print HBhb localhost:8080/verify

http --print HBhb localhost:8080/sign

```


## Configure
Edit `nginx.conf` to setup your custom location blocks.
```nginx configuration
location /secure/ {
    access_by_lua_file /bearer.lua;

    default_type text/plain;
    echo "<p>i am protected by jwt<p>";
}

location = /verify {
    content_by_lua '
        local cjson = require "cjson"
        local jwt = require "resty.jwt"

        local auth_header = ngx.var.http_Authorization
        if auth_header then
            _, _, jwt_token = string.find(auth_header, "Bearer%s+(.+)")
        end

        local jwt_obj = jwt:verify(os.getenv("JWT_SECRET"), jwt_token)
        -- ngx.say(jwt_obj["payload"].uuid)
        ngx.say(cjson.encode(jwt_obj))
    ';
}

location = /sign {
    content_by_lua '
        local cjson = require "cjson"
        local jwt = require "resty.jwt"

        local uid = ngx.req.get_headers()["X-Pro-Uuid"]

        local jwt_token = jwt:sign(
            os.getenv("JWT_SECRET"),
            {
                header={typ="JWT", alg="HS256"},
                payload={uuid=uid}
            }
        )
        ngx.say(jwt_token)
    ';
}

location /secure_this {
    access_by_lua '
        local jwt = require "resty.jwt"
        jwt.auth()
    ';

    proxy_pass http://my-backend.com$uri;
}
```

Edit `bearer.lua` or create new `lua` scripts to meet your specific needs for each location block.

Restart a container and volume mount in all of the required configuration.

## Build
To update or build a custom image edit the `Dockerfile` and:
```bash
docker build -t ubergarm/openresty-nginx-jwt .
```

## Note
I originally tried to get [auth0/nginx-jwt](https://github.com/auth0/nginx-jwt) working, but even the newer forks are not as straight forward as simply using `lua-resty-jwt` rock directly.

If you're looking for something beyond just JWT auth, check out [kong](https://getkong.org/) for all your API middleware plugin needs!

Also [Caddy](https://caddyserver.com/) might be faster for a simple project.

## References
* https://github.com/openresty/docker-openresty
* https://github.com/SkyLothar/lua-resty-jwt
* https://github.com/svyatogor/resty-lua-jwt
* https://getkong.org/
* https://jwt.io/
