param subnetId string
param computerName string
param adminUsername string
param resourceSuffix string
param publicSshKeyData string

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: 'nic-${resourceSuffix}'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-${resourceSuffix}-${computerName}'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: publicSshKeyData
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-${resourceSuffix}-${computerName}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output identityPrincipalId string = virtualMachine.identity.principalId
