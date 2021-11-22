param name string
param virtualNetworkId string

var zoneName = replace(name, '*', resourceGroup().location)

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: '${zoneName}-hub'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetworkId
      }
    }
  }
}

output id string = privateDnsZone.id
output name string = privateDnsZone.name
