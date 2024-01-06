-- local inspect = require 'inspect'

function get_uci_dhcp()
  -- local cmd = 'ssh root@192.168.1.1 "uci show dhcp" '
  local cmd = 'uci show dhcp'
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()

  return result

end
function backup_uci_dhcp_host()
  list = get_uci_dhcp()
  --
  f_name = '/tmp/dhcp-back.'..os.date('%Y-%m-%d.%s')
  out = io.open(f_name,"w")
  out:write(list.."\n")
  out:close()
  --
  print(string.format("dump dhcp.host to %s",f_name))

  return true

end

function uci_dhcp_host_to_lua_array(cmd_result)
  cmd_result = string.gsub(cmd_result,'@','')
  cmd_result = string.gsub(cmd_result,']=host',']={}')
  --
  lines = {}
  for line in cmd_result:gmatch("[^\r\n]+") do
    if string.match(line,'dhcp\.host') then
      table.insert(lines,line)
    end
  end
  str_array = ""
  for i,e in pairs(lines) do
    str_array = str_array..e.."\n"
  end
  str_array = str_array.."table.insert(dhcp.host, dhcp.host[0])\n"
  str_array = str_array.."dhcp.host[0]  = nil\n"
  -- print(str_array)
  dhcp={}
  dhcp.host={}
  -- eval uci
  local add_array = loadstring(str_array)
  add_array()

  return dhcp
end

function ip4_to_int(ip)
  t = {}
  for chunk in string.gmatch( ip , "([0-9]+)") do
    table.insert(t,chunk)
  end
  ip_num = 0
  for i,e in pairs(t) do
    ip_num = ip_num  + e*256^(4-i)
  end

  return ip_num

end

function sort_by_ip_addr(dhcp)
  for i,e in pairs(dhcp.host) do
    e.ip_num = ip4_to_int(e.ip)
  end
  table.sort(dhcp.host, function(a,b) return a.ip_num < b.ip_num end)

  return dhcp

end

function gen_uci_dhcp_add_cmd(dhcp)
  cmd = ''
  for i,e in pairs(dhcp.host) do
    idx = i-1
    cmd  = cmd..string.format("# No.%03d \n", i)
    cmd  = cmd.."uci add dhcp host\n"
    cmd  = cmd..string.format("uci set dhcp.@host[-1].dns='%s'\n", e.dns  )
    cmd  = cmd..string.format("uci set dhcp.@host[-1].ip='%s'\n",  e.ip  )
    if e.mac then
      cmd  = cmd..string.format("uci set dhcp.@host[-1].mac='%s'\n", e.mac )
    end
    if  e.leasetime then
      cmd  = cmd..string.format("uci set dhcp.@host[-1].leasetime='%s'\n", e.leasetime  )
    end
    cmd  = cmd..string.format("uci set dhcp.@host[-1].name='%s'\n", e.name )
  end

  return cmd

end

function gen_uci_dhcp_host_delete_cmd()
  del_cmd = 'while uci del dhcp.@host[-1] 2>/dev/null 1> /dev/null; do : ;  done;'
  return "# delete exists\n"..del_cmd.."\n# Adding dhcp \n"
end


function gen_uci_sorted_dhcp_host()
  -- get exists dhcp.host
  local str  = get_uci_dhcp()
  local arr = uci_dhcp_host_to_lua_array(str)
  -- sort dhcp.host
  arr = sort_by_ip_addr(arr)
  -- generate command string
  local cmd = ''
  cmd = cmd..gen_uci_dhcp_host_delete_cmd(arr)
  cmd = cmd..gen_uci_dhcp_add_cmd(arr)
  return cmd
end

function update_and_commit_uci_with_sorted_dhcp()
  local commit_cmd = ''
  commit_cmd = 'uci commit dhcp\n'
  local cmd = gen_uci_sorted_dhcp_host()
  cmd = cmd..commit_cmd
  local handle = io.popen(cmd)
  local result = handle:read("*a")
end


function main()
  backup_uci_dhcp_host()
  update_and_commit_uci_with_sorted_dhcp()
end

if not pcall(debug.getlocal, 4, 1) then
  main();
end
