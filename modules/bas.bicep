param resourceSuffix string
param subnetId string

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: 'pip-${resourceSuffix}-bas'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: 'bas-${resourceSuffix}'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          publicIPAddress: {
            id: publicIpAddress.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}
