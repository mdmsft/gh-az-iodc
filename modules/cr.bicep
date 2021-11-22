
param resourceSuffix string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: 'cr${replace(resourceSuffix, '-', '')}'
  location: resourceGroup().location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Disabled'
    networkRuleSet: {
      defaultAction: 'Allow'
    }
  }
}

output id string = containerRegistry.id
