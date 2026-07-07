# simple-nmap-scan

Script en Bash que automatiza un escaneo en **dos fases** con nmap sobre una
lista de IPs y genera un único fichero **XML** con el resultado.

Está pensado para muchas IPs: usa comandos **no intrusivos** (no rompen webs) y
relativamente **rápidos**.

## Las dos fases

1. **Descubrimiento de puertos** (todos, solo abiertos, SYN, tasa acotada):

   ```
   nmap -p- --open -sS -T4 --min-rate 1500 --max-rate 3000 -vvv -n -Pn <ip>
   ```

2. **Detección de servicios y versiones** sobre los puertos abiertos encontrados:

   ```
   nmap -sCV -p<puertosAbiertos> <ip>
   ```

En todo momento se ve por pantalla el comando exacto que se lanza y la salida de
nmap con triple verbose (`-vvv`).

## Uso

```bash
# Con flags
./scan.sh -l ips.txt -o resultado.xml

# O con parametros posicionales: primero la lista, luego el nombre del XML
./scan.sh ips.txt resultado.xml
```

Para el escaneo SYN (`-sS`) hacen falta privilegios, así que normalmente:

```bash
sudo ./scan.sh -l ips.txt -o resultado.xml
```

### Parámetros

| Parámetro           | Descripción                                                    |
|---------------------|----------------------------------------------------------------|
| `-l`, `--list`      | Fichero `.txt` con una IP (o rango) por línea.                 |
| `-o`, `--output`    | Nombre del fichero XML de salida.                             |
| `-r`, `--min-rate`  | **Suelo** de paquetes/seg de la fase 1 (por defecto `1500`).  |
| `-R`, `--max-rate`  | **Techo** de paquetes/seg, no lo supera (por defecto `3000`). |
| `-T`, `--timing`    | Plantilla de timing de nmap `0-5` (por defecto `4`).         |
| `-h`, `--help`      | Ayuda.                                                        |

### Equilibrio velocidad / carga de red

La idea es ir rápido **sin saturar la trama de red** del objetivo:

- `--min-rate` es el **suelo**: garantiza una velocidad mínima para no eternizarse.
- `--max-rate` es el **techo**: nmap nunca envía más de esa tasa, así se evita
  saturar la red o disparar los IDS/IPS.
- `-T4` es un timing rápido pero razonable.

Ejemplos:

```bash
# Suave, para producción u objetivos delicados
./scan.sh -l ips.txt -o out.xml -r 500 -R 1500 -T3

# Por defecto (equilibrado): -r 1500 -R 3000 -T4
./scan.sh -l ips.txt -o out.xml

# Agresivo, para redes internas que aguanten
./scan.sh -l ips.txt -o out.xml -r 3000 -R 8000 -T4
```

## Fichero de IPs

Una IP por línea. Se ignoran líneas vacías y comentarios (`#`). Se admite la
sintaxis de nmap para varias IPs en una línea, por ejemplo `10.10.0.20,21,22,23,24`.

```
10.10.0.10
10.10.0.11
10.10.0.20,21,22,23,24
```

## Salida

Se genera un único `.xml` combinando el resultado de la fase 2 de todos los
objetivos con puertos abiertos. Los objetivos sin puertos abiertos se omiten de
la fase 2.
