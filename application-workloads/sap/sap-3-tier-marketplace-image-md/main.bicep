@description('SAP System ID.')
@minLength(3)
@maxLength(3)
param sapSystemId string = 'DEQ'

@description('The stack type of the SAP system.')
@allowed([
  'ABAP'
  'JAVA'
  'ABAP+JAVA'
])
param stackType string = 'ABAP'

@description('The type of the operating system you want to deploy.')
@allowed([
  'Windows Server 2012 Datacenter'
  'Windows Server 2012 R2 Datacenter'
  'Windows Server 2016 Datacenter'
  'Windows Server 2019 Datacenter'
  'Windows Server 2022 Datacenter: Azure Edition - Gen2'
  'SLES 15'
  'RHEL 7'
  'Oracle Linux 7'
])
param osType string = 'Windows Server 2022 Datacenter: Azure Edition - Gen2'

@description('The type of the database')
@allowed([
  'SQL'
  'HANA'
])
param dbtype string = 'SQL'

@description('The size of the SAP System you want to deploy.')
@allowed([
  'Demo'
  'Small < 30.000 SAPS'
  'Medium < 70.000 SAPS'
  'Large < 180.000 SAPS'
  'X-Large < 250.000 SAPS'
])
param sapSystemSize string = 'Small < 30.000 SAPS'

@description('Determines whether this is a high available deployment or not. A HA deployment contains multiple instances of single point of failures.')
@allowed([
  'HA'
  'Not HA'
])
param systemAvailability string = 'Not HA'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine.')
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'password'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('Zone numbers. Enter the comma seperated zones you want use e.g. 1,3. In an HA case, the first two will be used for the cluster VMs.')
param availabilityZones string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string = ''

