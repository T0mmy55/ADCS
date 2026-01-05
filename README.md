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

<img width="977" height="485" alt="image" src="https://github.com/user-attachments/assets/73767aaa-daf0-4b4b-9158-86a1041bd8bc" />

<img width="980" height="512" alt="image" src="https://github.com/user-attachments/assets/3b8a9249-a12e-4ea5-928c-3560f3124d82" />

<img width="977" height="511" alt="image" src="https://github.com/user-attachments/assets/e4c04df7-c83a-4757-bdbc-69d08dd7bfba" />

<img width="959" height="353" alt="image" src="https://github.com/user-attachments/assets/67b83236-733d-4dfc-82b8-b09ece3ff6f8" />




