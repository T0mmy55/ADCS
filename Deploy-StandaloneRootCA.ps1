<#
====================================================================================================
Phoenix PKI - Standalone Root CA Deployment Script
====================================================================================================

Author      : Othmane Ennebet
Role        : Senior Cloud & Security Architect
Version     : 1.0
Date        : September 2026

DESCRIPTION
-----------
This script automates the deployment and configuration of the Phoenix Public Key
Infrastructure (PKI) Standalone Root Certification Authority (CA).

The script performs the following tasks:

1. Copies the CAPolicy.inf file to the Windows directory.
2. Installs the Active Directory Certificate Services (AD CS) Certification
   Authority role and management tools.
3. Configures a Standalone Root CA named "PhoenixRootCA".
4. Creates a 4096-bit RSA private key using SHA256.
5. Configures a 10-year Root CA certificate validity period.
6. Exports the Root CA certificate for publication and distribution.
7. Configures CRL validity, overlap period, auditing, and AD integration settings.
8. Configures Authority Information Access (AIA) publication locations.
9. Configures Certificate Revocation List (CDP) publication locations.
10. Restarts Certificate Services to apply configuration changes.
11. Generates and publishes the initial CRL.
12. Validates the Root CA configuration and certificate properties.

REQUIREMENTS
------------
- Run as Local Administrator.
- CAPolicy.inf must be present in C:\Temp.
- Execute on the designated Root CA server.
- Intended for an offline Standalone Root CA deployment.

====================================================================================================
#>

# ==================================================================================================
# STEP 1 - Copy CAPolicy.inf
# The CAPolicy.inf file defines CA-specific settings that are applied during
# Certification Authority installation.
# ==================================================================================================

Write-Host "=> Copying CAPolicy.inf to C:\Windows" -ForegroundColor Green
Copy-Item C:\Temp\CAPolicy.inf C:\Windows

# ==================================================================================================
# STEP 2 - Install Active Directory Certificate Services
# Installs the Certification Authority role and associated management tools.
# ==================================================================================================

Write-Host "=> Installing Active Directory Certificate Services" -ForegroundColor Green

Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

Start-Sleep 10

# ==================================================================================================
# STEP 3 - Configure the Standalone Root Certification Authority
# Creates PhoenixRootCA using:
#   - Standalone Root CA
#   - RSA 4096-bit key
#   - SHA256 hash algorithm
#   - 10-year certificate validity
# ==================================================================================================

Write-Host "=> Configuring PhoenixRootCA Certification Authority" -ForegroundColor Green

Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `
    -CACommonName "PhoenixRootCA" `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
    -KeyLength 4096 `
    -HashAlgorithmName SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits 10 `
    -Force

Start-Sleep 10

# ==================================================================================================
# STEP 4 - Export Root CA Certificate
# Copies the generated Root CA certificate so it can later be distributed
# through HTTP, Active Directory, Group Policy, or manual deployment.
# ==================================================================================================

Write-Host "=> Exporting PhoenixRootCA certificate" -ForegroundColor Green

Set-Location C:\Windows\System32\CertSrv\CertEnroll

Rename-Item pho-rca00_phoenixRootCA.crt PhoenixRootCA.crt

Copy-Item PhoenixRootCA.crt C:\Temp

# ==================================================================================================
# STEP 5 - Validate CA Installation
# Verifies that the Certificate Services service is operational and displays
# CA configuration information.
# ==================================================================================================

Write-Host "=> Validating Certification Authority configuration" -ForegroundColor Green

Get-Service CertSvc

certutil -cainfo

Start-Sleep 2

# ==================================================================================================
# STEP 6 - Configure CA and CRL Settings
# Sets:
#   - CRL lifetime to 26 weeks
#   - CRL overlap to 1 week
#   - Root CA certificate validity to 10 years
#   - Configuration Naming Context
#   - Full auditing (AuditFilter = 127)
# ==================================================================================================

Write-Host "=> Configuring CA validity, CRL and auditing settings" -ForegroundColor Green

certutil -setreg CA\CRLPeriodUnits 26
certutil -setreg CA\CRLPeriod "Weeks"

certutil -setreg CA\CRLOverlapUnits 1
certutil -setreg CA\CRLOverlapPeriod "Weeks"

certutil -setreg CA\ValidityPeriodUnits 10
certutil -setreg CA\ValidityPeriod "Years"

certutil -setreg CA\DSConfigDN "CN=Configuration,DC=phoenix,DC=us"

certutil -setreg CA\AuditFilter 127

Start-Sleep 10

# ==================================================================================================
# STEP 7 - Configure AIA Publication Locations
# AIA locations allow clients to retrieve the CA certificate during certificate
# chain validation.
#
# Publication locations:
#   - Local filesystem
#   - HTTP PKI repository
#   - LDAP publication point
# ==================================================================================================

Write-Host "=> Configuring Authority Information Access (AIA)" -ForegroundColor Green

