# zircon-battery

Stan baterii myszy **Genesis Zircon 660 Pro** (odbiornik 2.4 GHz, Telink `331a:502e`) na pulpicie KDE Plasma 6.

Mysz nie zgłasza baterii standardowym polem HID, więc jądro, UPower i KDE jej nie widzą. Bateria jest dostępna tylko przez kanał producenta (report ID 5), z którego korzysta program Genesis na Windowsie.

## Protokół

| | bajty |
|---|---|
| zapytanie (33 B, output report) | `05 24 fa 48` + 29× `00` |
| odpowiedź | `05 ?? fa 48 …` |
| napięcie | bajty 4–5 LE × 4 = mV |
| ładowanie | bajt[6] (1/0) |
| stałe `31 50 07` (nie bateria) | bajty 8–10 |

Mysz po 2.4 GHz nie podaje procentu, tylko napięcie. Demon przelicza je krzywą Li-Po skalibrowaną do odczytu z Bluetooth (BLE Battery Service: 3750 mV ≈ 64%). Bajt[1] odpowiedzi jest zmienny. Echo zapytania ma zera w bajtach 4–7 i jest pomijane. Na Linuksie kanał vendor dzieli `/dev/hidrawN` z raportami ruchu myszy.

## Elementy

- `bin/zircon-battery`: demon w Pythonie, bez zależności. Stan zapisuje w `$XDG_RUNTIME_DIR/zircon-battery.json`, a `--once` robi jeden odczyt od razu.
- `systemd/zircon-battery.service`: unit użytkownika.
- `udev/50-genesis-zircon.rules`: dostęp do hidraw bez roota (`uaccess`).
- `plasmoid/org.crevasse3523.zirconbattery`: widget z nazwą modelu, procentem, paskiem i błyskawicą przy ładowaniu. Tylko czyta plik stanu.

## Oszczędzanie baterii myszy

- Zapytanie idzie tylko po wykryciu ruchu myszy, więc uśpiona mysz nie jest budzona.
- Czekanie na ruch to `select()` w jądrze, bez wybudzeń procesu.
- Hidraw jest zamykany zaraz po odczycie. Między odczytami demon śpi 15 min, a przy ładowaniu 5 min.
- Raz wysyła powiadomienie przy ≤ 15%.
- Po 30 min bez ruchu mysz jest oznaczana jako uśpiona (widget pokazuje ostatni znany procent).

## Instalacja

```sh
./install.sh --udev   # pierwszy raz (reguła udev przez sudo)
./install.sh          # kolejne aktualizacje
```

Widget dodaje się przez „Dodaj widżety…” → **Zircon Battery**.
