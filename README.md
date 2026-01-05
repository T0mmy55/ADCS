.DESCRITPION
+ This PowerShell script performs enterprise-wide SSL certificate inventory and expiry monitoring across Windows servers in an Active Directory domain. 
+ It discovers all domain-joined servers (excluding workstations), validates remote connectivity via ICMP and RPC, then enumerates certificates from all LocalMachine stores using the X509Store API.

.NOTES

├── [Input] Active Directory Domain Controllers/Servers (excl. WS*)
├── [Scan] All Certificate Stores (LocalMachine: Root, My, AuthRoot, etc.)
├── [Check] Remote access via WMI/RPC (Ping + Port 135)
├── [Extract] Cert details: Subject, Issuer, Thumbprint, Dates
├── [Analyze] Days to expiry, categorize (Expired/30d/90d/Year)
├── [Output] HTML Report w/ color-coded expiry status + Stats dashboard
└── [Stats] Total scanned, expiring counts by timeframe

.REQUIREMENTS 
+ Run on a Domain Controller OR domain-joined machine with RSAT installed
+ Requires Domain Admin or SPECIFIC access right to connect to remote machines
+ PowerShell v2 or above

.EXAMPLE
    .\Get_SSL_Certificates - v1.ps1

. Excecution and results 

<img width="650" height="403" alt="image" src="https://github.com/user-attachments/assets/67eb40c5-952a-4433-9b57-ab1a0d6be9cb" />

<img width="702" height="401" alt="image" src="https://github.com/user-attachments/assets/6ffe3d69-be4d-4a76-a91c-9234efaa53b4" />

<img width="959" height="353" alt="image" src="https://github.com/user-attachments/assets/67b83236-733d-4dfc-82b8-b09ece3ff6f8" />