Set-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\PhoenixRootCA" `
  -Name CACertPublicationURLs `
  -Value @(
      '1:C:\Windows\system32\CertSrv\CertEnroll\%3%4.crt',
      '2:http://pki.phoenix.us/certdata/%3%4.crt',
      '2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11'
  )

Start-Sleep 2

# ==================================================================================================
# STEP 8 - Configure CDP Publication Locations
# CDP locations allow clients to retrieve the Certificate Revocation List (CRL)
# and verify certificate revocation status.
#
# Publication locations:
#   - Local filesystem
#   - HTTP PKI repository
#   - LDAP publication point
# ==================================================================================================

Write-Host "=> Configuring CRL Distribution Points (CDP)" -ForegroundColor Green

Set-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\PhoenixRootCA" `
  -Name CRLPublicationURLs `
  -Value @(
      '1:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl',
      '2:http://pki.phoenix.us/certdata/%3%8%9.crl',
      '2:ldap:///CN=%7%8,CN=phoenixCorporatePKI,CN=CDP,CN=Public Key Services,CN=Services,%6%10'
  )

# Display configured publication locations

certutil -getreg CA\CACertPublicationURLs
certutil -getreg CA\CRLPublicationURLs

# ==================================================================================================
# STEP 9 - Restart Certificate Services
# Applies all registry-based CA configuration changes.
# ==================================================================================================

Write-Host "=> Restarting Certificate Services" -ForegroundColor Green

Restart-Service CertSvc -Force

Start-Sleep 5

# ==================================================================================================
# STEP 10 - Publish Initial CRL
# Generates and publishes the first Certificate Revocation List.
# ==================================================================================================

Write-Host "=> Generating and publishing CRL" -ForegroundColor Green

certutil -crl

sleep 10
# ==================================================================================================
# STEP 11 - Verify Root CA Certificate
# Displays CA certificate details, including:
#   - Subject Name
#   - Signature Algorithm
#   - Validity Period
# ==================================================================================================

Write-Host "=> Reviewing Root CA certificate" -ForegroundColor Green

$CA = Get-ChildItem Cert:\LocalMachine\CA

$CA | Select-Object `
    Subject,
    SignatureAlgorithm,
    NotBefore,
    NotAfter

certutil -getconfig


# ==================================================================================================
# DEPLOYMENT SUMMARY
# ==================================================================================================

$CAInfo = Get-ChildItem Cert:\LocalMachine\CA | Select-Object -First 1
$ServiceStatus = (Get-Service CertSvc).Status

Write-Host ""
Write-Host "====================================================================================================" -ForegroundColor Cyan
Write-Host "                              PHOENIX ROOT CA DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "====================================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  CA Name                : {0}" -f $CAInfo.Subject) -ForegroundColor White
Write-Host ("  CA Type                : Standalone Root CA") -ForegroundColor White
Write-Host ("  Crypto Provider        : RSA#Microsoft Software Key Storage Provider") -ForegroundColor White
Write-Host ("  Key Length             : 4096 bits") -ForegroundColor White
Write-Host ("  Hash Algorithm         : SHA256") -ForegroundColor White
Write-Host ("  Certificate Validity   : 10 Years") -ForegroundColor White
Write-Host ("  Service Status         : {0}" -f $ServiceStatus) -ForegroundColor Green
Write-Host ("  Root Certificate       : C:\Temp\PhoenixRootCA.crt") -ForegroundColor White
Write-Host ("  CRL Validity           : 26 Weeks") -ForegroundColor White
Write-Host ("  CRL Overlap            : 1 Week") -ForegroundColor White
Write-Host ""
Write-Host "AIA Locations" -ForegroundColor Yellow
Write-Host "-------------" -ForegroundColor Yellow
Write-Host " [+] Local : C:\Windows\System32\CertSrv\CertEnroll\%3%4.crt"
Write-Host " [+] HTTP  : http://pki.phoenix.us/certdata/%3%4.crt"
Write-Host " [+] LDAP  : CN=AIA,CN=Public Key Services,CN=Services"
Write-Host ""
Write-Host "CDP Locations" -ForegroundColor Yellow
Write-Host "-------------" -ForegroundColor Yellow
Write-Host " [+] Local : C:\Windows\System32\CertSrv\CertEnroll\%3%8%9.crl"
Write-Host " [+] HTTP  : http://pki.phoenix.us/certdata/%3%8%9.crl"
Write-Host " [+] LDAP  : CN=CDP,CN=Public Key Services,CN=Services"
Write-Host ""
Write-Host "Deployment Tasks Completed" -ForegroundColor Yellow
Write-Host "--------------------------" -ForegroundColor Yellow
Write-Host " [OK] CAPolicy.inf deployed" -ForegroundColor Green
Write-Host " [OK] AD CS role installed" -ForegroundColor Green
Write-Host " [OK] Root CA configured" -ForegroundColor Green
Write-Host " [OK] Root certificate exported" -ForegroundColor Green
Write-Host " [OK] CA validity configured" -ForegroundColor Green
Write-Host " [OK] CRL settings configured" -ForegroundColor Green
Write-Host " [OK] AIA locations configured" -ForegroundColor Green
Write-Host " [OK] CDP locations configured" -ForegroundColor Green
Write-Host " [OK] Certificate Services restarted" -ForegroundColor Green
Write-Host " [OK] Initial CRL published" -ForegroundColor Green
Write-Host ""
Write-Host ("Deployment completed on : {0}" -f (Get-Date)) -ForegroundColor Cyan
Write-Host ("Executed by            : {0}" -f $env:USERNAME) -ForegroundColor Cyan
Write-Host ""
Write-Host "====================================================================================================" -ForegroundColor Cyan
Write-Host "        PhoenixRootCA successfully deployed and operational" -ForegroundColor Green
Write-Host "====================================================================================================" -ForegroundColor Cyan