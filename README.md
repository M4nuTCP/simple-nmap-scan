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
simple-scan -l ips.txt -o out.xml -p medio
```

| Parámetro         | Descripción                                            |
|-------------------|--------------------------------------------------------|
| `-l`, `--list`    | Fichero `.txt` con una IP (o rango) por línea.         |
| `-o`, `--output`  | Nombre del XML de salida.                              |
| `-p`, `--profile` | `bajo` \| `medio` \| `agresivo` (por defecto `medio`). |
| `-y`, `--yes`     | Ejecuta sin pedir confirmación.                        |
| `--update`        | Descarga la última versión y la reinstala.             |

Al lanzarlo muestra los dos comandos de nmap que se van a ejecutar y pregunta
`¿Ejecutar el escaneo? [y/N]`. Con `y` arranca.

**Ejecuta con `sudo`** para el escaneo óptimo: el SYN scan (`-sS`) necesita
privilegios de root. Sin `sudo`, se avisa y se usa `-sT` (connect scan), que
funciona igual pero es más lento y ruidoso.

```bash
sudo simple-scan -l ips.txt -o out.xml -p medio
```

## Perfiles

Controlan el equilibrio entre velocidad y no saturar la red escaneada. El techo
de tasa lo fija `--max-rate` en los tres:

- **`bajo`** · `≤500 pps` — super seguro: `-T3` sin suelo de tasa (deja que nmap
  frene ante congestión), pocos hosts en paralelo y más reintentos. Para redes
  frágiles. Tarda más.
- **`medio`** · `1000–3000 pps` — sintonía perfecta: `-T4` acotado, rápido sin
  saturar. **Valor por defecto.**
- **`agresivo`** · `3000–8000 pps` — más rápido pero acotado: `-T4` (nunca `-T5`,
  que daría falsos negativos), techo de tasa y RTT ajustado. Para redes que
  aguanten.

> Puedes subir/bajar las tasas editando los perfiles al inicio de `simple-scan`.
