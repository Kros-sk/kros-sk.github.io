# Build Machine

> Staré informácie pre build počítače, ktoré používajú Chocolatey, sú v [README-OLD.md](README-OLD.md)

Ak je to možné, je dobré mať pre agentov samostatný disk v počítači. Pototm je potrebné zadať správnu cestu k agentom
v parametri jednotlivých skriptov. Na nainštalovanie potrebných vecí a konfiguráciu build počítača slúžia skripty:

- `install.ps1`
- `configure.ps1`
- `configure-agents.ps1`

## Script `install-winget.ps1`

Ak je na rozbehávanej mašine Windows Server, tak Winget(použitý v ďalšom skripte na inštalácie) nie je defaultne nainštalovaný a pre jeho nainštalovanie je potrebné vykonať viacero krokov. Tento skript sa postará o všetko potrebné pre inštaláciu.
Ak potrebuješ konkrétnu verziu wingetu, tak cez parametre `-wingetVersion` a `-winGetLicenseFileName` si môžeš prispôsobiť. Potrebné dohľadať v [winget-cli releases](https://github.com/microsoft/winget-cli/releases)

## Skript `install.ps1`

Na inštaláciu bežných vecí sa používa **WinGet**. Je to nástroj priamo vo Windows, ktorý umožňuje inštalovať, aktualizovať
a odinštalovávať programy. Zoznam vecí čo sa na build počítač inštalujú je v súbore [`install.json`](install.json).
Zoznam programov je možné mať aj v inom súbore, ktorý sa špecifikuje pomocou parametra `-WingetJsonPath`.

Pri spustení súboru `install.ps1` sa nainštalujú/aktualizujú iba programy, definované v `install.json`. WinGet však umožňuje
aktualizovať všetky nainštalované programy. Spustením `winget upgrade` zobrazí zoznam programov, ktoré je možné aktualizovať.
Samotná aktualizácia sa spustí príkazom `winget upgrade --all`.

`install.ps1` aj `winget` je potrebné spúšťať ako administrátor.

### Azure CLI

Azure CLI je síce možné nainštalovať pomocou WinGet, ale toto sa ukázalo ako nespoľahlivé – inštalácia z nejakých dôvodov
náhodne padala. Preto `install.ps1` Azure CLI nainštaluje manuálne tak, že stiahne inštalačku a spustí ju.

### Kubectl

`kubectl` je nástroj na komunikáciu s Kubernetes. Tento nástroj sa inštaluje automaticky v `install.ps1`. Avšak na
počítači `BUILD5` bol problém, že samotné `exe` nemalo správne nastavené práva a tak ho bežný používateľ (build agent)
nevedel spustiť. Preto je po inštalácii toto potrebné preveriť. Súbor `kuibectl.exe` sa nachádza v zložke
`c:\Program Files\WinGet\Packages\Kubernetes.kubectl_Microsoft.Winget.Source_...\` a musí mať práva `Read`
a `Read and execute` pre skupinu `Users`. Ak ich nemá, je potrebné ich nastaviť.

## Skript `configure.ps1`

Skript nakonfiguruje na build počítači všetko potrebné a nainštaluje veci, ktoré nie je možné/vhodné inštalovať pomocou
`install.ps1`. Skript má nasledovné parametre (všetky nepovinné):

- `Proxy`: adresa proxy servera, zadaná aj so schémou a prípadným portom (`http://1.2.3:4:5678`). Predvolená hodnota je prázdny reťazec (bez proxy).
- `ToolsPath`: cesta k rôznym nástrojom. Táto cesta je pridaná do systémovej premennej `PATH`, aby nástroje boli globálne dostupné. Predvolená hodnota je `C:\tools`,
- `CachePath`: cesta, kde sa nastaví keš pre rôzne programy (NPM, Cypress…). Predvolená hodnota je `C:\cache`.

Skrip sa postará o nasledovné veci:

- Vytvorí zložku `ToolsPath`.
- Vytvorí zložku `CachePath` a v nej všetky ďalšie potrebné. Zároveň nastaví potrebné práva pre túto zložku.
- Ak bolo zadané `Proxy`, tak nastaví premenné prostredia `HTTP_PROXY` a `HTTPS_PROXY` a nastaví aj proxy pre NPM.
- Pridá štandardný `nuget.org` ako zdroj pre NuGet.
- Nainštaluje potrebné `dotnet` nástroje.
- Do zložky `$ToolsPath/newman` nainštaluje `newman`, potrebný pre Postman testy.
- Do zložky `$ToolsPath` skopíruje pomocné skripty `clean-temp.ps1` a `clean-nx-cache.ps1`.
- V plánovači úloh (Task Scheduler) vytvorí potrebné úlohy an čistenie rôznych dát.

Ak sa skript spúšťa opakovane, tak môže hlásiť chyby, pretože niektoré veci už budú existovať.

## Skript `configure-agents.ps1`

Skript vytvorí a nakonfiguruje potrebných build agentov. Má nasledovné parametre:

- `Pat`: personal access token (PAT) pre DevOps. Token musí mať právo `Read & manage` pre scope `Agent Pools`. Parameter je povinný.
- `AgentsBaseFolder`: adresár, do ktorého sa agenti nakpírujú. Predvolaná hodnota je `C:/agents`.
- `AgentZipFile`: názov ZIP súboru s agentom. Súbor musí byť v rovnakom adresári ako `configure-agents.ps1`. Predvolená hodnota ja `vsts-agent-win-x64.zip`.
- `WindowsUser`: meno Windows používateľa, pod ktorým budú služby agentov spustené. Predvolaná hdodnota je `buildAgent`.
- `WindowsPassword`: heslo Windows používateľa, pod ktorým budú služby agentov spustené. Predvolaná hdodnota je `buildAgent`.
- `Proxy`: adresa proxy servera, ak je potrebný, napríklad `http://1.2.3.4:5678`.

Zoznam agentov ktorí sa nakonfigurujú je v súbore `configure-agents.json`. Je potrebné stiahnuť si ZIP s aktuálnym agentom
(v časti _Agent pools_ v Devops). Všetci agenti sú registrovaní ako Windows služba a spustení sú pod jedným používateľom
(parameter `WindowsUser`). Ak tento používateľ vo Windows neexistuje, automaticky sa vytvorí.

Ak je agent za proxy serverom, je potrebné spustiť skript s parametrom `Proxy`. Pre každého agenta sú potom vytvorené
súbory `.proxy` a `.proxybypass`. Je možné tieto súbory vytvoriť aj ručne. Ak sa tieto súbory nachádzajú pri skripte
`configure-agents.ps1`, tak sa hodnota parametra `Proxy` (ak bola zadaná) nepoužije a k agentom sa skopírujú súbory,
ktoré už existujú.V súbory `.proxy` je uvedená adresa proxy servera, v súbore `.proxybypass` adresy, ktoré idú mimo proxy
server (napríklad `localhost`, `127.0.0.1`…). Každá adresa je na samostatnom riadku. Príklady:

Súbor `.proxy`:

``` text
http://1.2.3.4:5678
```

Súbor `.proxybypass`:

``` text
localhost
127.0.0.1
build5
```

## Script `install-load-tests.ps1`

Skript nainštaluje/nakonfiguruje všetko potrebné pre load testy. Tento skript je potrebné spúšťať len na build mašinách,
ktoré budú spúšťať load testy. Nainštaluje software, ktorý je definovaný v `load-tests-buildmachine-packages.config`.
Taktiež stiahne a rozbalí JMeter _(by default do `C:\tools\jmeter`)_ a nainštaluje potrebné pluginy.

Skript má nasledovné parametre (všetky nepovinné):

- `JMeterVersion` - Verzia JMeter-u, ktorá sa má nainštalovať _(default je `5.4.1`)_.
- `ToolsPath` - Adresár, kde sa nachádzajú naše tools. Tam sa nainštaluje JMeter _(default je `C:\tools`)_.
- `PluginsList` - Čiarkou oddelený zoznam pluginov _(Plugin Id)_, ktoré sa majú nainštalovať _(default je `jpgc-graphs-basic,jpgc-casutg,jpgc-prmctl,websocket-samplers,jpgc-wsc`)_.
