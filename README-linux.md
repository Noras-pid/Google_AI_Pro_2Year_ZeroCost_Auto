# Google AI Pro 2Year ZeroCost — Linux port

Форк оригинала `worldonlyu/Google_AI_Pro_2Year_ZeroCost_Auto` с минимальными правками, чтобы движок запускался на Linux (Arch / CachyOS / Ubuntu / Fedora и т.д.).

## Что поменялось относительно upstream

| Файл | Было | Стало |
|---|---|---|
| `automation_engine.py :: _find_chrome_path()` | захардкожены `C:\Program Files\...chrome.exe` | ищет `$CHROME_PATH`, потом `google-chrome-stable`, `google-chrome`, `chromium`, `chromium-browser`, `/opt/google/chrome/chrome`, snap, flatpak через `shutil.which` |
| `automation_engine.py :: run_pipeline()` | `netstat -ano | findstr` + `.decode("gbk")` + `taskkill /F /T /PID` | ветка IS_WINDOWS сохранена; на Linux — `lsof -t -iTCP:<port> -sTCP:LISTEN` + `os.kill SIGTERM` → `SIGKILL` через 2 с |
| `automation_engine.py :: finally` | `taskkill /F /T /PID {self.proc.pid}` | `self.proc.terminate()` → `wait(2)` → `kill()` |
| `app.py :: _launch_on_interactive_desktop()` | Только Windows-ветка с `CreateProcessW` + `winsta0\default` | Windows-ветка нетронута. На Linux — `Popen(start_new_session=True)` и предупреждение в лог, если `DISPLAY`/`WAYLAND_DISPLAY` пустые |
| Пусковые скрипты | `1_首次运行_安装依赖并启动.bat`, `2_启动控制台.bat` | рядом добавлены `1_install_and_start.sh` и `2_start_console.sh` (обычный bash, `xdg-open`, `pip install --user`, `playwright install chromium`). .bat-файлы сохранены для Windows-юзеров |

Остальная логика движка (HOOK_JS, Google One offer-токены, TOTP, FloppyData, LocalHttpProxyAuthBridge, веб-консоль на :8765) не меняется.

## Что нужно на машине

- Linux с графической сессией (X11 или Wayland). Из TTY без DISPLAY Chrome не всплывёт.
- Python ≥ 3.10.
- Google Chrome stable **или** Chromium **или** произвольный бинарник через `CHROME_PATH=/полный/путь`.
  - Arch/CachyOS: `yay -S google-chrome` либо `sudo pacman -S chromium`.
  - Debian/Ubuntu: `.deb` с google.com/chrome либо `sudo apt install chromium`.
  - Fedora: `sudo dnf install chromium` (или Chrome из RPM-репо).
- `lsof` для чистки залипших портов (`sudo pacman -S lsof` / `apt install lsof`).
- Для оригинальной «мультиаккаунт»-схемы автор предполагает резидентный прокси (например FloppyData). Без прокси работает только с одного US-IP.

## Установка и запуск

```bash
git clone -b linux-port https://github.com/Noras-pid/Google_AI_Pro_2Year_ZeroCost_Auto.git
cd Google_AI_Pro_2Year_ZeroCost_Auto
./1_install_and_start.sh
```

Скрипт поставит `fastapi`, `uvicorn`, `playwright`, `pydantic` в `--user`, дёрнет `playwright install chromium` и откроет `http://127.0.0.1:8765`.

Повседневный запуск:

```bash
./2_start_console.sh
```

Если Chrome в нестандартном месте:

```bash
CHROME_PATH=/opt/brave.com/brave/brave ./2_start_console.sh
```

## Как пользоваться консолью

1. В левой панели **«全局配置与内联免税绑卡»**:
   - Номер карты (16 цифр), срок (MM / YY), CVC, имя латиницей.
   - ZIP оставить `97201` (Орегон, штат без sales tax — апстрим именно на это завязан).
   - Нажать **💾 保存配置** — всё ляжет в `config.json` рядом с проектом **открытым текстом**.
2. В правой панели **«批量放号导入区»** вставить аккаунты, по одному на строку:
   - `email----password----recovery_email`
   - `email----password----recovery_email----2FA_secret`
   - `email----password----2FA_secret`
   - разделители также поддержанные: `—`, `|`, `\t`, `,`, пробел. Прокси идёт как доп. поле `http://user:pass@host:port`.
3. Нажать **▶ 执行** на одной строке — или **▶ 批量全自动执行** на всю очередь.
4. Этапы, которые прогонит бот:
   - **Step 1** — логин в Google, прохождение recovery-email / 2FA, авто-клик reCAPTCHA.
   - **Step 2** — биндинг карты с tax-free ZIP и первый промо-блок 12 мес за US$0.00.
   - **Step 3** — стак второго блока +6 мес (US$0.00 → 18 мес).
   - **Step 4** — стак третьего блока +6 мес (US$0.00 → 24 мес, потолок).
   - **Step 5** — Google Play → отмена автопродления, финальный скрин с датой истечения в `screenshots/`.

Веб-консоль слушает только `127.0.0.1:8765` **без авторизации**. Не пробрасывай этот порт наружу — `/api/state` отдаёт пароли, TOTP-секреты, CVC и номер карты любому, кто постучит.

## Прокси (опционально)

- В левой панели есть поле «代理模板». Шаблон вида `user:pass@host:port` или `http://user:pass@host:port` — для каждого аккаунта будет своя session-строка.
- Если в `config.json` задать `floppy_api_key`, консоль дёрнет `api.floppydata.net/v2/account/balances` и покажет остаток трафика (ключ улетит на floppydata по `X-Api-Key` — это заявлено).

## Что я не менял

- `HOOK_JS` в `automation_engine.py` — перехват Google Play payloads и подстановка offer-токенов. Это ядро функциональности, трогать нельзя.
- Хардкод offer-токенов (`TOK_PRO5TB_12M` и т.д.) — они специфичны для текущей промо-кампании, протухнут вместе с ней.
- `target_region` по дефолту в коде — `TR`, `target_plan` — `ultra_20tb_5x`. В README апстрима заявлен Pro 5TB; расхождение осталось от апстрима.

## Риски, которые нужно понимать перед запуском

- **Карта и пароли лежат plaintext** в `config.json`.
- **CVC и TOTP-коды** пишутся в лог `/api/state` (видны любому, кто подключится на 127.0.0.1:8765).
- **Промо-stacking + смена региона через прокси + bypass «Add 2-Step Verification» экрана** нарушают ToS Google — аккаунты могут улететь в бан волнами.
- Фактическая легальность по юрисдикции — на совести оператора. Код в форке не менялся так, чтобы обойти антифрод сильнее апстрима; и не менялся так, чтобы сливать карту третьим лицам (exfil в коде не найден).
- Инструмент стоит крутить сперва на одном тестовом аккаунте и виртуальной карте, а не на пачке живых.

## Структура файлов

```
.
├── app.py                      # FastAPI консоль, :8765
├── automation_engine.py        # Playwright-движок + Google One / Play логика
├── config.json                 # Карта, аккаунты, настройки (plaintext)
├── requirements.txt            # fastapi, uvicorn, playwright, pydantic
├── templates/index.html        # Веб-UI SPA
├── 1_install_and_start.sh      # ← новый: установка + старт (Linux)
├── 2_start_console.sh          # ← новый: повседневный старт (Linux)
├── 1_首次运行_安装依赖并启动.bat  # первый запуск (Windows)
└── 2_启动控制台.bat             # повседневный старт (Windows)
```
