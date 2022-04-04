# Build Machine

Počítač slúži na build našich projektov.

Inštalácia potrebných programov sa robí pomocou [Chocolatey](https://chocolatey.org/).

Na čo najjednoduchšie nakonfigurovanie počítača slúžia skripty `install.ps1` a `configure.ps1`. Oba skripty je potrebné spustiť
ako administrátor.

## Chocolatey

Ak je potrebné pridať nový program, prípadne niečo zmeniť, používajte `choco`. _Ručne_ inštalujeme iba to, na čo Choco nemá
balíček, prípadne sú na to nejkaé iné vážne dôvody. Zoznam základných vecí čo sa inštauljú je v súbore
[`buildmachine-packages.config`](https://github.com/Kros-sk/kros-sk.github.io/blob/master/buildmachine/buildmachine-packages.config),
tu na na našom GitHub-e. Ak je potrebné niečo zmeniť/pridať, nainštaluj to z príkazovej riadky (ako admin) a pridaj do toho súboru.
Jednoducho si tak v prípade potreby budeme vedieť spraviť ďalší build počítač. Prvé nainštalovanie z tohto zoznamu sa spraví príkazom:

``` sh
choco install ./buildmachine-packages.config --yes
```

`choco` spúšťaj v administrátorskom režime obyčajného _command prompt-u_ (`cmd`). Je možné to spustiť aj vo Windows Terminále,
prípadne v PowerShelli, ale tieto veci sa tiež aktualizujú cez `choco`, takže ich aktualizácia by neprešla, ak by boli spustené.

Ak bude potrebné pridať nejakú utilitku, čo sa neinštaluje štandardne, ale iba kopíruje, pridaj ju do zložky `C:\tools`,
nech máme takéto veci na jednom mieste. Táto cesta je aj zapísaná v premennej `PATH`, takže všetko čo je v nej, je priamo spustiteľné.

### Základné príkazy

Zoznam aktuálne nainštalovaných vecí:

``` sh
choco list --local
```

Nainštalovanie nového balíčka:

``` sh
choco install program-name --yes
```

Zoznam neaktuálnych vecí, tzn. programov, ktoré už majú novšiu verziu, než je nainštalovaná:

``` sh
choco outdated
```

Aktualizácia všetkých neaktuálnych programov:

``` sh
choco upgrade all --yes
```

Niekedy nechceme aktualizovať úplne všetko. Štandardne napríklad Terraform neaktualizujeme okamžite. Vtedy je potrebné napísať
 meno programu, ktorý sa má aktualizovať namiesto `all`. Takto je možné zadať aj viacero programov naraz, oddelených medzerou:

``` sh
choco upgrade program-1 program-2 program-3 --yes
```

## Skript `install.ps1`

Skript nainštaluje samotné **chocolatey** a potom aj všetky ostatné programy v `buildmachine-packages.config`.
Nie je potrebné nič inštalovať popredu, stačí spustiť Powershell ktorý aktuálne v systéme je. Chocolatey nainštaluje aj
Powershell Core, či Windows Terminal.

Skript nemá žiadne parametre.

## Skript `configure.ps1`

Skript nakonfiguruje všetko potrebné, čo je možné spraviť automaticky a to je takmer všetko, čo je popísané ďalej v tomto
dokumente.

Skript má nasledovné parametre (všetky nepovinné):

- `-Proxy` – adresa proxy servera, zadaná aj so schémou (napr. `http://`). Predvolená hodnota je prázdny reťazec (bez proxy).
- `-NewmanPath` – cesta, kde bude nainštalovaný Newman. Predvolená hodnota je `C:\newman`.
- `-ToolsPath` – cesta k rôznym nástrojom. Táto cesta je pridaná do systémovej premennej `PATH`, aby nástroje boli globálne dostupné. Predvolená hodnota je `C:\tools`,
- `-ScriptsPath` – cesta, kde sa nakopírujú skripty pre údržbu systému. Predvolená hdonota je `C:\scripts`,
- `-CachePath` – cesta, kde sa nastaví keš pre rôzne programy (NPM, Cypress…). Predvolená hodnota je `C:\cache`.

## Script `install-load-tests.ps1`

Skript nainštaluje / nakonfiguruje všetko potrebné pre load testy. Tento script je potrebné spúšťať len na build mašinách,
ktoré budú spúšťať load testy. Nainštaluje software, ktorý je definovaný v `load-tests-buildmachine-packages.config`.
Taktiež stiahne a rozbalí JMeter _(by default do `C:\tools\jmeter`)_ a nainštaluje potrebné pluginy.

Skript má nasledovné parametre (všetky nepovinné):

- `JMeterVersion` - Verzia JMeter-u, ktorá sa má nainštalovať _(default je `5.4.1`)_.
- `ToolsPath` - Adresár, kde sa nachádzajú naše tools. Tam sa nainštaluje JMeter _(default je `C:\tools`)_.
- `PluginsList` - Čiarkou oddelený zoznam pluginov _(Plugin Id)_, ktoré sa majú nainštalovať _(default je `jpgc-graphs-basic,jpgc-casutg,jpgc-prmctl`)_.

## PowerShell (`install.ps1`)

Je potrebné povoliť spúšťanie skriptov: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine`.
Skript `install.ps1` to nastaví sám.

## DevOps build agenti

**DevOps agentov treba konfigurovať nakoniec, až keď je nainštalované a nastavné všetko ostatné**, aby si zistili info o všetkom
čo je v počítači. V prípade, že sa neskôr nainštaluje niečo nové, čo má na agentov vplyv, je potrebné reštartovať ich služby
(prípadne počítač).

Každý agent musí bežať pod svojim vlastným používateľom. Je to kvôli problémom, keď sa agenti bili o nejaké zdroje počas buildu,
ak bežali pod spoločným účtom. Na jednoduché pridanie viacerých používateľov naraz slúži skript
[`create-users.ps1`](https://github.com/Kros-sk/kros-sk.github.io/blob/master/buildmachine/create-users.ps1).

Agentovi je potrebné nastaviť proxy server. V adresári agenta je potrebné vytvoriť súbor `.proxy` (pozor, súbor naozaj začína
bodkou), v ktorom je zapísaná adresa proxy servera aj s protokolom a portom (napr. `http://123.112.1.9:1234`).

Niekedy sú po rozbalení ZIP-u agenta zblbnuté práva na jeho adresári a súboroch, čo sa prejavuje chybovou hláškou:

> This access control list is not in canonical form and therefore cannot be modified.

Vtedy treba spustiť nasladovný príkaz: `icacls.exe {agent-folder} /reset /T /C /L /Q`. Parameter `{agent-folder}` je cesta
k zložke s agentom.

Samotný agent sa potom nakonfiguruje jednoducho nasledovným príkazom:

``` sh
.\config.cmd --unattended --url "https://dev.azure.com/krossk/" --auth pat --token {token} --runAsService --pool {pool-name} --agent {agent-name} --windowsLogonAccount {user-name} --windowsLogonPassword {user-password}
```

- `{token}`: PAT (personal access token) v DevOps, ktorý musí mať nastavený scope **Read & manage** pre **Agent Pools**.
Tento token môže mať krátku platnosť a je potrebný iba na zaregistrovanie agenta v DevOps agent pool-e.
Pre samotný beh agenta potrebný nie je.
- `{pool-name}`: Meno pool-u, do ktorého bude agent pridaný.
- `{agent-name}`: Meno agenta.
- `{user-name}`: Meno používateľa, pod ktorým agent beží.
- `{user-password}`: Heslo používateľa, pod ktorým agent beží.

⚠ **Dôležité nastavenie pre Agent Pools** - v Devopse v jeho nastaveniach (prístupné cez `Organization settings`),
treba nastaviť `Maintenance job`, ktorý bude pravidelne prečisťovať miesto. Nastaviť ho podľa iných pools tak,
aby sa ideálne vykonávanie robilo v iných časoch (nie je to nutná podmienka).

## Systémové premenné (`configure.ps1`)

### Všeobecné systémové premenné

- `CYPRESS_CACHE_FOLDER` – štandardne nastavená na `C:\cache\cypress`. Cypress si tu ukladá stiahnuté binárky.
- `NPM_CONFIG_CACHE` – štandardne nastavená na `C:\cache\npm`. NPM si tu ukladá stiahnuté balíčky.
- `NUGET_PACKAGES` – štandardne nastavená na `C:\cache\nuget`. NuGet si tu ukaldá stiahnuté balíčky.

### Proxy systémové premenné

Hodnota `{proxy}` je IP adresa nášho proxy servera aj so schémou a portom (http://a.b.c.d:port).

V systéme je nutné nastaviť niekoľko premenných (pre celý systém, nie iba pre používateľa):

- `HTTP_PROXY` - `{proxy}`
- `HTTPS_PROXY` - `{proxy}`

Všetky systémové premenné automaticky nastaví skript `configure.ps1`.

## Web Deploy (potrebné spraviť ručne)

> Web deploy služieb používajú iba na SSW, takže ak nie je potrebné, netreba sa s ním zaoberať.

Niektoré release pipeline-y používajú _Web Deploy_ spôsob nasadenia služby do Azure,
[takže je potrebné ho nainštalovať](https://www.iis.net/downloads/microsoft/web-deploy).
Po inštalácii je potrebné manuálne nastaviť proxy v súbore `msdeploy.exe.config`, na oboch miestach:

- `C:\Program Files\IIS\Microsoft Web Deploy V3`
- `C:\Program Files (x86)\IIS\Microsoft Web Deploy V3`

Do súborov je potrebné doplniť nasledujúcu sekciu. _Adresu proxy servera je potrebné zadať aj so schémou `http://`._

``` xml
<system.net>
  <defaultProxy>
    <proxy usesystemdefault="true" proxyaddress="http://{proxy}" bypassonlocal="true" />
  </defaultProxy>
</system.net>
```

## NPM (`configure.ps1`)

Nastavenie proxy (je potrebné ho zadať aj so schémou `http://`):

``` sh
npm config set proxy {proxy}
npm config set https-proxy {proxy}
```

Po nakonfigurovaní nového servera sa môže stať, že projekt si nevie stiahnuť npm balíčky
(konkrétne sa to stalo pre projekt s Cypress testami). Vtedy treba spustiť príkaz:

``` sh
npm config set registry https://registry.npmjs.org/
```

### Globálne NPM nástroje (`configure.ps1`)

⚠ Globálna inštalácia (`npm install -g`) v prípade NPM znamená, že sa daná vec nainštaluje
_globálne pre aktuálneho používateľa_, do jeho profilu. Toto nechceme, my daný nástroj potrebujeme globálne
pre celý systém. Neexistuje možnosť ako toto v NPM spraviť (aspoň o nej nevieme), takže jediné čo nám ostáva,
je nainštalovať to takto a potom ručne skopírovať na nejaké všeobecné miesto. Po prekopírovaní je možné danú
vec pokojne odinštalovať.

**NewMan:** `npm install -g newman` Po nainštalovaní skopírovať do `C:\newman` (príkaz musí byť dostupný ako
`C:\newman\newman.cmd`) a do systémovej premennej `PATH` pridať cestu `C:\newman`.
Nainštalovaný nástroj sa nachádza v zložke `%APPDATA%\npm\`.

## DotNet Global Tools (`configure.ps1`)

Je potrebné nainštalovať nasledovné dotnet tools:

- Kros.DummyData.Initializer
- Kros.VariableSubstitution

Nástroje sa inštalujú príkazom `dotnet tool install --global {toolName} --tool-path {toolPath}`.

## Inštalácia Docker 🐳

Docker je potrebné nainštalovať "ručne". Najskôr je v programoch a súčastiach potrebné zapnúť `Hyper-V` ![hyper-v](https://i.ibb.co/Yk6hQh3/stiahnu.png).
> Ak by bola časť možností disablovaná, tak je potrebné zapnúť virtualizáciu na úrovni BIOSu.

Ďalej [nainštalovať linux subsystem](https://docs.microsoft.com/en-us/windows/wsl/install) `wsl --install`.

A nakoniec samotný [Docker](https://docs.docker.com/desktop/windows/install/).

## Čistenie dočasných (temp) súborov (`configure.ps1`)

[Terraform](https://www.terraform.io) a v niektorých prípadoch aj .NET pri svojej práci vytvárajú súbory v `Temp` zložke.
Postupne veľkosť týchto súborov narastie na vyššie jednotky GB. Keďže každý agent beží pod vlastným používateľským účtom
má aj vlastnú `Temp` zložku a tak množstvo takto vytvorených dát je celkom významné.

Na prečistenie `Temp` zložiek všetkých používateľov slúži skript [`clean-temp.ps1`](https://github.com/Kros-sk/kros-sk.github.io/blob/master/buildmachine/clean-temp.ps1).
Ak sa spúšťa z príkazovej riadky, je potrebné ho spúšťať ako administrátor (inak vymaže len temp aktuálne prihláseného
používateľa). Na _build_ počítač ho treba pridať ako naplánovanú úlohu, ktorá sa spustí raz za deň a `Temp` prečistí.
Skript je potrebné nakopírovať do zložky `C:\scripts` a naplánovanú úlohu vytvoriť nasledovným príkazom,
spusteným ako administrátor:

``` sh
schtasks /create /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /sc daily /st 03:30 /tn "BuildAgents\CleanTemp" /tr "pwsh -File 'C:\scripts\clean-temp.ps1' -SaveTranscript"
```

Skript vytvorí záznam o svojom poslednom behu do súboru `clean-temp.log`.
