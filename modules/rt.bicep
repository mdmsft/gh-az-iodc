param resourceSuffix string
param firewallPrivateIpAddress string
param firewallPublicIpAddress string

resource routeTable 'Microsoft.Network/routeTables@2021-03-01' = {
  name: 'rt-${resourceSuffix}'
  location: resourceGroup().location
  properties: {
    routes: [
      {
        name: 'net-to-afw'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIpAddress
        }
      }
      {
        name: 'afw-to-www'
        properties: {
          addressPrefix: '${firewallPublicIpAddress}/32'
          nextHopType: 'Internet'
        }
      }
    ]
    disableBgpRoutePropagation: true
  }
}

output id string = routeTable.id
