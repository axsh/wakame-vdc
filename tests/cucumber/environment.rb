VDC_ROOT=File.dirname(__FILE__) + "/../.." unless defined?(VDC_ROOT)

TIMEOUT_BASE = 10
TIMEOUT_CREATE_INSTANCE = TIMEOUT_BASE * 20
TIMEOUT_TERMINATE_INSTANCE = TIMEOUT_BASE * 20

IO.popen("cd #{VDC_ROOT}/dcmgr && ./bin/vdc-debug vnet edges") { |debug_io|
  while !(line = debug_io.readline).nil?
    if line =~ /^result: ([a-z]*)$/
      HOST_NODES = JSON.parse(debug_io.read)
      break
    end
  end
}

raise("No host nodes found: #{HOST_NODES.inspect}.") if HOST_NODES.empty?
