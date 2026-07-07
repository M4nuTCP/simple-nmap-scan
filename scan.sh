#!/usr/bin/env bash
#
# scan.sh - Escaneo automatico en dos fases con nmap
#
#   Fase 1: descubrimiento de puertos abiertos (rapido, no intrusivo)
#           nmap -p- --open -sS --min-rate 5000 -vvv -n -Pn <ip>
#
#   Fase 2: deteccion de servicios/versiones sobre los puertos abiertos
#           nmap -sCV -p<puertos> <ip>
#
# Lee una lista de IPs desde un .txt (una IP por linea) y genera un unico
# fichero XML combinando el resultado de la fase 2 de todas las IPs.
#
# Uso:
#   ./scan.sh -l <listado_ips.txt> -o <salida.xml>
#   ./scan.sh <listado_ips.txt> <salida.xml>
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Colores (solo si la salida es un terminal)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
    C_RESET="\033[0m"; C_BOLD="\033[1m"; C_BLUE="\033[34m"
    C_GREEN="\033[32m"; C_YELLOW="\033[33m"; C_RED="\033[31m"; C_CYAN="\033[36m"
else
    C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""
fi

banner() { echo -e "${C_BOLD}${C_BLUE}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }
info()   { echo -e "${C_CYAN}[i]${C_RESET} $*"; }
warn()   { echo -e "${C_YELLOW}[!]${C_RESET} $*"; }
err()    { echo -e "${C_RED}[x]${C_RESET} $*" >&2; }
# Muestra el comando exacto que se va a lanzar
show_cmd() { echo -e "${C_GREEN}\$ ${C_BOLD}$*${C_RESET}"; }

usage() {
    cat <<EOF
Uso:
  $0 -l <listado_ips.txt> -o <salida.xml>
  $0 <listado_ips.txt> <salida.xml>

Parametros:
  -l, --list    Fichero .txt con una IP (o rango) por linea.
  -o, --output  Nombre del fichero XML de salida.
  -r, --min-rate  Paquetes/seg de la fase 1 (por defecto 5000).
  -h, --help    Muestra esta ayuda.
EOF
}

# ---------------------------------------------------------------------------
# Parseo de argumentos (soporta flags y posicionales)
# ---------------------------------------------------------------------------
IP_LIST=""
OUT_XML=""
MIN_RATE=5000

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--list)     IP_LIST="${2:-}"; shift 2 ;;
        -o|--output)   OUT_XML="${2:-}"; shift 2 ;;
        -r|--min-rate) MIN_RATE="${2:-}"; shift 2 ;;
        -h|--help)     usage; exit 0 ;;
        -*)            err "Opcion desconocida: $1"; usage; exit 1 ;;
        *)             POSITIONAL+=("$1"); shift ;;
    esac
done