var azArray = split(availabilityZones, ',')
var azArrayLength = length(azArray)
var images = {
  'Windows Server 2012 Datacenter': {
    sku: '2012-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'Windows Server 2012 R2 Datacenter': {
    sku: '2012-R2-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'Windows Server 2019 Datacenter': {
    sku: '2019-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'Windows Server 2022 Datacenter: Azure Edition - Gen2': {
    sku: '2022-Datacenter-Azure-Edition'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    OSType: 'Windows'
  }
  'SLES 15': {
    sku: 'gen1'
    offer: 'sles-sap-15-sp5-byos'
    publisher: 'SUSE'
    OSType: 'Linux'
  }
  'RHEL 7': {
    sku: '7.5'
    offer: 'RHEL-SAP'
    publisher: 'RedHat'
    OSType: 'Linux'
  }
  'Oracle Linux 7': {
    sku: '7.5'
    offer: 'Oracle-Linux'
    publisher: 'Oracle'
    OSType: 'Linux'
  }
}
var internalOSType = images[osType].OSType
var csExtension = {
  Windows: {
    Publisher: 'Microsoft.Compute'
    Name: 'CustomScriptExtension'
    Version: '1.7'
    script: uri(_artifactsLocation, 'diskConfig.ps1${_artifactsLocationSasToken}')
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File diskConfig.ps1'
  }
  Linux: {
    Publisher: 'Microsoft.Azure.Extensions'
    Name: 'CustomScript'
    Version: '2.0'
    script: uri(_artifactsLocation, 'diskConfig.sh${_artifactsLocationSasToken}')
    scriptCall: 'sh diskConfig.sh'
  }
}
var sizes = {
  Demo: {
    HANA: {
      dbvmSize: 'Standard_D4s_v3'
      ascsVMSize: 'Standard_D2s_v3'
      diVMSize: 'Standard_D2s_v3'
      diVMCount: 1
      dbdisks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 5
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1#2,3#4#5#6,7\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\'  -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: false
    }
    SQL: {
      dbvmSize: 'Standard_D4s_v3'
      ascsVMSize: 'Standard_D2s_v3'
      diVMSize: 'Standard_D2s_v3'
      diVMCount: 1
      dbdisks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Windows: '-luns "0" -names "data" -paths "C:\\sql\\data,C:\\sql\\log"  -sizes "70,100"'
      }
      useFastNetwork: false
    }
    other: {
      dbvmSize: 'Standard_D4s_v3'
      ascsVMSize: 'Standard_D2s_v3'
      diVMSize: 'Standard_D2s_v3'
      diVMCount: 1
      dbdisks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0\' -names \'datalog\' -paths \'/db/data,/db/log\'  -sizes \'70,100\''
        Windows: '-luns "0" -names "data" -paths "C:\\db\\data,C:\\db\\log"  -sizes "70,100"'
      }
      useFastNetwork: false
    }
  }
  'Small < 30.000 SAPS': {
    HANA: {
      dbvmSize: 'Standard_E32s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E8s_v3'
      diVMCount: 1
      dbdisks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3#4#5\' -names \'datalog#shared#usrsap#backup\' -paths \'/hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'70,100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      dbvmSize: 'Standard_E8s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E8s_v3'
      diVMCount: 1
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3#4" -names "data#log" -paths "C:\\sql\\data#C:\\sql\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
    other: {
      dbvmSize: 'Standard_E8s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E8s_v3'
      diVMCount: 1
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2,3,4\' -names \'datalog\' -paths \'/db/data,/db/log\' -sizes \'70,100\''
        Windows: '-luns "0,1,2,3#4" -names "data#log" -paths "C:\\sql\\data#C:\\sql\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
  }
  'Medium < 70.000 SAPS': {
    HANA: {
      dbvmSize: 'Standard_E64s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E8s_v3'
      diVMCount: 4
      dbdisks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3#4#5\' -names \'datalog#shared#usrsap#backup\' -paths \'/hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'70,100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      dbvmSize: 'Standard_E16s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E8s_v3'
      diVMCount: 4
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3,4,5,6#7" -names "data#log" -paths "C:\\sql\\data#C:\\sql\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
    other: {
      dbvmSize: 'Standard_E16s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E8s_v3'
      diVMCount: 4
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2,3,4,5,6,7\' -names \'datalog\' -paths \'/db/data,/db/log\'  -sizes \'70,100\''
        Windows: '-luns "0,1,2,3,4,5,6#7" -names "data#log" -paths "C:\\db\\data#C:\\db\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
  }
  'Large < 180.000 SAPS': {
    HANA: {
      dbvmSize: 'Standard_M64s'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E16s_v3'
      diVMCount: 6
      dbdisks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 8
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 9
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2,3#4,5#6#7#8,9\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      dbvmSize: 'Standard_E32s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E16s_v3'
      diVMCount: 6
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3,4#5" -names "data#log" -paths "C:\\sql\\data#C:\\sql\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
    other: {
      dbvmSize: 'Standard_E32s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E16s_v3'
      diVMCount: 6
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2,3,4,5\' -names \'datalog\' -paths \'/db/data,/db/log\'  -sizes \'70,100\''
        Windows: '-luns "0,1,2,3,4#5" -names "data#log" -paths "C:\\db\\data#C:\\db\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
  }
  'X-Large < 250.000 SAPS': {
    HANA: {
      dbvmSize: 'Standard_M128s'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E16s_v3'
      diVMCount: 10
      dbdisks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 2048
        }
        {
          lun: 8
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 2048
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3,4#5#6#7,8\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      dbvmSize: 'Standard_E64s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E16s_v3'
      diVMCount: 10
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Windows: '-luns "0,1,2,3,4,5,6#7" -names "data#log" -paths "C:\\sql\\data#C:\\sql\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
    other: {
      dbvmSize: 'Standard_E64s_v3'
      ascsVMSize: 'Standard_E2s_v3'
      diVMSize: 'Standard_E16s_v3'
      diVMCount: 10
      dbdisks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2,3,4,5,6,7\' -names \'datalog\' -paths \'/db/data,/db/log\'  -sizes \'70,100\''
        Windows: '-luns "0,1,2,3,4,5,6#7" -names "data#log" -paths "C:\\db\\data#C:\\db\\log"  -sizes "100#100"'
      }
      useFastNetwork: true
    }
  }
}
var dbvmCount = ((systemAvailability == 'HA') ? 2 : 1)
var ascsvmCount = ((systemAvailability == 'HA') ? 2 : 1)
var divmCountNonHA = sizes[sapSystemSize][dbtype].diVMCount
var divmCount = ((systemAvailability == 'HA') ? max(2, divmCountNonHA) : divmCountNonHA)
var dbVMSize = sizes[sapSystemSize][dbtype].dbvmSize
var ascsVMSize = sizes[sapSystemSize][dbtype].ascsVMSize
var diVMSize = sizes[sapSystemSize][dbtype].diVMSize
var dbDisks = sizes[sapSystemSize][dbtype].dbdisks
var sidlower = toLower(sapSystemId)
var vmName = sidlower
var vnetName = '${sidlower}-vnet'
var subnetName = 'Subnet'
var selectedSubnetId = subnetId
var publicIpNameASCSName = '${sidlower}-pip-ascs'
var avSetNameASCSName = '${sidlower}-avset-ascs'
var nsgName = '${sidlower}-nsg'
var loadBalancerNameASCSName = '${sidlower}-lb-ascs'
var loadBalancerNamePubASCSName = '${sidlower}-lb-pub-ascs'
var vmNameASCSName = '${vmName}-ascs'
var nicNameASCSName = '${sidlower}-nic-ascs'
var avSetNameDBName = '${sidlower}-avset-db'
var loadBalancerNameDBName = '${sidlower}-lb-db'
var loadBalancerNamePubDBName = '${sidlower}-lb-pub-db'
var nicNameDBName = '${sidlower}-nic-db'
var vmNameDBName = '${vmName}-db'
var avSetNameDIName = '${sidlower}-avset-di'
var nicNameDIName = '${sidlower}-nic-di'
var vmNameDIName = '${vmName}-di'
var osSecurityRules = {
  Windows: [
    {
      name: 'RDP'
      properties: {
        description: 'Allow RDP Subnet'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '3389'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
    }
  ]
  Linux: [
    {
      name: 'SSH'
      properties: {
        description: 'Allow SSH Subnet'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
    }
  ]
}
var selectedSecurityRules = osSecurityRules[internalOSType]
var scriptArgumentsASCSDI = {
  Linux: '-luns \'0\' -names \'usrsap\' -paths \'/usr/sap\'  -sizes \'100\''
  Windows: '-luns "0" -names "sap" -paths "S"  -sizes "100"'
}
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var frontendHANADB = 'frontendhdb'
var frontendSQLDB = 'frontendsql'
var frontendSQLCL = 'frontendsqlcl'
var frontendASCS = 'frontendascs'
var frontendAERS = 'frontendaers'
var frontendSCS = 'frontendscs'
var frontendERS = 'frontenders'
var frontendASCSCL = 'frontendascscl'
var frontendPubASCS = 'frontendpubascs'
var frontendPubDB = 'frontendpubdb'
var backendPoolHANADB = 'backendhdb'
var backendPoolSQLDB = 'backendsql'
var backendPoolSQLCL = 'backendsqlcl'
var backendPoolASCS = 'backendascs'
var backendPoolAERS = 'backendaers'
var backendPoolSCS = 'backendscs'
var backendPoolERS = 'backenders'
var backendPoolASCSCL = 'backendascscl'
var backendPoolPubASCS = 'backendpubascs'
var backendPoolPubDB = 'backendpubdb'
var probePortHANADB = 'probehdb'
var probePortSQLDB = 'probesql'
var probePortSQLCL = 'probesqlcl'
var probePortASCS = 'probeascs'
var probePortAERS = 'probeaers'
var probePortSCS = 'probescs'
var probePortERS = 'probeers'
var probePortASCSCL = 'probeascscl'
var dbInstanceNumberHANA = 4
var ascsInstanceNumber = 0
var scsInstanceNumber = 1
var aersInstanceNumber = 2
var ersInstanceNumber = 3
var probePortInternalHANADB = (62500 + dbInstanceNumberHANA)
var probePortInternalSQLDB = 62500
var probePortInternalSQLCL = 63500
var probePortInternalASCS = (62000 + ascsInstanceNumber)
var probePortInternalAERS = (62100 + aersInstanceNumber)
var probePortInternalSCS = (62000 + scsInstanceNumber)
var probePortInternalERS = (62100 + ersInstanceNumber)
var probePortInternalASCSCL = 63500
var lbRulePrefixHANADB = 'lb${padLeft(dbInstanceNumberHANA, 2, '0')}Rule'
var lbRulePrefixSQLDB = 'lbsqlRule'
var lbRulePrefixSQLCL = 'lbsqlclRule'
var lbRulePrefixASCS = 'lbascsRule'
var lbRulePrefixAERS = 'lbaersRule'
var lbRulePrefixSCS = 'lbscsRule'
var lbRulePrefixERS = 'lbersRule'
var lbRulePrefixASCSCL = 'lbascsclRule'
var idleTimeoutInMinutes = 30
var publicIpNameLBDBName = '${sidlower}-pip-lb-db'
var publicIpNameLBASCSName = '${sidlower}-pip-lb-ascs'
var pipIdDB = publicIpNameLBDBResource.id
var pipIdASCS = publicIpNameLBASCSResource.id
var lbFrontendConfigsDB = {
  HANA: {
    Linux: [
      {
        properties: {
          subnet: {
            id: selectedSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: frontendHANADB
      }
    ]
  }
  SQL: {
    Windows: [
      {
        properties: {
          subnet: {
            id: selectedSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: frontendSQLDB
      }
      {
        properties: {
          subnet: {
            id: selectedSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: frontendSQLCL
      }
    ]
  }
}
var lbFrontendConfigsABAP = [
  {
    properties: {
      subnet: {
        id: selectedSubnetId
      }
      privateIPAllocationMethod: 'Dynamic'
    }
    name: frontendASCS
  }
  {
    properties: {
      subnet: {
        id: selectedSubnetId
      }
      privateIPAllocationMethod: 'Dynamic'
    }
    name: frontendAERS
  }
]
var lbFrontendConfigJAVA = [
  {
    properties: {
      subnet: {
        id: selectedSubnetId
      }
      privateIPAllocationMethod: 'Dynamic'
    }
    name: frontendSCS
  }
  {
    properties: {
      subnet: {
        id: selectedSubnetId
      }
      privateIPAllocationMethod: 'Dynamic'
    }
    name: frontendERS
  }
]
var lbFrontendConfigIND = [
  {
    properties: {
      subnet: {
        id: selectedSubnetId
      }
      privateIPAllocationMethod: 'Dynamic'
    }
    name: frontendASCSCL
  }
]
var lbFrontendConfigXSCS = {
  ABAP: concat(lbFrontendConfigIND, lbFrontendConfigsABAP)
  JAVA: concat(lbFrontendConfigIND, lbFrontendConfigJAVA)
  'ABAP+JAVA': concat(lbFrontendConfigIND, lbFrontendConfigsABAP, lbFrontendConfigJAVA)
}
var lbBackendPoolsDB = {
  HANA: {
    Linux: [
      {
        name: backendPoolHANADB
      }
    ]
  }
  SQL: {
    Windows: [
      {
        name: backendPoolSQLDB
      }
      {
        name: backendPoolSQLCL
      }
    ]
  }
}
var lbBackendPoolsABAP = [
  {
    name: backendPoolASCS
  }
  {
    name: backendPoolAERS
  }
]
var lbBackendPoolJAVA = [
  {
    name: backendPoolSCS
  }
  {
    name: backendPoolERS
  }
]
var lbBackendPoolIND = [
  {
    name: backendPoolASCSCL
  }
]
var lbBackendPoolXSCS = {
  ABAP: concat(lbBackendPoolIND, lbBackendPoolsABAP)
  JAVA: concat(lbBackendPoolIND, lbBackendPoolJAVA)
  'ABAP+JAVA': concat(lbBackendPoolIND, lbBackendPoolsABAP, lbBackendPoolJAVA)
}
var lbRulesDB = {
  HANA: {
    Linux: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDBName, frontendHANADB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDBName, backendPoolHANADB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDBName, probePortHANADB)
          }
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixHANADB}${padLeft(dbInstanceNumberHANA, 2, '0')}all'
      }
    ]
  }
  SQL: {
    Windows: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDBName, frontendSQLDB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDBName, backendPoolSQLDB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDBName, probePortSQLDB)
          }
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixSQLDB}all'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDBName, frontendSQLCL)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDBName, backendPoolSQLCL)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDBName, probePortSQLCL)
          }
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixSQLCL}all'
      }
    ]
  }
}
var lbRulesABAP = [
  {
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameASCSName, frontendASCS)
      }
      backendAddressPool: {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolASCS)
      }
      probe: {
        id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameASCSName, probePortASCS)
      }
      protocol: 'All'
      frontendPort: 0
      backendPort: 0
      enableFloatingIP: true
      idleTimeoutInMinutes: idleTimeoutInMinutes
    }
    name: '${lbRulePrefixASCS}all'
  }
  {
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameASCSName, frontendAERS)
      }
      backendAddressPool: {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolAERS)
      }
      probe: {
        id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameASCSName, probePortAERS)
      }
      protocol: 'All'
      frontendPort: 0
      backendPort: 0
      enableFloatingIP: true
      idleTimeoutInMinutes: idleTimeoutInMinutes
    }
    name: '${lbRulePrefixAERS}all'
  }
]
var lbRulesJAVA = [
  {
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameASCSName, frontendSCS)
      }
      backendAddressPool: {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolSCS)
      }
      probe: {
        id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameASCSName, probePortSCS)
      }
      protocol: 'All'
      frontendPort: 0
      backendPort: 0
      enableFloatingIP: true
      idleTimeoutInMinutes: idleTimeoutInMinutes
    }
    name: '${lbRulePrefixSCS}all'
  }
  {
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameASCSName, frontendERS)
      }
      backendAddressPool: {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolERS)
      }
      probe: {
        id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameASCSName, probePortERS)
      }
      protocol: 'All'
      frontendPort: 0
      backendPort: 0
      enableFloatingIP: true
      idleTimeoutInMinutes: idleTimeoutInMinutes
    }
    name: '${lbRulePrefixERS}all'
  }
]
var lbRulesIND = [
  {
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameASCSName, frontendASCSCL)
      }
      backendAddressPool: {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolASCSCL)
      }
      probe: {
        id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameASCSName, probePortASCSCL)
      }
      protocol: 'All'
      frontendPort: 0
      backendPort: 0
      enableFloatingIP: true
      idleTimeoutInMinutes: idleTimeoutInMinutes
    }
    name: '${lbRulePrefixASCSCL}all'
  }
]
var lbRuleXSCS = {
  ABAP: concat(lbRulesIND, lbRulesABAP)
  JAVA: concat(lbRulesIND, lbRulesJAVA)
  'ABAP+JAVA': concat(lbRulesIND, lbRulesABAP, lbRulesJAVA)
}
var lbProbesDB = {
  HANA: {
    Linux: [
      {
        properties: {
          protocol: 'Tcp'
          port: probePortInternalHANADB
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: probePortHANADB
      }
    ]
  }
  SQL: {
    Windows: [
      {
        properties: {
          protocol: 'Tcp'
          port: probePortInternalSQLDB
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: probePortSQLDB
      }
      {
        properties: {
          protocol: 'Tcp'
          port: probePortInternalSQLCL
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: probePortSQLCL
      }
    ]
  }
}
var lbProbesABAP = [
  {
    properties: {
      protocol: 'Tcp'
      port: probePortInternalASCS
      intervalInSeconds: 5
      numberOfProbes: 2
    }
    name: probePortASCS
  }
  {
    properties: {
      protocol: 'Tcp'
      port: probePortInternalAERS
      intervalInSeconds: 5
      numberOfProbes: 2
    }
    name: probePortAERS
  }
]
var lbProbesJAVA = [
  {
    properties: {
      protocol: 'Tcp'
      port: probePortInternalSCS
      intervalInSeconds: 5
      numberOfProbes: 2
    }
    name: probePortSCS
  }
  {
    properties: {
      protocol: 'Tcp'
      port: probePortInternalERS
      intervalInSeconds: 5
      numberOfProbes: 2
    }
    name: probePortERS
  }
]
var lbProbesIND = [
  {
    properties: {
      protocol: 'Tcp'
      port: probePortInternalASCSCL
      intervalInSeconds: 5
      numberOfProbes: 2
    }
    name: probePortASCSCL
  }
]
var lbProbeXSCS = {
  ABAP: concat(lbProbesIND, lbProbesABAP)
  JAVA: concat(lbProbesIND, lbProbesJAVA)
  'ABAP+JAVA': concat(lbProbesIND, lbProbesABAP, lbProbesJAVA)
}
var nicBackAddressPoolsDB = {
  HANA: {
    Linux: [
      {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNamePubDBName, backendPoolPubDB)
      }
      {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDBName, backendPoolHANADB)
      }
    ]
  }
  SQL: {
    Windows: [
      {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNamePubDBName, backendPoolPubDB)
      }
      {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDBName, backendPoolSQLDB)
      }
      {
        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDBName, backendPoolSQLCL)
      }
    ]
  }
}
var nicBackAddressPoolsABAP = [
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolASCS)
  }
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolAERS)
  }
]
var nicBackAddressPoolsJAVA = [
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolSCS)
  }
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolERS)
  }
]
var nicBackAddressPoolsIND = [
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameASCSName, backendPoolASCSCL)
  }
]
var nicBackAddressPoolsPub = [
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNamePubASCSName, backendPoolPubASCS)
  }
]
var nicBackAddressPoolsINDPub = ((length(subnetId) > 0) ? concat(nicBackAddressPoolsIND, nicBackAddressPoolsPub) : nicBackAddressPoolsIND)
var nicBackAddressPoolXSCS = {
  ABAP: concat(nicBackAddressPoolsINDPub, nicBackAddressPoolsABAP)
  JAVA: concat(nicBackAddressPoolsINDPub, nicBackAddressPoolsJAVA)
  'ABAP+JAVA': concat(nicBackAddressPoolsINDPub, nicBackAddressPoolsABAP, nicBackAddressPoolsJAVA)
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-05-01' = if (length(subnetId) == 0) {
  name: concat(nsgName)
  location: location
  properties: {
    securityRules: selectedSecurityRules
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-05-01' = if (length(subnetId) == 0) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource avSetNameASCSResource 'Microsoft.Compute/availabilitySets@2020-06-01' = if (length(availabilityZones) == 0) {
  name: avSetNameASCSName
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
}

resource publicIpNameLBASCSResource 'Microsoft.Network/publicIPAddresses@2020-05-01' = if ((ascsvmCount > 1) && (length(subnetId) > 0)) {
  name: publicIpNameLBASCSName
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource loadBalancerNamePubASCSResource 'Microsoft.Network/loadBalancers@2020-05-01' = if ((ascsvmCount > 1) && (length(subnetId) > 0)) {
  name: loadBalancerNamePubASCSName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendPubASCS
        properties: {
          publicIPAddress: {
            id: pipIdASCS
          }
        }
      }
    ]
    outboundRules: [
      {
        name: 'test'
        properties: {
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerNamePubASCSName, frontendPubASCS)
            }
          ]
          allocatedOutboundPorts: 1000
          idleTimeoutInMinutes: 4
          enableTcpReset: true
          protocol: 'All'
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNamePubASCSName, backendPoolPubASCS)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolPubASCS
      }
    ]
  }
}

