# simple-scan

Escaneo automático en dos fases con nmap sobre una lista de IPs, con salida en un
único XML. Muestra los comandos, pide confirmación y los ejecuta con triple
verbose.

Es rápido con muchas IPs: la fase 1 (descubrimiento de puertos) escanea **toda
la lista en una sola pasada** dejando que nmap paralelice entre hosts, y la
fase 2 (servicios/versiones) agrupa las IPs por puertos y lanza un escaneo por
grupo — no una ejecución por IP.

## Instalación (Debian/Ubuntu)

```bash
sudo ./setup            # instala en /usr/local/bin y comprueba nmap
sudo ./setup uninstall  # lo elimina
```

## Uso

```bash
simple-scan --check -l ips.txt              # 1) mide la red y recomienda perfil
simple-scan -l ips.txt -o out.xml -p medio  # 2) escanea
```

| Parámetro         | Descripción                                                        |
|-------------------|-------------------------------------------------------------------|
| `-l`, `--list`    | Fichero `.txt` con una IP (o rango) por línea.                    |
| `-o`, `--output`  | Nombre del XML de salida.                                         |
| `-p`, `--profile` | `superbajo` \| `bajo` \| `medio` \| `alto` \| `agresivo` (def. `medio`). |
| `-y`, `--yes`     | Ejecuta sin pedir confirmación.                                  |
| `--check`         | Mide la estabilidad de la red y recomienda un perfil.            |
| `--update`        | Descarga la última versión y la reinstala.                       |

Al lanzarlo muestra los dos comandos de nmap que se van a ejecutar y pregunta
`¿Ejecutar el escaneo? [y/N]`. Con `y` arranca.

**Ejecuta con `sudo`** para el escaneo óptimo: el SYN scan (`-sS`) necesita
privilegios de root. Sin `sudo`, se avisa y se usa `-sT` (connect scan), que
funciona igual pero es más lento y ruidoso.

```bash
sudo simple-scan -l ips.txt -o out.xml -p medio
```

## `--check` (recomendación de perfil)

Antes de escanear, `--check` sondea la red con un `ping` corto (no intrusivo),
mide **pérdida de paquetes, jitter y RTT**, detecta si sales por **VPN** y te
**recomienda un perfil**. Si das `-l`, sondea el primer objetivo; si no, el
gateway.

```bash
simple-scan --check -l ips.txt
```

Si diste `-l`, al terminar te **pregunta si quieres ejecutar el escaneo con el
perfil recomendado** y, si aceptas, te pide el **nombre del `.xml`** (con un valor
por defecto derivado de la lista) y lo lanza directamente.

Habría avisado del problema típico de una **VPN inestable** (que puede tirar el
escaneo a medias): con VPN, pérdida o jitter alto, recomienda un perfil suave.

## Perfiles

De más seguro/lento a más rápido. El techo de tasa lo fija `--max-rate` en todos
(estrictamente creciente):

- **`superbajo`** · `≤100 pps` — máxima seguridad: una sonda a la vez. Para redes
  OT/ICS/embebidas o **inestables**. Muy lento.
- **`bajo`** · `≤500 pps` — super seguro: `-T3` sin suelo de tasa. Redes frágiles.
- **`medio`** · `1000–3000 pps` — sintonía perfecta, rápido sin saturar. **Por defecto.**
- **`alto`** · `2000–5000 pps` — rápido y preciso para redes limpias (LAN sana).
- **`agresivo`** · `3000–8000 pps` — lo más rápido, acotado (nunca `-T5`). Solo LAN robusta.

> Puedes ajustar las tasas editando los perfiles al inicio de `simple-scan`.
