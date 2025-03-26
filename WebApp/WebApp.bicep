// Parameters
param virtualNetworks_WebAppVNet_name string = 'WebAppVNet'
param virtualMachines_WebServerVM_name string = 'WebServerVM'
param networkSecurityGroups_WebAppNSG_name string = 'WebAppNSG'
param networkInterfaces_webservervm898_name string = 'webservervm898'
param publicIPAddresses_WebServerVM_ip_name string = 'WebServerVM-ip'
param adminUsername string // Added to avoid hardcoded value

// Network Security Group (NSG)
resource networkSecurityGroups_WebAppNSG_name_resource 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: networkSecurityGroups_WebAppNSG_name
  location: 'australiasoutheast'
  properties: {
    securityRules: [
      {
        name: 'AllowAnySSHInbound'
        properties: { // Removed id reference to break cyclic dependency
          description: 'AllowAnySSHInbound'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAnyHTTPInbound'
        properties: { // Removed id reference to break cyclic dependency
          description: 'AllowAnyHTTPInbound'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

// Public IP Address
resource publicIPAddresses_WebServerVM_ip_name_resource 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIPAddresses_WebServerVM_ip_name
  location: 'australiasoutheast'
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

// Virtual Network (VNet)
resource virtualNetworks_WebAppVNet_name_resource 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworks_WebAppVNet_name
  location: 'australiasoutheast'
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    privateEndpointVNetPolicies: 'Disabled'
    subnets: [
      {
        name: 'WebSubnet'
        properties: { // Removed id reference to break cyclic dependency
          addressPrefixes: ['10.0.1.0/24']
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

// Network Interface (NIC)
resource networkInterfaces_webservervm898_name_resource 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: networkInterfaces_webservervm898_name
  location: 'australiasoutheast'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: { // Removed self-referencing id
          privateIPAddress: '10.0.1.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_WebServerVM_ip_name_resource.id
            properties: {
              deleteOption: 'Delete'
            }
          }
          subnet: {
            id: '${virtualNetworks_WebAppVNet_name_resource.id}/subnets/WebSubnet' // Fixed reference to subnet
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups_WebAppNSG_name_resource.id
    }
  }
  dependsOn: [
    virtualNetworks_WebAppVNet_name_resource
    publicIPAddresses_WebServerVM_ip_name_resource
    networkSecurityGroups_WebAppNSG_name_resource
  ]
}

// Virtual Machine (VM)
resource virtualMachines_WebServerVM_name_resource 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: virtualMachines_WebServerVM_name
  location: 'australiasoutheast'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${virtualMachines_WebServerVM_name}_OsDisk_1_bd6837196e3e4b2a8a3c681b9c55ff84'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 30
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: virtualMachines_WebServerVM_name
      adminUsername: adminUsername // Use parameter instead of hardcoded value
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_webservervm898_name_resource.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  dependsOn: [
    networkInterfaces_webservervm898_name_resource
  ]
}
