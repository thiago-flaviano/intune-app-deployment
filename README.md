# intune-app-deployment

Implementações de apps Win32 via Microsoft Intune com foco em
deploy silencioso, detecção resiliente e princípio de Least Privilege.

## Apps documentados

| App | Contexto | Desafio | Solução |
|---|---|---|---|
| Google Drive File Stream | System | Detection quebrava a cada atualização | File exists em \current\ |
| DocuSign PKI | User | Looping eterno por contexto errado + NSIS case-sensitive | Wrapper PowerShell + /S |

## Princípios aplicados
- Least Privilege: User context apenas para apps Per-User
- Detecção resiliente: file exists em vez de versão específica
- Automação: wrapper PowerShell para higiene de processos

## Conexão com Zero Trust
Dispositivos gerenciados pelo Intune alimentam o Conditional Access
(Require compliant device) — complemento direto do azure-iam-labs.
