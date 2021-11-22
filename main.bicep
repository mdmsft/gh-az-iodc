param project string
param networkAddressPrefix string

param deployJumphost bool = false
param jumphostComputerName string
param jumphostAdminUsername string
param jumphostPublicSshKeyData string = ''

param firewallNetworkRules array
param firewallApplicationRules array
param firewallSubnetAddressPrefix string
param firewallSourceAddressPrefixes array

param bastionSubnetAddressPrefix string
param serviceSubnetAddressPrefix string
param virtualMachineSubnetAddressPrefix string

param privateDnsZones array = []

param tags object = {}

var resourceSuffix = '${project}-${deployment().location}'

var modulePrefix = '${deployment().name}-${resourceSuffix}'

var containerRegistryPrivateDnsZone = 'privatelink.azurecr.io'

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${resourceSuffix}'
  location: deployment().location
  tags: tags
}

module vnet 'modules/vnet.bicep' = {
  name: '${modulePrefix}-vnet'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    addressPrefix: networkAddressPrefix
    serviceSubnetAddressPrefix: serviceSubnetAddressPrefix
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
    firewallSubnetAddressPrefix: firewallSubnetAddressPrefix
    virtualMachineSubnetAddressPrefix: virtualMachineSubnetAddressPrefix
  }
}

module privateDns 'modules/dns.bicep' = [for privateDnsZone in privateDnsZones: {
  name: replace(privateDnsZone, '.*', '')
  scope: resourceGroup
  params: {
    name: privateDnsZone
    virtualNetworkId: vnet.outputs.id
  }
}]

module privateDnsZoneRegistry 'modules/dns.bicep' = {
  name: containerRegistryPrivateDnsZone
  scope: resourceGroup
  params: {
    name: containerRegistryPrivateDnsZone
    virtualNetworkId: vnet.outputs.id
  }
}

module registry 'modules/cr.bicep' = {
  name: '${modulePrefix}-cr'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
  }
}

module privateEndpointContainerRegistry 'modules/pe.bicep' = {
  name: '${modulePrefix}-pe-cr'
  scope: resourceGroup
  params: {
    name: 'cr-${resourceSuffix}'
    privateLinkServiceGroupId: 'registry'
    privateLinkServiceId: registry.outputs.id
    subnetId: vnet.outputs.serviceSubnetId
    privateDnsZoneId: privateDnsZoneRegistry.outputs.id
  }
}

module bas 'modules/bas.bicep' = {
  name: '${modulePrefix}-bas'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    subnetId: vnet.outputs.bastionSubnetId
  }
}

module firewall 'modules/afw.bicep' = {
  name: '${modulePrefix}-afw'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    subnetId: vnet.outputs.firewallSubnetId
    sourceAddresses: firewallSourceAddressPrefixes
    applicationRules: firewallApplicationRules
    networkRules: firewallNetworkRules
  }
}

module jumphost 'modules/vm.bicep' = if (deployJumphost) {
  name: '${modulePrefix}-${jumphostComputerName}'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    adminUsername: jumphostAdminUsername
    subnetId: vnet.outputs.virtualMachineSubnetId
    computerName: jumphostComputerName
    publicSshKeyData: jumphostPublicSshKeyData
  }
}

module routeTable 'modules/rt.bicep' = {
  name: '${modulePrefix}-rt'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    firewallPrivateIpAddress: firewall.outputs.privateIpAddress
    firewallPublicIpAddress: firewall.outputs.publicIpAddress
  }
}

output vnetId string = vnet.outputs.id
output registryId string = registry.outputs.id
output privateDnsZones array = [for i in range(0, length(privateDnsZones) - 1): {
  id: privateDns[i].outputs.id
  name: privateDns[i].outputs.name
}]
output firewallPrivateIpAddress string = firewall.outputs.privateIpAddress
output firewallPublicIpAddress string = firewall.outputs.publicIpAddress
