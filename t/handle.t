# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $MainConfig = qq{
    env NS_KEY;
    env NS_HOST;
    env NS_KEYNAME;
};

our $HttpConfig = qq{
    resolver 8.8.8.8;
    lua_package_path "$pwd/lib/?.lua;;";

    init_by_lua_block {
        require "resty.core"
    }
};

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: download sanity
--- main_config eval: $::MainConfig
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local netstorage = require("resty.netstorage")

            local ns, err = netstorage:new({
                key = os.getenv("NS_KEY"),
                key_name = os.getenv("NS_KEYNAME"),
                host = os.getenv("NS_HOST"),
                ssl = true,
            })
            if not ns then
                ngx.log(ngx.ERR, "init failed: ", err)
                return ngx.exit(500)
            end

            local ret, err, code = ns:download("/10000/new_file")
            if err then
                ngx.log(ngx.ERR, "donwload failed: ", err)
                return ngx.exit(500)
            end

            ngx.say("code: ", code, ", content: ", ret)
            ns:set_keepalive()
        }
    }
--- request
GET /t
--- response_body_like
code: 200, content: (.*)
--- no_error_log
[error]
