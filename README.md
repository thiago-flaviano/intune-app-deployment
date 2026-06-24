![Labs](https://img.shields.io/badge/Labs-2%20concluídos-1DB87A?style=flat)
![Stack](https://img.shields.io/badge/Stack-Microsoft%20Intune-0078D4?style=flat&logo=microsoft)
![Framework](https://img.shields.io/badge/Framework-Zero%20Trust-7C6FE0?style=flat)
![Princípio](https://img.shields.io/badge/Princípio-Least%20Privilege-E8613A?style=flat)

# intune-app-deployment

Implementações de apps Win32 via Microsoft Intune com foco em deploy silencioso,
detecção resiliente e princípio de Least Privilege.

Todos os deploys foram realizados em ambiente corporativo real.

---

## Por que isso é relevante para IAM?

O Intune faz parte do ecossistema Microsoft Entra ID. Dispositivos gerenciados
pelo Intune são validados como **compliant** e alimentam diretamente as políticas
de **Conditional Access** — especificamente a condição `Require compliant device`.

```
Usuário autentica (Entra ID)
        +
Dispositivo gerenciado e conforme (Intune)
        ↓
Conditional Access libera acesso ✓
```

> Complemento direto do repositório [azure-iam-labs](https://github.com/thiago-flaviano/azure-iam-labs),
> onde foram configuradas as políticas de Conditional Access.

---

## Apps implementados

| App | Contexto | Principal desafio | Solução |
|---|---|---|---|
| Google Drive File Stream | System | Detection quebrava a cada atualização automática | `file exists` em `\current\` em vez de versão específica |
| DocuSign PKI | User | Loop infinito de instalação | Wrapper PowerShell + contexto correto (Per-User) + `/S` NSIS |

---

## Labs documentados

### Lab 01 — Google Drive File Stream

**Objetivo:** Distribuir o Google Drive como app opcional via Company Portal
sem conflito com versões instaladas manualmente pelos usuários.

**Configuração:**

| Campo | Valor |
|---|---|
| Formato | Win32 (.intunewin) |
| Assignment | Available for enrolled devices |
| Contexto | System |
| Detection Rule | `C:\Program Files\Google\Drive File Stream\current\GoogleDriveFS.exe` — file exists |

**Erros encontrados:**

| Código | Nome | Causa | Solução |
|---|---|---|---|
| `0x87D1041C` | App not detected | Detection usava código MSI de versão específica — Google se atualiza diariamente | Trocar para `file exists` em `\current\` |
| `0x80070666` | Another version installed | Conflito com versão instalada manualmente pelo usuário | Remover versão anterior antes do deploy |

**Decisão técnica:** Detection por `file exists` em vez de versão específica
torna a regra resiliente a atualizações automáticas — o Intune não quebra
quando o Google Drive se atualiza.

---

### Lab 02 — DocuSign PKI

**Objetivo:** Distribuir silenciosamente o DocuSign PKI (app Per-User)
resolvendo loop de instalação causado por contexto incorreto e parâmetro silencioso errado.

**Configuração:**

| Campo | Valor |
|---|---|
| Formato | Win32 (.intunewin) com wrapper PowerShell |
| Contexto | **User** — obrigatório para apps Per-User |
| Instalação | `.\DocuSignPKI.exe /S` — NSIS é case-sensitive |
| Desinstalação | `%LocalAppData%\DocuSignPKI\uninstall.exe /S` |
| Detection Rule | `%LocalAppData%\DocuSignPKI\DocuSignPKI.exe` — file exists |

**Por que User context e não System?**

O DocuSign instala em `%LocalAppData%` — perfil do usuário, não no sistema.
Usar System context (permissão de administrador) causava processos "fantasmas"
na memória que impediam instalações subsequentes.

> **Least Privilege na prática:** usar o menor contexto de permissão necessário.
> System context só quando o app realmente instala em `C:\Program Files`.

**Erros encontrados:**

| Sintoma | Causa | Solução |
|---|---|---|
| Loop infinito "Instalando..." | 1. `/silent` não reconhecido (NSIS exige `/S`). 2. System context para app Per-User | Corrigir para `/S` + mudar para User context |
| Processos travados na memória | Tentativas anteriores deixaram instâncias ativas | Wrapper PowerShell encerra processos antes de instalar |
| `install.ps1` não executado | Arquivo era `install.ps1.txt` — Windows ocultava extensão `.txt` | Ativar exibição de extensões e renomear corretamente |

**Script:** [`docusign-pki/install.ps1`](docusign-pki/install.ps1)

---

## Estrutura do repositório

```
intune-app-deployment/
└── docusign-pki/
    └── install.ps1    # Wrapper PowerShell documentado
```

---

## Lições aprendidas

| Lição | Princípio de IAM |
|---|---|
| Detection por `file exists`, não por versão | Políticas resilientes não quebram com mudanças menores |
| User context para Per-User, System para sistema | **Least Privilege** — mínimo de permissão necessário |
| `%LocalAppData%` em vez de caminho fixo | Identidade dinâmica — funciona para qualquer usuário |
| Wrapper encerra processos antes de instalar | Higiene de sessão — encerrar antes de criar novas |
| Intune gerencia dispositivos para o CA | **Device Identity** — dispositivo também tem identidade |

---

## Conexão com Zero Trust

Este repositório cobre o **pilar de dispositivo** do Zero Trust.
O [azure-iam-labs](https://github.com/thiago-flaviano/azure-iam-labs) cobre o **pilar de identidade**.

```
Zero Trust = Verificar identidade (Entra ID + CA)
           + Verificar dispositivo (Intune)
```

---

## Referências

- [Microsoft Intune — Win32 app deployment](https://learn.microsoft.com/pt-br/mem/intune/apps/apps-win32-app-management)
- [Zero Trust Architecture — NIST](https://www.nist.gov/publications/zero-trust-architecture)
- [CIS Microsoft Intune Benchmarks](https://www.cisecurity.org/benchmark/intune)
