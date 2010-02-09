
class ResourceManeger
  def getInstances(hv_uuid)
    #hvc/hva_uuid‚©‚çinstance‚ð’T‚·
    instances = Hash.new()
    instances.store("count",3)
    rows = Array.new

    instance_uuid = "I-1001"
    instance = Hash.new()
    instance.store(:id,instance_uuid)
    #instance_uuid‚©‚çstatus‚ð‚Ð‚­
    instance.store(:status,"running")
    rows.push(instance)

    instance_uuid = "I-1002"
    instance = Hash.new()
    instance.store(:id,instance_uuid)
    instance.store(:status,"running")
    rows.push(instance)

    instance_uuid = "I-1003"
    instance = Hash.new()
    instance.store(:id,instance_uuid)
    instance.store(:status,"pending")
    rows.push(instance)

    instances.store(:rows,rows)

    instances
  end

  def getHV(server_uuid,level)
    level = level-1
    hvs   = Hash.new()
    hvs.store("count",2)
    rows = Array.new

    hv_uuid = "VC-2110"
    hv = Hash.new()
    hv.store(:id,hv_uuid)
    if level > 0
      hv.store(:instance,getInstances(hv_uuid))
    end
    rows.push(hv)

    hv_uuid = "VC-2120"
    hv = Hash.new()
    hv.store(:id,hv_uuid)
    if level > 0
      hv.store(:instance,getInstances(hv_uuid))
    end
    rows.push(hv)

    hvs.store(:rows,rows)

    hvs
  end

  def getServers(rack_uuid,level)
    level = level-1
    servers   = Hash.new()

    servers.store("count",2)
    rows = Array.new

    server_uuid = "S-2001"
    server = Hash.new()
    server.store(:id,server_uuid)
    if level > 0
      server.store(:hvs,getHV(server_uuid,level))
    end
    rows.push(server)

    server_uuid = "S-3001"
    server = Hash.new()
    server.store(:id,server_uuid)
    if level > 0
      server.store(:hvs,getHV(server_uuid,level))
    end
    rows.push(server)

    servers.store(:rows,rows)
    servers
  end

  def getRacks(map_uuid,level)
    level = level-1
    racks     = Hash.new()
    racks.store("count",2)
    rows = Array.new

    rack_uuid = "R-1001"
    rack = Hash.new()
    rack.store(:id,rack_uuid)
    rack.store(:x,200)
    rack.store(:y,200)
    if level > 0
      rack.store(:servers,getServers(rack_uuid,level))
    end
    rows.push(rack)

    rack_uuid = "R-1002"
    rack = Hash.new()
    rack.store(:id,rack_uuid)
    rack.store(:x,300)
    rack.store(:y,200)
    if level > 0
      rack.store(:servers,getServers(rack_uuid,level))
    end
    rows.push(rack)

    racks.store(:rows,rows)
    racks
  end

  def getMaps(level)
    level = level-1
    maps     = Hash.new()
    maps.store("count",3)
    rows = Array.new

    map_uuid = "M-1001"
    map = Hash.new()
    map.store(:id,map_uuid)
    map.store(:nm,"1F-100")
    map.store(:url,'./images/map/1F-10.jpeg')
    map.store(:grid,20)
    if level > 0
      map.store(:racks,getRacks(map_uuid,level))
    end
    rows.push(map)

    map_uuid = "M-1002"
    map = Hash.new()
    map.store(:id,map_uuid)
    map.store(:nm,"2F-100")
    map.store(:url,'./images/map/1F-10.jpeg')
    map.store(:grid,40)
    if level > 0
      map.store(:racks,getRacks(map_uuid,level))
    end
    rows.push(map)

    map_uuid = "M-1003"
    map = Hash.new()
    map.store(:id,map_uuid)
    map.store(:nm,"2F-200")
    map.store(:url,'./images/map/1F-10.jpeg')
    map.store(:grid,30)
    if level > 0
      map.store(:racks,getRacks(map_uuid,level))
    end
    rows.push(map)

    maps.store(:rows,rows)
    maps
  end

  module Constants
     HV_ONLY = 1
     HV_IS = 2
     SV_ONLY = 1
     SV_HV = 2
     SV_HV_IS = 3
     R_ONLY = 1
     R_SV = 2
     R_SV_HV = 3
     R_SV_HV_IS = 4
     M_ONLY = 1
     M_R = 2
     M_R_SV = 3
     M_R_SV_HV = 4
     M_R_SV_HV_IS = 5
  end
  include Constants

end
