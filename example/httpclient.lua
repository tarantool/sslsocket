#!/usr/bin/env tarantool

local sslsocket = require('sslsocket')
local log = require('log')

local sock, err = sslsocket.tcp_connect('www.google.com', 443)
if not sock then
    log.info(err)
    return
end

local num = sock:write('GET /?q=tarantool HTTP/1.1\r\n'..
                           'Host:www.google.com\r\n'..
                           'Connection:close\r\n'..
                           '\r\n')

local REQUEST = 1
local HEADERS = 2

local httpstate = REQUEST

local response = {
    version='',
    code='',
    headers={}
}

while true do
    local line, err = sock:read({delimiter='\r\n'})
    if line == nil then
        log.debug('Read failed while handshake')
        return nil, sock:error()
    elseif line == '' then
        log.debug('Read eof while handshake')
        return nil, 'Connection closed'
    end
    if httpstate == REQUEST then
        local i, j
        -- Method SP Request-URI SP HTTP-Version CRLF
        i, j, response.version, response.code, response.reason =
            line:find('^([^%s]+)%s([^%s]+)%s([^\r\n]*)')
        httpstate = HEADERS
    elseif httpstate == HEADERS then
        if line == '\r\n' then
            break
        else
            local _, _, name, value = line:find('^([^:]+)%s*:%s*(.+)')
            if name == nil or value == nil then
                log.info('Malformed packet')
                break
            end
            response.headers[name:strip():lower()] = value:strip()
        end
    end
end

log.info('===response===')
log.info(response)

log.info('===body===')
local body = sock:read(256)
while body ~= nil and body ~= '' do
    log.info(body)
    body = sock:read(256)
end
