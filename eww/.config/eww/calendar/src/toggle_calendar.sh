#!/bin/bash
current_day_name=$(date +%A | iconv -f UTF-8 -t ASCII//TRANSLIT | tr '[:lower:]' '[:upper:]')
current_day=$(date +%d)
current_month=$(date +%B | tr '[:lower:]' '[:upper:]')
eww open --toggle calendar
eww update day_number="$current_day"
eww update day_name="$current_day_name"
eww update month="$current_month"