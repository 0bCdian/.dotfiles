#!/bin/bash
# Función para obtener el nombre del mes en español sin tildes y en mayúsculas
get_month_name() {
    case $1 in
        1) month_name="ENERO";;
        2) month_name="FEBRERO";;
        3) month_name="MARZO";;
        4) month_name="ABRIL";;
        5) month_name="MAYO";;
        6) month_name="JUNIO";;
        7) month_name="JULIO";;
        8) month_name="AGOSTO";;
        9) month_name="SEPTIEMBRE";;
        10) month_name="OCTUBRE";;
        11) month_name="NOVIEMBRE";;
        12) month_name="DICIEMBRE";;
        *) month_name="";;
    esac
    echo "$month_name" | tr '[:lower:]' '[:upper:]' | iconv -f UTF-8 -t ASCII//TRANSLIT
}

# Función para obtener el día de la semana en español sin tildes y en mayúsculas
get_day_of_week() {
    case $1 in
        1) day_of_week="LUNES";;
        2) day_of_week="MARTES";;
        3) day_of_week="MIERCOLES";;
        4) day_of_week="JUEVES";;
        5) day_of_week="VIERNES";;
        6) day_of_week="SABADO";;
        7) day_of_week="DOMINGO";;
        *) day_of_week="";;
    esac
    echo "$day_of_week" | tr '[:lower:]' '[:upper:]' | iconv -f UTF-8 -t ASCII//TRANSLIT
}

# Obtener los valores de los argumentos
day="$1"
month=$(( $2 + 1 ))
year="$3"

# Convertir el día a formato de dos dígitos
day=$(printf "%02d" "$day")

# Obtener el nombre del mes en español sin tildes y en mayúsculas
month_name=$(get_month_name "$month")

# Obtener el día de la semana en español sin tildes y en mayúsculas
day_of_week=$(date -d "$month/$day/$year" +%u)
day_of_week=$(get_day_of_week "$day_of_week")

# Actualizar variables del calendario
eww update day_number="$day"
eww update day_name="$day_of_week"
eww update month="$month_name"

