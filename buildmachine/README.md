# Build Machine

Počítač slúži na build našich projektov.

Inštalácia potrebných programov sa robí pomocou [Chocolatey](https://chocolatey.org/).
Takže ak je potrebné pridať nový program, prípadne niečo zmeniť, používajte `choco`. Zoznam nainštalovaných vecí je v súbore
[`buildmachine-packages.config`](https://github.com/Kros-sk/kros-sk.github.io/blob/master/buildmachine/buildmachine-packages.config),
tu na na našom GitHub-e. Ak je potrebné niečo zmeniť/pridať, nainštaluj to z príkazovej riadky (ako admin) a pridaj do toho súboru.
Jednoducho si tak v prípade potreby budeme vedieť spraviť ďalší build počítač.

Ak bude potrebné pridať nejakú utilitku, čo sa neinštaluje štandardne, ale iba kopíruje, pridaj ju do zložky `C:\tools`,
nech máme takéto veci na jednom mieste. Táto cesta je aj zapísaná v premennej `PATH`, takže všetko čo je v nej, je priamo spustiteľné.

## DevOps build agenti

**DevOps agentov treba konfigurovať nakoniec, až keď je nainštalované a nastavné všetko ostatné**, aby si zistili info o všetkom
čo je v počítači. V prípade, že sa neskôr nainštaluje niečo nové, čo má na agentov vplyv, je potrebné reštartovať ich služby
(prípadne počítač).

Každý agent musí bežať pod svojim vlastným používateľom. Je to kvôli problémom, keď sa agenti bili o nejaké zdroje počas buildu,
ak bežali po spoločným účtom. Na jednoduché pridanie viacerých používateľov naraz slúži skript
[`create-users.ps1`](https://github.com/Kros-sk/kros-sk.github.io/blob/master/buildmachine/create-users.ps1).

Samotný agent sa dá jednoducho nakonfigurovať nasledovným príkazom:

``` sh
.\config.cmd --unattended --url "https://dev.azure.com/krossk/" --auth pat --token {token} --runAsService --pool {pool-name} --agent {agent-name} --windowsLogonAccount {user-name} --windowsLogonPassword {user-password}
```

## Systémové premenné

Hodnota `{proxy}` je IP adresa nášho proxy servera aj so schémou a portom (http://a.b.c.d:port).

V systéme je nutné nastaviť niekoľko premenných (pre celý systém, nie iba pre používateľa):

- `HTTP_PROXY` - `{proxy}`
- `HTTPS_PROXY` - `{proxy}`
- `JAVA` - nastaviť na rovnakú hodnotu, ako má `JAVA_HOME`. Premennú `JAVA_HOME` automaticky vytvorí inštalácia Javy, ale Devops agent potrebuje premennú `JAVA`. Samotná Java je potrebná pre [SonarCloud](https://sonarcloud.io/).
- `JAVA_FLAGS` = `-Dhttps.proxyHost={proxy adresa} -Dhttps.proxyPort={proxy port} -Dhttp.nonProxyHosts="localhost|127.0.0.1"`
- `SONAR_SCANNER_OPTS` - nastaviť rovnako ako `JAVA_FLAGS`. Premenná je potrebná pre [SonarCloud](https://sonarcloud.io).

Na jednoduché nastavenie premenných slúži skript [`set-environment-vars.ps1`](https://github.com/Kros-sk/kros-sk.github.io/blob/master/buildmachine/set-environment-vars.ps1),

## Web Deploy

Niektoré release pipeline-y používajú *Web Deploy* spôsob nasadenia služby do Azure,
[takže je potrebné ho nainštalovať](https://www.iis.net/downloads/microsoft/web-deploy).
Po inštalácii je potrebné manuálne nastaviť proxy v súbore `msdeploy.exe.config`, na oboch miestach:

- `C:\Program Files\IIS\Microsoft Web Deploy V3`
- `C:\Program Files (x86)\IIS\Microsoft Web Deploy V3`

Do súborov je potrebné doplniť nasledujúcu sekciu. *Adresu proxy servera je potrebné zadať aj so schémou `http://`.*

``` xml
<system.net>
  <defaultProxy>
    <proxy usesystemdefault="true" proxyaddress="http://{proxy}" bypassonlocal="true" />
  </defaultProxy>
</system.net>
```

## PowerShell

Je potrebné povoliť spúšťanie skriptov: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine`

## NPM

Nastavenie proxy (je potrebné ho zadať aj so schémou `http://`):

``` bash
npm config set proxy {proxy}
npm config set https-proxy {proxy}
```

### Globálne NPM nástroje

⚠ Globálna inštalácia (`npm install -g`) v prípade NPM znamená, že sa daná vec nainštaluje
*globálne pre aktuálneho používateľa*, do jeho profilu. Toto nechceme, my daný nástroj potrebujeme globálne
pre celý systém. Neexistuje možnosť ako toto v NPM spraviť (aspoň o nej nevieme), takže jediné čo nám ostáva,
je nainštalovať to takto a potom ručne skopírovať na nejaké všeobecné miesto. Po prekopírovaní je možné danú
vec pokojne odinštalovať.

**NewMan:** `npm install -g newman` Po nainštalovaní skopírovať do `C:\newman` (príkaz musí byť dostupný ako
`C:\newman\newman.cmd`) a do systémovej premennej `PATH` pridať cestu `C:\newman`. Nainštalovaný nástroj sa nachádza v zložke `%APPDATA%\npm\`.