resource publicIpNameASCSResource 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, ascsvmCount): if (length(subnetId) == 0) {
  name: '${publicIpNameASCSName}-${i}'
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: [
    vnet
  ]
}]

resource loadBalancerNameASCSResource 'Microsoft.Network/loadBalancers@2020-05-01' = if (ascsvmCount > 1) {
  name: loadBalancerNameASCSName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: lbFrontendConfigXSCS[stackType]
    backendAddressPools: lbBackendPoolXSCS[stackType]
    loadBalancingRules: lbRuleXSCS[stackType]
    probes: lbProbeXSCS[stackType]
  }
  dependsOn: [
    vnet
  ]
}

resource nicNameASCSResource 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, ascsvmCount): {
  name: '${nicNameASCSName}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: ((length(subnetId) == 0) ? json('{"id": "${resourceId('Microsoft.Network/publicIPAddresses', '${publicIpNameASCSName}-${i}')}"}') : json('null'))
          subnet: {
            id: selectedSubnetId
          }
          loadBalancerBackendAddressPools: ((ascsvmCount > 1) ? nicBackAddressPoolXSCS[stackType] : json('null'))
        }
      }
    ]
  }
  dependsOn: [
    publicIpNameASCSResource
    vnet
    loadBalancerNameASCSResource
    loadBalancerNamePubASCSResource
  ]
}]

