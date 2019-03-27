![PoshNmap Logo](images/PoshSNMP.png)
# PoshSNMP
[![PSGallery][]][PSGalleryLink] [![PSGalleryDL][]][PSGalleryDLLink]
---

A Powershell Module for querying SNMP information from network devices, leveraging the [#SNMP](https://www.sharpsnmp.com/) library by [LeXtudio](https://www.lextudio.com/).

[PSGallery]: https://img.shields.io/powershellgallery/v/PoshSNMP.svg?logo=windows&label=Powershell+Gallery+Latest
[PSGalleryLink]: https://www.powershellgallery.com/packages/PoshSNMP

[PSGalleryDL]: https://img.shields.io/powershellgallery/dt/PoshSNMP.svg?logo=windows&label=downloads
[PSGalleryDLLink]: https://www.powershellgallery.com/packages/PoshSNMP

# Why
Most of the other Powershell modules that leverage SNMP use SnmpSharpNet, which hasn't been updated in 4 years and is not Powershell Core Compatible. This module uses #SNMP which is core compatible and allows for a cross-platform deployment.

Unfortunately #SNMP's MIB functionality is licensed, so we fall back to the net-snmp cmdlets for now for some MIB translation and table activities until a better solution can be found.

# Features

* Intelligent Defaults (public community, version 2c, etc.)
* Convert SNMP Tables to Powershell Objects
* MIB OID Translation Support

# Demo

## SNMP Table (Get-SNMPTable returns Network Interfaces by default)
![](images/GetSnmpTable.gif)