#!/usr/bin/env tarantool

local log = require('log')
local sslsocket = require('sslsocket')
local yaml = require('yaml')

-- INITIALIZATION
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
local ctx = sslsocket.ctx(sslsocket.methods.tlsv1)
local rc = sslsocket.ctx_use_private_key_file(ctx, script_path() .. 'certificate.pem')
if rc == false then
    log.info('Certificate is invalid')
    return
end
rc = sslsocket.ctx_use_certificate_file(ctx, script_path() .. 'certificate.pem')
if rc == false then
    log.info('Private key is invalid')
    return
end

-- READ/WRITE LOOP
sslsocket.tcp_server(
    '0.0.0.0', 8443,
    function(client, from)
        log.info('client accepted %s', yaml.encode(from))
        local buf, err = client:read(10)
        if buf == nil then
            log.info('client error %s', err)
            return
        elseif buf == '' then
            log.info('client eof')
            return
        end
        log.info('echo buffer - %s', buf)
        client:write(buf)
        log.info('shutdown client %s', yaml.encode(from))
        local rc, err = client:shutdown()
        if rc == nil then
            log.info(err)
        end
    end,
    nil,
    ctx)