resource vmNameASCSResource 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, ascsvmCount): {
  name: '${vmNameASCSName}-${i}'
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : array(azArray[(i % azArrayLength)]))
  properties: {
/*
    availabilitySet: ((azArrayLength == 0) ? avSetNameASCSResource.id : json('null'))
*/
    hardwareProfile: {
      vmSize: ascsVMSize
    }
    osProfile: {
      computerName: '${vmNameASCSName}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameASCSName}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameASCSName}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    nicNameASCSResource
  ]
}]

resource vmNameASCS_csExtension_internalOSType 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, ascsvmCount): {
  name: '${vmNameASCSName}-${i}/${csExtension[internalOSType].Name}'
  location: location
  properties: {
    publisher: csExtension[internalOSType].Publisher
    type: csExtension[internalOSType].Name
    typeHandlerVersion: csExtension[internalOSType].Version
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        csExtension[internalOSType].script
      ]
      commandToExecute: '${csExtension[internalOSType].scriptCall} ${scriptArgumentsASCSDI[internalOSType]}'
    }
  }
  dependsOn: [
    vmNameASCSResource
  ]
}]

resource avSetNameDBResource 'Microsoft.Compute/availabilitySets@2020-06-01' = if (length(availabilityZones) == 0) {
  name: avSetNameDBName
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
}

