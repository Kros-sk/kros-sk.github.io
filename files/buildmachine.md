# Build Machine

Počítač slúži na build našich projektov.

Inštalácia potrebných programov sa robí pomocou [Chocolatey](https://chocolatey.org/).
Takže ak je potrebné pridať nový program, prípadne niečo zmeniť, používajte `choco`. Zoznam nainštalovaných vecí je v súbore
[`buildmachine-packages.config`](https://github.com/Kros-sk/kros-sk.github.io/blob/master/files/buildmachine-packages.config),
tu na na našom GitHub-e. Ak je potrebné niečo zmeniť/pridať, nainštaluj to z príkazovej riadky (ako admin) a pridaj do toho súboru.
Jednoducho si tak v prípade potreby budeme vedieť spraviť ďalší build počítač.

Ak bude potrebné pridať nejakú utilitku, čo sa neinštaluje štandardne, ale iba kopíruje, pridaj ju do zložky `C:\tools`,
nech máme takéto veci na jednom mieste. Táto cesta je aj zapísaná v premennej `PATH`, takže všetko čo je v nej, je priamo spustiteľné.

DevOps agentov treba konfigurovať, až keď je celé prostredie nastavené, aby si zistili info o všetkom čo je v počítači.
V prípade, že sa nainštaluje niečo nové, čo má na agentov vplyv, je potrebné reštartovať ich služby.

## Prostredie

Hodnota `{proxy}` je IP adresa nášho proxy servera aj s portom (http://a.b.c.d:port).

V systéme je nutné nastaviť niekoľko premenných (pre celý systém, nie iba pre používateľa):

- `HTTP_PROXY` - `{proxy}`
- `HTTPS_PROXY` - `{proxy}`
- `JAVA` - nastaviť na rovnakú hodnotu, ako má `JAVA_HOME`. Premennú `JAVA_HOME` automaticky vytvorí inštalácia Javy, ale Devops agent potrebuje premennú `JAVA`. Samotná Java je potrebná pre [SonarCloud](https://sonarcloud.io/).
- `JAVA_FLAGS` = `-Dhttps.proxyHost={proxy adresa} -Dhttps.proxyPort={proxy port} -Dhttp.nonProxyHosts="localhost|127.0.0.1"`

## PowerShell

Je potrebné povoliť spúšťanie skriptov: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine`

## NPM

Nastavenie proxy:

```
npm config set proxy {proxy}
npm config set https-proxy {proxy}
```

### Globálne NPM nástroje

- **NewMan:** `npm install -g newman`
