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
simple-scan -l ips.txt -o out.xml -p medio  # 2) escanea una lista
sudo simple-scan -t 172.16.12.0/24          # escanea una trama/CIDR entera
```

| Parámetro         | Descripción                                                        |
|-------------------|-------------------------------------------------------------------|
| `-l`, `--list`    | Fichero `.txt` con una IP (o rango) por línea.                    |
| `-t`, `--trama`   | Trama/CIDR (p.ej. `172.16.12.0/24`): descubre equipos activos primero. |
| `-o`, `--output`  | Nombre del XML de salida (en `-t`, por defecto `trama_<red>.xml`). |
| `-p`, `--profile` | `superbajo` \| `bajo` \| `medio` \| `alto` \| `agresivo` (def. `medio`). |
| `-y`, `--yes`     | Ejecuta sin pedir confirmación.                                  |
| `--check`         | Mide la estabilidad de la red y recomienda un perfil.            |
| `--update`        | Descarga la última versión y la reinstala.                       |

### Trama/CIDR (`-t`)

Con `-t` parte de una red entera y añade una fase previa de **equipos activos**:

```bash
sudo simple-scan -t 172.16.12.0/24
```

1. **Equipos activos** (`nmap -sn`) → guarda los vivos en `ips_trama_<red>.txt`.
2. **Puertos** sobre los equipos vivos (una sola pasada, con el perfil elegido).
3. **Servicios/versiones** (`-sCV`) por grupo de puertos → `trama_<red>.xml`.

Al lanzarlo muestra los dos comandos de nmap que se van a ejecutar y pregunta
`¿Ejecutar el escaneo? [y/N]`. Con `y` arranca.

**Ejecuta con `sudo`** para el escaneo óptimo: el SYN scan (`-sS`) necesita
privilegios de root. Sin `sudo`, se avisa y se usa `-sT` (connect scan), que
funciona igual pero es más lento y ruidoso.

```bash
sudo simple-scan -l ips.txt -o out.xml -p medio
```

## `--check` (recomendación de perfil)

Antes de escanear, `--check` sondea la red (2 ráfagas de ping, no intrusivo) y
**recomienda un perfil**, con **fuerte sesgo de seguridad** para no tumbar redes.

```bash
simple-scan --check -l ips.txt
```

**Reproducible entre máquinas.** La decisión de seguridad se basa en señales
**intrínsecas de la red** (pérdida de paquetes, VPN, inestabilidad entre ráfagas),
no en el ruido local de tu equipo:

- La **pérdida** se mide agrupando ~40 paquetes y descartando el de warm-up (ARP);
  un drop aislado en una sola ráfaga **no** te baja de perfil.
- El **jitter/RTT** solo se usan para *subir* a `alto` cuando el enlace es **por
  cable**, con 0% pérdida y estable — nunca deciden por sí solos. Por eso dos
  auditores en la misma red (uno por WiFi, otro por cable) ya no sacan `bajo` vs
  `alto`; sacan `medio` vs `alto` (adyacentes, el WiFi en el lado seguro).
- **VPN** → tope `bajo`. **WiFi/desconocido** → tope `medio`. Cualquier
  incertidumbre redondea hacia lo seguro. **`agresivo` nunca es automático.**

Si diste `-l`, al terminar te **pregunta si ejecutar el escaneo** con el perfil
recomendado y, si aceptas, te pide el **nombre del `.xml`** y lo lanza.

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