resource publicIpNameLBDBResource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIpNameLBDBName
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource loadBalancerNamePubDBResource 'Microsoft.Network/loadBalancers@2020-05-01' = if (ascsvmCount > 1) {
  name: loadBalancerNamePubDBName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendPubDB
        properties: {
          publicIPAddress: {
            id: pipIdDB
          }
        }
      }
    ]
    outboundRules: [
      {
        name: 'test'
        properties: {
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerNamePubDBName, frontendPubDB)
            }
          ]
          allocatedOutboundPorts: 1000
          idleTimeoutInMinutes: 4
          enableTcpReset: true
          protocol: 'All'
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNamePubDBName, backendPoolPubDB)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolPubDB
      }
    ]
  }
}

resource loadBalancerNameDBResource 'Microsoft.Network/loadBalancers@2020-05-01' = if (dbvmCount > 1) {
  name: loadBalancerNameDBName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: lbFrontendConfigsDB[dbtype][internalOSType]
    backendAddressPools: lbBackendPoolsDB[dbtype][internalOSType]
    loadBalancingRules: lbRulesDB[dbtype][internalOSType]
    probes: lbProbesDB[dbtype][internalOSType]
  }
  dependsOn: [
    vnet
  ]
}

resource nicNameDBResource 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, dbvmCount): {
  name: '${nicNameDBName}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: selectedSubnetId
          }
          loadBalancerBackendAddressPools: ((dbvmCount > 1) ? nicBackAddressPoolsDB[dbtype][internalOSType] : json('null'))
        }
      }
    ]
  }
  dependsOn: [
    vnet
    loadBalancerNameDBResource
    loadBalancerNamePubDBResource
  ]
}]

