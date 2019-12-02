Name
====

NetStorageKit-Lua

Table of Contents
=================

* [Name](#name)
* [Description](#description)
* [Synopsis](#synopsis)
* [Modules](#methods)
    * [resty.netstorage](#netstorage)
        * [Methods](#methods)
            * [new](#new)
            * [dir](#dir)
            * [du](#du)
            * [stat](#stat)
            * [mkdir](#mkdir)
            * [rmdir](#rmdir)
            * [mtime](#mtime)
            * [delete](#delete)
            * [quick_delete](#quick_delete)
            * [rename](#rename)
            * [symlink](#symlink)
            * [download](#download)
            * [upload](#upload)
            * [set_keepalive](#set_keepalive)
* [Installation](#installation)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Description
========

NetStorageKit-Lua is Akamai Netstorage (File/Object Store) API for Lua(Openresty). And this module is ported from [netstoragekit-golang](http://github.com/akamai/netstoragekit-golang). Before using this module, [lua-resty-http](https://github.com/ledgetech/lua-resty-http) and [lua-resty-hmac](https://github.com/jkeys089/lua-resty-hmac) should be installed.

Synopsis
========

List the environment variable name in nginx.conf file via the [env directive](https://nginx.org/en/docs/ngx_core_module.html#env) for accessing in lua.

Add configs in `main block`

```nginx
    env NS_KEY;
    env NS_HOST;
    env NS_KEYNAME;
```

Add configs in `http block`

```lua
    lua_package_path "/path/to/NetStorageKit-Lua/lib/?.lua;;";

    server {
        location /test {
            content_by_lua_block {
                local netstorage = require("resty.netstorage")

                -- Get parameters from os evironment, you can change to your own private value.
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

                local _, err, code = ns:upload("/10000/new_file", "hello netstorage here!")
                if err or code ~= 200 then
                    ngx.log(ngx.ERR, "upload failed: ", err, ", code: ", code)
                    return ngx.exit(500)
                end

                ngx.print("success")
                ns:set_keepalive()
            }
        }
    }
```

[Back to TOC](#table-of-contents)

Modules
=======

[Back to TOC](#table-of-contents)

resty.netstorage
--------

[Back to TOC](#table-of-contents)

### Methods

[Back to TOC](#table-of-contents)

#### new

[Back to TOC](#table-of-contents)

#### dir

[Back to TOC](#table-of-contents)

#### du

[Back to TOC](#table-of-contents)

#### stat

[Back to TOC](#table-of-contents)

#### mkdir

[Back to TOC](#table-of-contents)

#### rmdir

[Back to TOC](#table-of-contents)

#### mtime

[Back to TOC](#table-of-contents)

#### delete

[Back to TOC](#table-of-contents)

#### quick_delete

[Back to TOC](#table-of-contents)

#### rename

[Back to TOC](#table-of-contents)

#### symlink

[Back to TOC](#table-of-contents)

#### download

[Back to TOC](#table-of-contents)

#### upload

[Back to TOC](#table-of-contents)

#### delete

[Back to TOC](#table-of-contents)

#### set_keepalive

[Back to TOC](#table-of-contents)

Installation
====

export LUA_LIB_DIR=/path/to/lualib && make install

[Back to TOC](#table-of-contents)

TODO
====

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2018-2018, by rainingmaster.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: https://github.com/openresty/lua-nginx-module/#readme
* [netstorage-http-api-developer-guide](https://learn.akamai.com/en-us/webhelp/netstorage/netstorage-http-api-developer-guide/GUID-22B017EE-DD73-4099-B96D-B5FD91E1ED98.html)
* [lua-resty-core](https://github.com/openresty/lua-resty-core)
* [lua-resty-http](https://github.com/ledgetech/lua-resty-http)
* [lua-resty-hmac](https://github.com/jkeys089/lua-resty-hmac)

[Back to TOC](#table-of-contents)

