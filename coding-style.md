# C# Coding Style

Nevymýšľame koleso - coding style je prebratý z projektu [corefx](https://github.com/dotnet/corefx/blob/master/Documentation/coding-guidelines/coding-style.md).

Základné pravidlo formátovanie je "použi predvolený štýl Visual Studia".

1. Krútené zátvorky píšeme na samostatný riadok. Jednoriadkový príkaz môžeme napísať bez krútených zátvoriek, ale musí byť na samostatnom riadku a správne odsadený. V prípade že ide o skupinu `if ... [else if ... else if ...] else`, tak buď sú krútené zátvorky vo všetkých vetvách, alebo nikde -  tzn. nie je niektorá vetva so zátvorkami a iná bez nich. Pri definovaní tela `get`, `set` metód jednoduchých vlastností môžu byť krútené zátvorky aj s príkazom na jednom riadku (`get { return _value; }`).
2. Na odsadenie sa používame 4 medzery (nie tabulátory).
3. Privátne členy pomenovávame `_camelCase` a kde je to možné, použijeme `readonly`. Privátne a interné (`internal`) členy majú prefix `_`. Ak je člen statický, kľúčové slovo `readonly` je za `static` (tzn. `static readonly`, nie `readonly static`). Verejné členy nepoužívame a ak naozaj je taká potreba, tak ich názov je `PascalCase` bez prefixu.
4. Ak to nie je vyslovene nutné, nepoužívame `this.`.
5. Vždy explicitne špecifikujeme viditeľnosť, teda aj v prípade, ak je rovnaká ako predvolená (tzn. použije sa `private string _foo` a nie `string _foo`). Viditeľnosť je vždy prvý modifikátor (`public abstract`, nie `abstract public`).
6. Import namespace-ov je vždy na začiatku súboru a je zotriedený podľa abecedy. Abecedne zotriedené sú všetky importy ako celok, tzn. aj systémové (vo Visual Studiu sa dá zapnúť, aby systémové dával na začiatok - to nechceme).
7. Nikde nepoužívame viac ako jeden prázdny riadok za sebou.
8. Zbytočné medzery na konci riadkov odstraňujeme. Do plného Visual Studia, aj do VS Code sú na to rozšírenia, ktoré to robia automaticky.
9. Kľúčové slovo `var` používame iba v prípade, že je úplne jasný typ danej premennej (`var stream = new FileStream(...)`, nie `var stream = OpenStream(...)`).
10. Dátové typy zapisujeme kľúčovými slovami jazyka a nie typmi BCL (napr. `int`, `string`, `float` namiesto `Int32`, `String`, `Single`). Toto sa používa aj na volania metód (napr. `int.Parse` namiesto `Int32.Parse`).
11. Konštanty pomenovávame štýlom `PascalCase`. Výnimky sú _interop_ konštanty (konštanty z Windows API). Tie zapisujeme rovnako ako sú vo Windows API.
12. Vždy keď je to relevantné, používame `nameof(...)` namiesto reťazca `"..."`.
13. Definície všetkých privátnych členov sú na začiatku triedy (typu).
14. Dĺžka riadku je obmedzená na 130 znakov. Ak je to dlhšie (aj o jeden znak), treba to rozumne zalomiť na dva riadky. _Výnimka sú zdrojáky v unit testových knižniciach, kde sa relatívne často stane že sú dlhé riadky (napríklad kvôli informačným textom ak by test neprešiel). Tam je možné nechať riadky dlhšie, ak by zalamovanie len zhoršilo čitateľnosť._
15. Pri zalamovaní riadkov operátory `.`, `=>`, `?:`, `:` dávame na začiatok ďalšieho riadku a nie na koniec predošlého. Výnimka je pri operátore `=>` ak je použitý v parametre metódy, ktorý je lambda funkciou. Ak takáto funkcia má telo na viac riadkov (jej telo je blok `{ ... }`), tak operátor je na konci.
```csharp
public class LineBreaks
{
    public LineBreaks() : base()
    {
    }

    public LineBreaks(string parameter1, string parameter2, string parameter3)
        : base(parameter1, parameter2, parameter3)
    {
    }

    private override void FooShort() => base.FooShort();

    private override void FooWithNameTooLongForOneLine()
        => base.FooWithNameTooLongForOneLine();

    private void LambdaAsMethodArgument(IWebHostBuilder builder) {
        builder.ConfigureServices(services =>
        {
            services.AddSingleton<IEmailSender, SmtpEmailSender>();
            services.AddTransient<ILogger>(serviceProvider => new Logger());
        });
    }
    
    private void Bar()
    {
        services.AddIdentityServer()
            .AddDeveloperSigningCredential()
            .AddInMemoryPersistedGrants()
            .AddInMemoryClients(clients.Value);
    }

    private void TernaryOperator(int count, string primaryKeyName)
    {
        int total = count > 0 ? count * _itemPrice : 0;

        IndexSchema primaryKey = string.IsNullOrWhiteSpace(primaryKeyName)
            ? null
            : new IndexSchema(primaryKeyName, IndexType.PrimaryKey);
    }
}
```
16.  Ak je hlavička metódy príliš dlhá, zalamujú sa jej parametre, pričom sú zalomenú buď všetky (aj prvý), alebo žiaden (ak sa zmestí na riadok).
```csharp
private void Foo(int param1, string param2, string param3)
{
}

private void Bar(
    int param1,
    string param2,
    string param3)
{
}
```
17.  Verejné veci sú popísané dokumentačnými komentármi.
18.  Všeobecné komentáre priamo v zdrojákoch sa píšu podľa potreby. Dôležité je, aby komentár hovoril o tom, **prečo** je niečo spravené tak ako je.
