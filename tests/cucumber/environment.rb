VDC_ROOT=File.dirname(__FILE__) + "/../.." unless defined?(VDC_ROOT)

TIMEOUT_BASE = 10
TIMEOUT_CREATE_INSTANCE = TIMEOUT_BASE * 20
TIMEOUT_TERMINATE_INSTANCE = TIMEOUT_BASE * 20

HOST_NODES = {}

vnet_edges_debug = IO.popen("cd #{VDC_ROOT}/dcmgr && ./bin/vdc-debug vnet edges").readlines
vnet_edges_debug.each { |line|
  case line
  when /^(hva.[A-Za-z0-9]*): \ttype:([A-Za-z0-9]*)\n$/
    HOST_NODES[$1] = { :online => true, :type => $2 }
  when /^(hva.[A-Za-z0-9]*): \terror\n$/
    HOST_NODES[$1] = { :online => false, :type => nil }
  when /^(hva.[A-Za-z0-9]*):/
    raise("Parse error: '#{line}'.")
  end
}  

raise("No host nodes found: #{vnet_edges_debug.inspect}.") if HOST_NODES.empty?
