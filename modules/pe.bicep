param name string
param subnetId string
param privateLinkServiceGroupId string
param privateLinkServiceId string
param privateDnsZoneId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: 'pe-${name}'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          groupIds: [
            privateLinkServiceGroupId
          ]
          privateLinkServiceId: privateLinkServiceId
        }
      }
    ]
  }

  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'default'
          properties: {
            privateDnsZoneId: privateDnsZoneId
          }
        }
      ]
    }
  }
}