resource vmNameDBResource 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, dbvmCount): {
  name: '${vmNameDBName}-${i}'
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : array(azArray[(i % azArrayLength)]))
  properties: {
/*
    availabilitySet: ((azArrayLength == 0) ? avSetNameDBResource.id : json('null'))
*/
    hardwareProfile: {
      vmSize: dbVMSize
    }
    osProfile: {
      computerName: '${vmNameDBName}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameDBName}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: dbDisks
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameDBName}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    nicNameDBResource
  ]
}]

resource vmNameDB_csExtension_internalOSType 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, dbvmCount): {
  name: '${vmNameDBName}-${i}/${csExtension[internalOSType].Name}'
  location: location
  properties: {
    publisher: csExtension[internalOSType].Publisher
    type: csExtension[internalOSType].Name
    typeHandlerVersion: csExtension[internalOSType].Version
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        csExtension[internalOSType].script
      ]
      commandToExecute: '${csExtension[internalOSType].scriptCall} ${sizes[sapSystemSize][dbtype].scriptArguments[internalOSType]}'
    }
  }
  dependsOn: [
    vmNameDBResource
  ]
}]

resource avSetNameDIResource 'Microsoft.Compute/availabilitySets@2020-06-01' = if (length(availabilityZones) == 0) {
  name: avSetNameDIName
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
}

resource nicNameDIResource 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, divmCount): {
  name: '${nicNameDIName}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: selectedSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}]

resource vmNameDIResource 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, divmCount): {
  name: '${vmNameDIName}-${i}'
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : array(azArray[(i % azArrayLength)]))
  properties: {
/*
    availabilitySet: ((azArrayLength == 0) ? avSetNameDIResource.id : json('null'))
*/
    hardwareProfile: {
      vmSize: diVMSize
    }
    osProfile: {
      computerName: '${vmNameDIName}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameDIName}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameDIName}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    nicNameDIResource
  ]
}]

resource vmNameDI_csExtension_internalOSType 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, divmCount): {
  name: '${vmNameDIName}-${i}/${csExtension[internalOSType].Name}'
  location: location
  properties: {
    publisher: csExtension[internalOSType].Publisher
    type: csExtension[internalOSType].Name
    typeHandlerVersion: csExtension[internalOSType].Version
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        csExtension[internalOSType].script
      ]
      commandToExecute: '${csExtension[internalOSType].scriptCall} ${scriptArgumentsASCSDI[internalOSType]}'
    }
  }
  dependsOn: [
    vmNameDIResource
  ]
}]
