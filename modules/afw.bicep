param subnetId string
param resourceSuffix string
param sourceAddresses array
param networkRules array
param applicationRules array

var defaultNetworkRules = [
  {
    name: 'net-aks-udp'
    ruleType: 'NetworkRule'
    ipProtocols: [
      'UDP'
    ]
    destinationFqdns: [
      'AzureCloud.${resourceGroup().location}'  // control plane for public AKS (UDP)
    ]
    destinationPorts: [
      '1194'
    ]
    sourceAddresses: sourceAddresses
  }
  {
    name: 'net-aks-tcp'
    ruleType: 'NetworkRule'
    ipProtocols: [
      'TCP'
    ]
    destinationAddresses: [
      'AzureCloud.${resourceGroup().location}'  // control plane for public AKS (TCP)
    ]
    destinationPorts: [
      '9000'
    ]
    sourceAddresses: sourceAddresses
  }
  {
    name: 'ntp'
    ruleType: 'NetworkRule'
    ipProtocols: [
      'UDP'
    ]
    destinationFqdns: [
      'ntp.ubuntu.com'  // NTP
    ]
    destinationPorts: [
      '123'
    ]
    sourceAddresses: sourceAddresses
  }
]

var defaultApplicationRules = [
  {
    name: 'app-aks-azure'
    ruleType: 'ApplicationRule'
    fqdnTags: [
      'AzureKubernetesService'              // Azure-curated list of service tags and FQDNs for AKS egress
      'AzureMonitor'
      'Storage.${resourceGroup().location}' // Control plane diagnostic logs backend
    ]
    sourceAddresses: sourceAddresses
    protocols: [
      {
        port: 80
        protocolType: 'Http'
      }
      {
        port: 443
        protocolType: 'Https'
      }
    ]
  }
]

var customNetworkRules = [for networkRule in networkRules: {
  name: networkRule.name
  ruleType: 'NetworkRule'
  ipProtocols: networkRule.protocols
  destinationAddresses: networkRule.addresses
  destinationFqdns: networkRule.fqdns
  destinationPorts: networkRule.ports
  description: networkRule.description
  sourceAddresses: union(sourceAddresses, networkRule.sources)
}]

var customApplicationRules = [for applicationRule in applicationRules: {
  name: applicationRule.name
  ruleType: 'ApplicationRule'
  targetFqdns: applicationRule.fqdns
  description: applicationRule.description
  sourceAddresses: union(sourceAddresses, applicationRule.sources)
  protocols: [
    {
      port: 443
      protocolType: 'Https'
    }
  ]
}]

resource firewallPublicIpAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-${resourceSuffix}-afw'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: 'afw-${resourceSuffix}'
  location: resourceGroup().location
  properties: {
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: firewallPublicIpAddress.id
          }
        }
      }
    ]
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-03-01' = {
  name: 'afwp-${resourceSuffix}'
  location: resourceGroup().location
  properties: {
    dnsSettings: {
      enableProxy: true
    }
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
  }

  resource ruleCollectionGroup 'ruleCollectionGroups' = {
    name: 'default'
    properties: {
      priority: 100
      ruleCollections: [
        {
          name: 'net'
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: union(defaultNetworkRules, customNetworkRules)
        }
        {
          name: 'app'
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          priority: 300
          action: {
            type: 'Allow'
          }
          rules: union(defaultApplicationRules, customApplicationRules)
        }
      ]
    }
  }
}

output publicIpAddress string = firewallPublicIpAddress.properties.ipAddress
output privateIpAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
