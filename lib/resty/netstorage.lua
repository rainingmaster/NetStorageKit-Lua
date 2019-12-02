local new_http      = require "resty.http" .new
local hmac_tbl      = require "resty.hmac"

local new_hmac      = hmac_tbl .new
local encode_base64 = ngx.encode_base64
local escape_uri    = ngx.escape_uri
local random        = math.random
local time          = ngx.time
local tbl_concat    = table.concat
local type          = type

local TYPE_STRING   = "string"

local _M = {
    _VERSION = "0.01",
}

local mt = { __index = _M }


function _M.new(_, args)
    local key_name = args.key_name
    local key = args.key
    local host = args.host
    if type(key_name) ~= TYPE_STRING
       or type(key) ~= TYPE_STRING
       or type(host) ~= TYPE_STRING
    then
        return nil, "should input netstorage host, keyname and key all"
    end

    local ssl = args.ssl
    local port = ssl and 443 or 80

    local httpc = new_http()

    local timeout = tonumber(args.timeout)
    if timeout then
        local err = httpc:set_timeout(timeout)
        if err then
            return nil, err
        end
    end

    local ok, err = httpc:connect(host, port)
    if not ok then
        return nil, err
    end

    if ssl then
        ok, err = httpc:ssl_handshake(nil, host, false)
        if not ok then
            return nil, err
        end
    end

    local hmac = new_hmac(nil, key, hmac_tbl.ALGOS.SHA256)
    if not hmac then
        return nil, "init hmac failed"
    end

    return setmetatable({
        httpc = httpc,
        host = host,
        hmac = hmac,
        key_name = key_name,
    }, mt)
end


function _M._request(self, params)
    local path = params.path
    if type(path) ~= TYPE_STRING then
        return nil, "illeagel path"
    end

    local httpc = self.httpc
    local hmac = self.hmac
    if not httpc or not hmac then
        return nil, "not initialized"
    end

    local acs_act = "version=1&action=" .. params.action
    local acs_auth_data = tbl_concat({
        "5, 0.0.0.0, 0.0.0.0",
        time(),
        random(1, 100000),
        self.key_name,
    }, ", ")

    local ok = hmac:update(
        acs_auth_data
        .. path
        .. "\nx-akamai-acs-action:"
        .. acs_act
        .. "\n"
    )
    if not ok then
        return nil, "hmac update failed"
    end

    local sum = hmac:final(nil, false)
    if not sum then
        return nil, "hmac sum failed"
    end

    ok = hmac:reset()
    if not ok then
        return nil, "hmac reinit failed"
    end

    local sign = encode_base64(sum)
    if not sign then
        return nil, "base64 encode failed"
    end

    local resp, err = httpc:request({
        method = params.method,
        path = path,
        headers = {
            ["Host"] = self.host,
            ["X-Akamai-ACS-Action"] = acs_act,
            ["X-Akamai-ACS-Auth-Data"] = acs_auth_data,
            ["X-Akamai-ACS-Auth-Sign"] = sign,
            ["Accept-Encoding"] = "identity",
            ["User-Agent"] = "NetStorageKit-Lua",
        },
        body = params.data,
    })

    if not resp then
        return nil, err
    end

    local reader = resp.body_reader
    if not reader then
        return nil, "no body to be read"
    end

    local chunks = {}
    local chunk, err
    repeat
        chunk, err = reader()

        if err then
            return nil, err, tbl_concat(chunks) -- Return any data so far.
        end
        if chunk then
            chunks[#chunks + 1] = chunk
        end
    until not chunk

    return tbl_concat(chunks), nil, resp.status
end


function _M.set_keepalive(self, ...)
    local httpc = self.httpc
    if not httpc then
        return nil, "not initialized"
    end

    return httpc:set_keepalive(...)
end


-- Dir returns the directory structure
function _M.dir(self, path)
    return self:_request({
        action = "dir&format=xml",
        method = "GET",
        path = path,
    })
end


-- Du returns the disk usage information for a directory
function _M.du(self, path)
    return self:_request({
        action = "du&format=xml",
        method = "GET",
        path = path,
    })
end


-- Stat returns the information about an object structure
function _M.stat(self, path)
    return self:_request({
        action = "stat&format=xml",
        method = "GET",
        path = path,
    })
end


-- Mkdir creates an empty directory
function _M.mkdir(self, path)
    return self:_request({
        action = "mkdir",
        method = "POST",
        path = path,
    })
end


-- Rmdir deletes an empty directory
function _M.rmdir(self, path)
    return self:_request({
        action = "rmdir",
        method = "POST",
        path = path,
    })
end


-- Mtime changes a file’s mtime
function _M.mtime(self, path, mtime)
    local num_mtime = tonumber(mtime)
    if not num_mtime then
        return nil, "illeagel mtime"
    end

    return self:_request({
        action = "mtime&format=xml&mtime=" .. mtime,
        method = "POST",
        path = path,
    })
end


-- Delete deletes an object/symbolic link
function _M.delete(self, path)
    return self:_request({
        action = "delete",
        method = "POST",
        path = path,
    })
end


-- QuickDelete deletes a directory (i.e., recursively delete a directory tree)
-- In order to use this func, you need to the privilege on the CP Code.
function _M.quick_delete(self, path)
    return self:_request({
        action = "quick-delete&quick-delete=imreallyreallysure",
        method = "POST",
        path = path,
    })
end


-- Rename renames a file or symbolic link.
function _M.rename(self, target, dest)
    if type(target) ~= TYPE_STRING then
        return nil, "illeagel target"
    end

    if type(dest) ~= TYPE_STRING then
        return nil, "illeagel dest"
    end

    return self:_request({
        action = "rename&destination=" .. escape_uri(dest),
        method = "POST",
        path = target,
    })
end


-- Symlink creates a symbolic link.
function _M.symlink(self, target, dest) 
    if type(target) ~= TYPE_STRING then
        return nil, "illeagel target"
    end

    if type(dest) ~= TYPE_STRING then
        return nil, "illeagel dest"
    end

    return self:_request({
        action = "symlink&target=" .. escape_uri(target),
        method = "POST",
        path = dest,
    })
end


-- Upload uploads a piece of string.
function _M.upload(self, dest, content)
    if type(dest) ~= TYPE_STRING then
        return nil, "illeagel dest"
    end

    if type(content) ~= TYPE_STRING then
        return nil, "illeagel content"
    end

    -- Request body is empty string.
    return self:_request({
        action = "upload",
        method = "PUT",
        path = dest,
        data = content,
    })
end


-- Download downloads a piece of string.
function _M.download(self, target)
    if type(target) ~= TYPE_STRING then
        return nil, "illeagel target"
    end

    return self:_request({
        action = "download",
        method = "GET",
        path = target,
    })
end


return _M
