#-
# Copyright (c) 2010 axsh co., LTD.
# All rights reserved.
#
# Author: Takahisa Kamiya
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

class ResourceManeger
  def getInstances(hv_uuid,top=false)
    #hvc/hva_uuid‚©‚çinstance‚ð’T‚·
    instances = Hash.new()
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

    if top
      instances.store(:instances,rows)
      instances
    else
      rows
    end
  end

  def getHV(server_uuid,level,top=false)
    level = level-1
    hvs   = Hash.new()
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

    if top
      hvs.store(:hvs,rows)
      hvs
    else
      rows
    end
  end

  def getServers(rack_uuid,level,top=false)
    level = level-1
    servers   = Hash.new()
    rows = Array.new

    server_uuid = "S-2001"
    server = Hash.new()
    server.store(:id,server_uuid)
    server.store(:name,"S-2001")
    if level > 0
      server.store(:hvs,getHV(server_uuid,level))
    end
    rows.push(server)

    server_uuid = "S-3001"
    server = Hash.new()
    server.store(:id,server_uuid)
    server.store(:name,"S-3001")
    if level > 0
      server.store(:hvs,getHV(server_uuid,level))
    end
    rows.push(server)

    if top
      servers.store(:servers,rows)
      servers
    else
      rows
    end
  end

  def getRacks(map_uuid,level,top=false)
    level = level-1
    racks = Hash.new()
    rows = Array.new

    rack_uuid = "R-1001"
    rack = Hash.new()
    rack.store(:id,rack_uuid)
    rack.store(:name,"R-1001")
    rack.store(:x,200)
    rack.store(:y,200)
    if level > 0
      rack.store(:servers,getServers(rack_uuid,level))
    end
    rows.push(rack)

    rack_uuid = "R-1002"
    rack = Hash.new()
    rack.store(:id,rack_uuid)
    rack.store(:name,"R-1002")
    rack.store(:x,300)
    rack.store(:y,200)
    if level > 0
      rack.store(:servers,getServers(rack_uuid,level))
    end
    rows.push(rack)

    if top
      racks.store(:racks,rows)
      racks
    else
      rows
    end
  end

  def getMaps(level)
    level = level-1
    maps  = Hash.new()
    rows = Array.new

    map_uuid = "M-1001"
    map = Hash.new()
    map.store(:id,map_uuid)
    map.store(:name,"1F-100")
    map.store(:url,'/images/map/1F-10.jpeg')
    map.store(:grid,20)
    map.store(:memo,'xxxxxx')
    if level > 0
      map.store(:racks,getRacks(map_uuid,level))
    end
    rows.push(map)

    map_uuid = "M-1002"
    map = Hash.new()
    map.store(:id,map_uuid)
    map.store(:name,"2F-100")
    map.store(:url,'/images/map/1F-10.jpeg')
    map.store(:memo,'xxxxxx')
    map.store(:grid,40)
    if level > 0
      map.store(:racks,getRacks(map_uuid,level))
    end
    rows.push(map)

    map_uuid = "M-1003"
    map = Hash.new()
    map.store(:id,map_uuid)
    map.store(:name,"2F-200")
    map.store(:url,'/images/map/1F-10.jpeg')
    map.store(:memo,'xxxxxx')
    map.store(:grid,30)
    if level > 0
      map.store(:racks,getRacks(map_uuid,level))
    end
    rows.push(map)

    maps.store(:count,rows.length)
    maps.store(:maps,rows)
    maps
  end

  module Constants
     HV_ONLY = 1				# HVC
     HV_IS = 2					# HVC & Instance
     SV_ONLY = 1				# Server
     SV_HV = 2					# Server & HVC
     SV_HV_IS = 3				# Server & HVC & Instance
     R_ONLY = 1					# Rack
     R_SV = 2					# Rack & Server
     R_SV_HV = 3				# Rack & Server & HVC
     R_SV_HV_IS = 4				# Rack & Server & HVC & Instance
     M_ONLY = 1					# MAP
     M_R = 2					# MAP & Rack
     M_R_SV = 3					# MAP & Rack & Server
     M_R_SV_HV = 4				# MAP & Rack & Server & HVC
     M_R_SV_HV_IS = 5			# MAP & Rack & Server & HVC & Instance
  end
  include Constants

end
