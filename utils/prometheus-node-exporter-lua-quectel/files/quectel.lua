-- Quectel 5G module (RM520N and similar), queried through quectel-atd.

local unix = require("socket.unix")

local SOCKET = "/var/run/quectel-at.sock"

-- All queries chained into one command: one round trip instead of ~300 ms each.
local QUERY = "AT" .. table.concat({
  '+QENG="servingcell"',
  "+QCAINFO",
  '+QENG="neighbourcell"',
  "+QRSRP",
  "+QRSRQ",
  "+QSINR",
  '+QNWCFG="lte_csi"',
  '+QNWCFG="nr5g_csi"',
  '+QNWCFG="lte_ambr"',
  '+QNWCFG="nr5g_ambr"',
  "+COPS?",
  "+CEREG?",
  "+C5GREG?",
  "+QNETRC?",
  "+QTEMP",
}, ";")

local function at()
  local sock = unix()
  sock:settimeout(3)
  local ok, err = sock:connect(SOCKET)
  if not ok then error("quectel: " .. SOCKET .. ": " .. err) end
  sock:send(QUERY .. "\n")
  local out, rerr, partial = sock:receive("*a")
  sock:close()
  out = out or partial
  if not out:find("\r\nOK\r\n$") then error("quectel: " .. (rerr or out)) end
  return out
end

-- Splits "+X: a,"b",c" into {"a", "b", "c"}; "-" (invalid) becomes nil.
local function fields(s)
  local f, n = {}, 0
  for v in (s .. ","):gmatch("([^,]*),") do
    n = n + 1
    v = v:gsub('^"(.*)"$', "%1")
    if v ~= "-" and v ~= "" then f[n] = v end
  end
  return f
end

local num = tonumber

-- LTE DL bandwidth in QCAINFO is given in resource blocks (6 ... 100).
local LTE_RB_MHZ = { ["6"] = 1.4, ["15"] = 3, ["25"] = 5, ["50"] = 10, ["75"] = 15, ["100"] = 20 }
-- NR DL bandwidth index (QENG/QCAINFO).
local NR_BW_MHZ = { [0] = 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 200, 400, 35, 45 }
-- Antenna paths of AT+QRSRP/QRSRQ/QSINR, in field order.
local PATHS = { "prx", "drx", "rx2", "rx3" }
-- AcT from AT+COPS?.
local MODE = { ["7"] = "lte", ["10"] = "lte", ["11"] = "sa", ["12"] = "sa", ["13"] = "nsa" }

-- Help texts; node-exporter-lua's metric() only writes TYPE.
local HELP = {
  quectel_rsrp_dbm = "Reference signal received power per carrier, in dBm.",
  quectel_rsrq_db = "Reference signal received quality per carrier, in dB.",
  quectel_rssi_dbm = "Received signal strength indicator per LTE carrier, in dBm.",
  quectel_sinr_db = "Signal to interference plus noise ratio per carrier, in dB.",
  quectel_state = "UE state (SEARCH, LIMSRV, NOCONN = idle, CONNECT = data in progress), always 1.",
  quectel_cell_info = "Serving cell identity (cell ID, physical cell ID, TAC, ARFCN, band), always 1.",
  quectel_tx_power_dbm = "Uplink transmit power, in dBm; only meaningful while sending.",
  quectel_carrier_bandwidth_mhz = "Downlink bandwidth per carrier, in MHz.",
  quectel_neighbour_cells = "Number of LTE neighbour cells per frequency, cells in use excluded.",
  quectel_neighbour_rsrp_dbm = "RSRP of the strongest LTE neighbour cell per frequency, in dBm.",
  quectel_neighbour_rsrq_db = "RSRQ of the strongest LTE neighbour cell per frequency, in dB.",
  quectel_antenna_rsrp_dbm = "RSRP per receive antenna path of the primary carrier, in dBm.",
  quectel_antenna_rsrq_db = "RSRQ per receive antenna path of the primary carrier, in dB.",
  quectel_antenna_sinr_db = "SINR per receive antenna path of the primary carrier, in dB.",
  quectel_mcs = "Modulation and coding scheme index of the downlink.",
  quectel_mimo_layers = "Rank indicator: number of downlink MIMO layers.",
  quectel_cqi = "Channel quality indicator reported to the network.",
  quectel_ambr_kbps = "Aggregate maximum bit rate granted by the network per APN, in kbit/s.",
  quectel_network_info = "Registered operator and network mode (lte, nsa, sa), always 1.",
  quectel_registration_status = "Registration status per domain (0 not registered, 1 home, 2 searching, 3 denied, 5 roaming).",
  quectel_reject_cause = "Last reject cause from the network per protocol (3GPP TS 24.301/24.501), 0 = none.",
  quectel_temperature_celsius = "Temperature per module sensor, in degrees Celsius.",
}

