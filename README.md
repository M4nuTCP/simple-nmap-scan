# simple-scan

Binario en Bash que automatiza un escaneo **en dos fases** con nmap sobre una
lista de IPs y genera un único **XML** combinado. Pensado para auditorías de
muchas IPs: comandos **no intrusivos** (no rompen webs) y con un equilibrio
afinado entre **velocidad** y **no saturar la trama de red**.

```
simple-scan -l ips.txt -o out.xml -p medio
```

## Las dos fases

1. **Descubrimiento de puertos** — todos los puertos, solo abiertos, SYN scan
   (no llega a la capa de aplicación, no toca la web):

   ```
   nmap -p- --open -sS <ajuste-del-perfil> -vvv -n -Pn <ip> -oG <tmp>
   ```

2. **Servicios y versiones** — solo sobre los puertos abiertos encontrados:

   ```
   nmap -sCV -p<puertos_abiertos> <ajuste-del-perfil> -vvv -n -Pn <ip> -oX <tmp>
   ```

En todo momento se ve el comando exacto lanzado y la salida de nmap con **triple
verbose** (`-vvv`).

## Perfiles

El equilibrio velocidad / carga de red se elige con `-p`:

| Perfil       | Idea                                                        | Velocidad |
|--------------|-------------------------------------------------------------|-----------|
| `bajo`       | **Super seguro**: no tumba redes frágiles. Tarda algo más.  | 🐢        |
| `medio` ⭐   | **Sintonía perfecta**: rápido sin saturar. Por defecto.     | ⚖️        |
| `agresivo`   | **Más rápido** pero acotado (sin `-T5` a lo loco).          | 🚀        |

La clave para no saturar es acotar la tasa con `--max-rate` (techo) en todos los
perfiles, y ajustar `-T`, reintentos y paralelismo según el perfil. `bajo` usa
timing educado y un techo bajo; `agresivo` sube el techo pero sigue estando
limitado.

## Instalación (Debian/Ubuntu)

Instálalo como binario del sistema con el script `setup`:

```bash
sudo ./setup            # instala en /usr/local/bin/simple-scan y comprueba nmap
sudo ./setup uninstall  # lo elimina
```

También hay `Makefile`:

```bash
sudo make install
sudo make uninstall
```

El instalador comprueba la dependencia **nmap** (y la instala con `apt` si falta)
y deja `simple-scan` disponible en el `PATH`.

## Uso

```bash
simple-scan -l <ips.txt> -o <salida.xml> [-p <perfil>] [-y]
```

| Parámetro          | Descripción                                             |
|--------------------|---------------------------------------------------------|
| `-l`, `--list`     | Fichero `.txt` con una IP (o rango) por línea.          |
| `-o`, `--output`   | Nombre del fichero XML de salida.                       |
| `-p`, `--profile`  | `bajo` \| `medio` \| `agresivo` (por defecto `medio`).  |
| `-y`, `--yes`      | No preguntar confirmación, ejecutar directamente.       |
| `-h`, `--help`     | Ayuda.                                                  |

### Flujo

Al ejecutar, primero se muestran **los dos comandos** que se van a lanzar
(numerados `1.` y `2.`) y un resumen del escaneo, y se pide **confirmación**:

```
  ¿Ejecutar el escaneo? [y/N]
```

Pulsando `y` arranca y se ve todo por pantalla con triple verbose. Con `-y` se
salta la confirmación.

## Fichero de IPs

Una IP por línea. Se ignoran líneas vacías y comentarios (`#`). Admite la
sintaxis de nmap para varias IPs en una línea (`10.10.0.20,21,22,23,24`).

```
10.10.0.10
10.10.0.11
10.10.0.20,21,22,23,24
```

## Salida

Un único `.xml` que combina el resultado de la fase 2 de todos los objetivos con
puertos abiertos. Los objetivos sin puertos abiertos se omiten de la fase 2.

## Aviso legal

Úsalo solo contra sistemas de tu propiedad o con **autorización por escrito**. El
escaneo de puertos sin permiso puede ser ilegal.