# Rellenar con posicionales si no se usaron flags
[[ -z "$IP_LIST" && ${#POSITIONAL[@]} -ge 1 ]] && IP_LIST="${POSITIONAL[0]}"
[[ -z "$OUT_XML" && ${#POSITIONAL[@]} -ge 2 ]] && OUT_XML="${POSITIONAL[1]}"

# ---------------------------------------------------------------------------
# Validaciones
# ---------------------------------------------------------------------------
if [[ -z "$IP_LIST" || -z "$OUT_XML" ]]; then
    err "Faltan parametros."
    usage
    exit 1
fi

if [[ ! -f "$IP_LIST" ]]; then
    err "No existe el fichero de IPs: $IP_LIST"
    exit 1
fi

if ! command -v nmap >/dev/null 2>&1; then
    err "nmap no esta instalado o no esta en el PATH."
    exit 1
fi

# Aviso si no somos root (-sS necesita privilegios; si no, nmap cae a -sT)
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    warn "No estas como root: -sS (SYN) necesita privilegios."
    warn "Ejecuta con sudo para el escaneo SYN, o nmap usara connect scan (-sT)."
fi

# Asegurar extension .xml
[[ "$OUT_XML" != *.xml ]] && OUT_XML="${OUT_XML}.xml"

# Directorio temporal para los XML por host
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Cargar IPs (ignora lineas vacias y comentarios con #)
# ---------------------------------------------------------------------------
mapfile -t TARGETS < <(grep -vE '^\s*(#|$)' "$IP_LIST" | sed 's/#.*//' | awk '{$1=$1};1' | grep -v '^$')

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    err "El fichero $IP_LIST no contiene IPs validas."
    exit 1
fi

banner "Objetivos cargados: ${#TARGETS[@]}"
for t in "${TARGETS[@]}"; do info "  - $t"; done
echo

# Lista de XML generados (fase 2) para el merge final
XML_PARTS=()
IDX=0

# ---------------------------------------------------------------------------
# Bucle principal: dos fases por cada objetivo
# ---------------------------------------------------------------------------
for IP in "${TARGETS[@]}"; do
    IDX=$((IDX + 1))
    SAFE="$(echo "$IP" | tr '/,: ' '____')"
    D_SCAN="$TMP_DIR/disc_${IDX}_${SAFE}.txt"
    X_SCAN="$TMP_DIR/serv_${IDX}_${SAFE}.xml"

    echo
    banner "[$IDX/${#TARGETS[@]}] Objetivo: ${C_YELLOW}${IP}${C_RESET}"

    # ---- FASE 1: descubrimiento de puertos ------------------------------
    banner "Fase 1 - Descubrimiento de puertos (todos, --open, SYN, rapido)"
    show_cmd "nmap -p- --open -sS --min-rate ${MIN_RATE} -vvv -n -Pn ${IP} -oG ${D_SCAN}"
    # -vvv -> interfaz de nmap con triple verbose en pantalla
    # -oG  -> salida greppable para extraer los puertos de forma fiable
    nmap -p- --open -sS --min-rate "${MIN_RATE}" -vvv -n -Pn "${IP}" -oG "${D_SCAN}"

    # ---- Extraer los puertos abiertos -----------------------------------
    # Del fichero greppable sacamos "puerto/open/..." y nos quedamos el numero
    PORTS="$(grep -oE '[0-9]+/open' "${D_SCAN}" 2>/dev/null \
                | cut -d '/' -f1 | sort -un | xargs | tr ' ' ',')"

    if [[ -z "$PORTS" ]]; then
        warn "Sin puertos abiertos en ${IP}. Se omite la fase 2."
        continue
    fi

    info "Puertos abiertos en ${IP}: ${C_GREEN}${PORTS}${C_RESET}"

    # ---- FASE 2: scripts por defecto + version --------------------------
    banner "Fase 2 - Deteccion de servicios y versiones (-sCV)"
    show_cmd "nmap -sCV -p${PORTS} -vvv -n -Pn ${IP} -oX ${X_SCAN}"
    nmap -sCV -p"${PORTS}" -vvv -n -Pn "${IP}" -oX "${X_SCAN}"

    XML_PARTS+=("${X_SCAN}")
done

# ---------------------------------------------------------------------------
# Combinar todos los XML de la fase 2 en un unico fichero
# ---------------------------------------------------------------------------
echo
if [[ ${#XML_PARTS[@]} -eq 0 ]]; then
    warn "Ningun objetivo tenia puertos abiertos: no se genera XML."
    exit 0
fi

banner "Generando XML combinado: ${C_GREEN}${OUT_XML}${C_RESET}"

FIRST="${XML_PARTS[0]}"
LAST="${XML_PARTS[${#XML_PARTS[@]}-1]}"

{
    # Cabecera: todo lo anterior al primer <host> del primer fichero
    awk 'BEGIN{p=1} /<host[ >]/{p=0} p{print}' "$FIRST"

    # Cuerpo: todos los bloques <host>...</host> de cada fichero
    for f in "${XML_PARTS[@]}"; do
        awk '/<host[ >]/{c=1} c{print} /<\/host>/{c=0}' "$f"
    done

    # Pie: runstats + cierre del ultimo fichero
    awk '/<runstats>/{p=1} p{print}' "$LAST"
} > "$OUT_XML"

info "Hosts con puertos abiertos: ${#XML_PARTS[@]}"
info "XML generado en: ${C_GREEN}${OUT_XML}${C_RESET}"
banner "Hecho."