local function gauge(name)
  out:write("# HELP ", name, " ", HELP[name], "\n")
  return metric(name, "gauge")
end

local function scrape()
  local lines = {}
  for line in at():gmatch("[^\r\n]+") do
    local cmd, rest = line:match("^%+(%w+):%s*(.*)$")
    if cmd then
      lines[cmd] = lines[cmd] or {}
      table.insert(lines[cmd], fields(rest))
    end
  end

  local m_rsrp = gauge("quectel_rsrp_dbm")
  local m_rsrq = gauge("quectel_rsrq_db")
  local m_rssi = gauge("quectel_rssi_dbm")
  local m_sinr = gauge("quectel_sinr_db")

  -- Serving cell: state, cell identity, NR signal (QCAINFO has none for NR).
  local m_state = gauge("quectel_state")
  local m_cell = gauge("quectel_cell_info")
  local m_txp = gauge("quectel_tx_power_dbm")
  -- LTE cells in use, to tell them apart in the neighbour list: "earfcn:PCID".
  local serving = {}
  for _, f in ipairs(lines.QENG or {}) do
    -- LTE-only mode puts the "LTE" fields on the servingcell line, after
    -- servingcell,state; in EN-DC mode they get a line of their own.
    local o = 0
    if f[1] == "servingcell" then
      m_state({ state = f[2] }, 1)
      if f[3] == "NR5G-SA" then
        -- servingcell,state,NR5G-SA,duplex,MCC,MNC,cellID,PCID,TAC,ARFCN,band,bw,RSRP,RSRQ,SINR,scs,srxlev
        m_cell({ rat = "nr5g", cell_id = f[7], pcid = f[8], tac = f[9], arfcn = f[10], band = f[11] }, 1)
        local l = { rat = "nr5g", role = "pcc", band = f[11], arfcn = f[10] }
        m_rsrp(l, num(f[13])); m_rsrq(l, num(f[14])); m_sinr(l, num(f[15]))
      elseif f[3] == "LTE" then
        o = 2
      end
    end
    if f[o + 1] == "LTE" then
      -- LTE,duplex,MCC,MNC,cellID,PCID,earfcn,band,ULbw,DLbw,TAC,RSRP,RSRQ,RSSI,SINR,CQI,tx_power,srxlev
      m_cell({ rat = "lte", cell_id = f[o + 5], pcid = f[o + 6], tac = f[o + 11], arfcn = f[o + 7], band = f[o + 8] }, 1)
      serving[f[o + 7] .. ":" .. f[o + 6]] = true
      if f[o + 17] then m_txp({ rat = "lte" }, num(f[o + 17]) / 10) end
    elseif f[1] == "NR5G-NSA" then
      -- NR5G-NSA,MCC,MNC,PCID,RSRP,SINR,RSRQ,ARFCN,band,bw,scs
      m_cell({ rat = "nr5g", pcid = f[4], arfcn = f[8], band = f[9] }, 1)
      local l = { rat = "nr5g", role = "scc", band = f[9], arfcn = f[8] }
      m_rsrp(l, num(f[5])); m_sinr(l, num(f[6])); m_rsrq(l, num(f[7]))
    end
  end

  -- Carrier aggregation: one line per LTE carrier (PCC + SCCs) with signal,
  -- NR SCC without signal (taken from QENG above).
  local m_bw = gauge("quectel_carrier_bandwidth_mhz")
  for _, f in ipairs(lines.QCAINFO or {}) do
    local rat, band = (f[4] or ""):match("^(%S+) BAND (%d+)$")
    if rat == "LTE" then
      -- PCC|SCC,earfcn,bw,band,state,PCID,RSRP,RSRQ,RSSI,RSSNR[,UL...]
      local l = { rat = "lte", role = f[1]:lower(), band = band, arfcn = f[2] }
      m_bw(l, LTE_RB_MHZ[f[3]])
      m_rsrp(l, num(f[7])); m_rsrq(l, num(f[8])); m_rssi(l, num(f[9])); m_sinr(l, num(f[10]))
      serving[f[2] .. ":" .. f[6]] = true
    elseif rat == "NR5G" then
      m_bw({ rat = "nr5g", role = f[1]:lower(), band = band, arfcn = f[2] }, NR_BW_MHZ[num(f[3])])
    end
  end

  -- LTE neighbour cells (the list also holds the cells in use): count and
  -- the strongest one per frequency, the candidate for a handover.
  local count, best = {}, {}
  for _, f in ipairs(lines.QENG or {}) do
    -- neighbourcell intra|inter,LTE,earfcn,PCID,RSRQ,RSRP,RSSI,SINR,...
    if f[1] and f[1]:match("^neighbourcell") and f[2] == "LTE" and not serving[f[3] .. ":" .. f[4]] then
      local rsrp = num(f[6])
      count[f[3]] = (count[f[3]] or 0) + 1
      if rsrp and (not best[f[3]] or rsrp > best[f[3]].rsrp) then
        best[f[3]] = { rsrp = rsrp, rsrq = num(f[5]) }
      end
    end
  end
  local m_ncount = gauge("quectel_neighbour_cells")
  local m_nrsrp = gauge("quectel_neighbour_rsrp_dbm")
  local m_nrsrq = gauge("quectel_neighbour_rsrq_db")
  for arfcn, n in pairs(count) do
    local l = { rat = "lte", arfcn = arfcn }
    m_ncount(l, n)
    if best[arfcn] then m_nrsrp(l, best[arfcn].rsrp); m_nrsrq(l, best[arfcn].rsrq) end
  end

  -- Signal per antenna path of the primary carrier; -32768 = invalid.
  for cmd, name in pairs({ QRSRP = "quectel_antenna_rsrp_dbm", QRSRQ = "quectel_antenna_rsrq_db", QSINR = "quectel_antenna_sinr_db" }) do
    local m = gauge(name)
    for _, f in ipairs(lines[cmd] or {}) do
      -- prx,drx,rx2,rx3,LTE|NR5G
      for i, path in ipairs(PATHS) do
        local v = num(f[i])
        if v and v ~= -32768 then m({ rat = f[5]:lower(), path = path }, v) end
      end
    end
  end

  -- Channel state: MCS, rank (= MIMO layers), CQI per RAT.
  local m_mcs = gauge("quectel_mcs")
  local m_ri = gauge("quectel_mimo_layers")
  local m_cqi = gauge("quectel_cqi")
  -- Aggregate maximum bit rate granted by the network (kbit/s), per APN;
  -- drops when the tariff throttles.
  local m_ambr = gauge("quectel_ambr_kbps")
  for _, f in ipairs(lines.QNWCFG or {}) do
    local rat, kind = f[1]:match("^(%w+)_(%w+)$")
    if kind == "csi" then
      -- <rat>_csi,mcs,ri,cqi,pmi
      local l = { rat = rat }
      m_mcs(l, num(f[2])); m_ri(l, num(f[3])); m_cqi(l, num(f[4]))
    elseif kind == "ambr" and f[2] then
      -- <rat>_ambr,APN,downlink,uplink
      m_ambr({ rat = rat, apn = f[2], direction = "downlink" }, num(f[3]))
      m_ambr({ rat = rat, apn = f[2], direction = "uplink" }, num(f[4]))
    end
  end

  -- Operator and access technology (13 = EN-DC/NSA).
  local cops = (lines.COPS or {})[1] or {}
  if cops[3] then
    gauge("quectel_network_info")({ operator = cops[3], mode = MODE[cops[4]] or cops[4] }, 1)
  end

  -- Registration status per domain (1 = home, 5 = roaming).
  local m_reg = gauge("quectel_registration_status")
  for cmd, domain in pairs({ CEREG = "eps", C5GREG = "5gs" }) do
    local f = (lines[cmd] or {})[1] or {}
    m_reg({ domain = domain }, num(f[2]))
  end

  -- Last reject cause from the network per protocol (0 = none).
  local m_rej = gauge("quectel_reject_cause")
  for _, f in ipairs(lines.QNETRC or {}) do
    -- emm_cause|esm_cause|5gmm_cause,cause
    m_rej({ protocol = f[1]:gsub("_cause$", "") }, num(f[2]))
  end

  -- Temperatures; sensors of unused paths report 0 or -273.
  local m_temp = gauge("quectel_temperature_celsius")
  for _, f in ipairs(lines.QTEMP or {}) do
    local t = num(f[2])
    if t and t > 0 then m_temp({ sensor = f[1] }, t) end
  end
end

return { scrape = scrape }
