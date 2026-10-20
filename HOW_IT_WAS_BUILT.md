# Como o KotatsuIOS foi construído

> Documento gerado durante o desenvolvimento real no dispositivo. Nada aqui é teórico — cada passo foi executado e verificado no iPhone.

## O desafio

Portar o [Kotatsu](https://github.com/KotatsuApp/Kotatsu) (leitor de mangá Android, ~50k linhas de Kotlin) para iOS **usando apenas o próprio iPhone** como máquina de desenvolvimento:

- **Dispositivo:** iPhone 7 (iPhone9,3), iOS 15.8.8, jailbreak rootless (palera1n + Procursus)
- **Sem Mac, sem Xcode, sem simulador**
- **Usuário `mobile` (uid 501), sem root direto** (sudo apenas para trustcache)

## Descoberta do toolchain

O ambiente já tinha clang 16 (Procursus) mas **sem SDK iOS**. A primeira tentativa de compilar falhou:

```
fatal error: 'UIKit/UIKit.h' file not found
```

O iOS não embarca headers dos frameworks. A chave foi descobrir que o Procursus já tinha um **SDK iOS 16.2 completo** em:

```
/var/jb/usr/share/SDKs/iPhoneOS.sdk
```

Com `-isysroot` apontando para lá, o clang compila Objective-C/UIKit nativamente no device.

## Pipeline de build

`build.sh` — compila cada `.m` para `.o` e linka:

```bash
clang -isysroot /var/jb/usr/share/SDKs/iPhoneOS.sdk \
      -target arm64-apple-ios15.0 \
      -fobjc-arc -fmodules -O2 \
      -I Sources/... -c arquivo.m -o arquivo.o

clang -isysroot ... -framework UIKit -framework Foundation -o KotatsuIOS *.o
```

`package.sh` — monta o `.app` e empacota `.deb`:

```
Kotatsu.app/
├── KotatsuIOS   (binário arm64)
├── Info.plist   (CFBundleIdentifier: org.koitharu.kotatsu.ios)
└── PkgInfo
```

Instalação: `dpkg -i` → `/var/jb/Applications/Kotatsu.app` (rootless).

## Assinatura e trustcache

Todo binário novo morre com **exit 137 (SIGKILL)** até ser assinado e registrado:

1. **ldid com entitlements** (`platform-application`, `no-container`, `skip-library-validation`, `no-sandbox`)
2. **Extrair cdhash:** `ldid -h` → 40 chars hex
3. **Registrar:** `sudo jbctl trustcache add <cdhash>`

O trustcache é **volátil** — após reboot do jailbreak, re-registrar.

## Arquitetura (paridade com o Android)

Mapeamento direto dos pacotes Kotlin → módulos ObjC:

| Kotatsu Android (Kotlin) | KotatsuIOS (ObjC) |
|---|---|
| `org.koitharu.kotatsu.core.model` | `Sources/Core/Models/` (Manga, Chapter, Source) |
| `kotatsu-parsers` (MangaDexParser.kt) | `Sources/Parsers/MangaDexParser.m` |
| Room DB (favoritos/histórico) | `Sources/Data/FavoritesStore.m` (NSKeyedArchiver) |
| `ui/library`, `ui/details`, `ui/reader` | `Sources/Presentation/` (Library, Details, Reader) |
| Hilt DI | Singleton (`sharedParser`, `sharedStore`) |

O código Kotlin oficial de referência está em `reference/kotatsu-parsers/` — cada decisão de parsing foi copiada de lá.

## Paridade com o parser Kotlin

O `MangaDexParser.kt` oficial define o contrato. Pontos copiados à risca:

- **Capa:** `https://uploads.mangadex.org/covers/{mangaId}/{fileName}` (de `cover_art` relationship)
- **Capítulos:** `order[volume]=asc&order[chapter]=asc`, `includes[]=scanlation_group`, todos os contentRatings
- **externalUrl:** capítulos oficiais são pulados (`if (!attrs.isNull("externalUrl")) continue`)
- **Páginas:** `at-home/server/{id}` → `baseUrl/data/{hash}/{file}`, `forcePort443=false`
- **Data:** `publishAt` ISO8601 com offset `+00:00`
- **NSNull-safe:** campos `chapter`/`volume`/`title` podem ser `null` em capítulos oficiais (causa de crash corrigida)

## Testes de regressão

`Tests/RegressionTests.m` + `test.sh` — binário nativo (sem XCTest, que exige Xcode):

- **Fixtures** capturados da API real (Solo Leveling como caso de teste)
- **Testes de paridade:** formato de URL de capa, seleção de título (en fallback), skip de externalUrl, construção de URL de página, parsing de data, mapeamento de status
- **Testes live:** popular (20 itens), busca, capítulos — contra a API real do MangaDex

Resultado final: **23 PASS, 0 FAIL**.

## Bugs reais encontrados e corrigidos

1. **Crash Abort trap 6** — `NSNull.doubleValue` em capítulos oficiais (`chapter: null`). Corrigido com type-checking antes de cada cast.
2. **Fixture JSON inválido** — concatenação de string ObjC com `}` extra. Reescrito em linha única.
3. **`systemBackground` não existe** — o SDK 16.2 usa `systemBackgroundColor` (em `UIInterface.h`).
4. **`cp -R` aninhou o .app** — `Kotatsu.app/Kotatsu.app/` dentro do .deb. Corrigido para copiar conteúdo.
5. **HTTP 400 no push** — resolvido com push em partes + token na URL.

## Estado final

| Item | Status |
|---|---|
| Build no device | ✅ clang + SDK 16.2, arm64 |
| Testes | ✅ 23/23 (incl. live API) |
| Instalação | ✅ .deb em `/var/jb/Applications/Kotatsu.app` |
| Funcional | ✅ Library (grid + capas), busca, Details, Reader (páginas reais), favoritos, histórico |
| Parsers | 1 de ~1358 (MangaDex) — referência completa em `reference/` |

## Limitações conhecidas

- **1 parser** (MangaDex). Os outros estão em `reference/kotatsu-parsers/` para port incremental — o padrão é mecânico (mesma API, outro site).
- **Sem downloads offline**, sem trackers, sem backup, sem temas.
- **Trustcache volátil** — após reboot, re-executar o registro do cdhash.
- **NSKeyedArchiver** em vez de SQLite — suficiente para o escopo atual; migração futura trivial.

## Reproduzir

```bash
# No iPhone com jailbreak rootless (Procursus):
git clone https://github.com/loopedsouls/kotatsuios
cd kotatsuios
./build.sh      # compila e assina
./package.sh    # gera o .deb
sudo dpkg -i build/org.koitharu.kotatsu.ios_1.0.0_iphoneos-arm64.deb
# registrar cdhash no trustcache (ver seção acima)
```
