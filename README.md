# simple-scan

Escaneo automático en dos fases con nmap sobre una lista de IPs, con salida en un
único XML. Muestra los comandos, pide confirmación y los ejecuta con triple
verbose.

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

Al lanzarlo muestra los dos comandos de nmap que se van a ejecutar y pregunta
`¿Ejecutar el escaneo? [y/N]`. Con `y` arranca.

## Perfiles

Controlan el equilibrio entre velocidad y no saturar la red escaneada:

- **`bajo`** — super seguro: tasa baja y timing educado para no tumbar redes
  frágiles. Tarda algo más.
- **`medio`** — sintonía perfecta: rápido sin saturar. Es el valor por defecto.
- **`agresivo`** — más rápido pero acotado (sin `-T5` a lo loco): para redes que
  aguanten.
