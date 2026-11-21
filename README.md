# Voice Alarm

Budzik, ktory wylaczysz **tylko nagrywajac glosowke (min. 5 s)**.

- budziki jednorazowe i cykliczne (dni tygodnia), alarm gra glosno, petla, wibracje
- ekran dzwonienia blokuje "wstecz"; przycisk wylaczenia aktywuje sie dopiero po 5 s nagrania
- nagrania zapisuja sie lokalnie w telefonie (`recordings/`) i mozna je odsluchac w apce
- wlasne dzwieki: mp3, wav, ogg, m4a, aac, flac, mid (kopiowane do `sounds/`)
- wbudowane dzwieki (klasyczny budzik, melodia polifoniczna, syrena) - generowane przez `tools/gen_sounds.py`
- Flutter: kod wspolny dla Androida i iPhone'a (iOS - kolejny etap)

## Uruchomienie (Android)

```bash
flutter create --platforms=android --org com.example --project-name voice_alarm .
python3 tools/patch_android.py
flutter pub get
flutter run            # telefon z wlaczonym debugowaniem USB
flutter build apk      # plik w build/app/outputs/flutter-apk/
```

Przy pierwszym uruchomieniu zezwol na: powiadomienia, mikrofon, dokladne alarmy.
Na Xiaomi/Samsung/Huawei wylacz optymalizacje baterii dla aplikacji, inaczej system
moze ubic budzik.
