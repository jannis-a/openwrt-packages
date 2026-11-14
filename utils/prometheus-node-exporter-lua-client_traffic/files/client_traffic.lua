-- Traffic per client MAC from the counter sets tx (sent by the client) and rx
-- (received by the client) of the nftables table bridge client_traffic. MACs
-- are upper case like in wifi_stations and uci_dhcp_host, for joins on mac.

local HELP = {
  client_transmit_bytes_total = "Bytes sent by the client to or through the router.",
  client_transmit_packets_total = "Packets sent by the client to or through the router.",
  client_receive_bytes_total = "Bytes received by the client from or through the router.",
  client_receive_packets_total = "Packets received by the client from or through the router.",
}

local function counter(name)
  out:write("# HELP ", name, " ", HELP[name], "\n")
  return metric(name, "counter")
end

local function scrape()
  for set, dir in pairs({ tx = "transmit", rx = "receive" }) do
    local m_bytes = counter("client_" .. dir .. "_bytes_total")
    local m_packets = counter("client_" .. dir .. "_packets_total")
    local nft = io.popen("nft list set bridge client_traffic " .. set .. " 2>/dev/null")
    local list = nft:read("*a")
    nft:close()
    if list == "" then error("client_traffic: table missing") end
    for mac, packets, bytes in list:gmatch("(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x) counter packets (%d+) bytes (%d+)") do
      -- Skip multicast/broadcast destinations (mDNS, NDP, ff:ff:...): no client.
      if tonumber(mac:sub(1, 2), 16) % 2 == 0 then
        local l = { mac = mac:upper() }
        m_bytes(l, bytes)
        m_packets(l, packets)
      end
    end
  end
end

return { scrape = scrape }
