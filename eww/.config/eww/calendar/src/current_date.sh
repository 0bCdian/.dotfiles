#!/bin/bash
#get_date() {
#  current_day=$(date +%d)
#  current_day_name=$(date +%A)
#  current_month=$(date +%B)
#  json="{\"day\": \"$current_day\", \"day_name\": \"$current_day_name\", \"month\": \"$current_month\"}"
#  echo "$json"
#}
#current_time=$(date +%s)
#midnight_time=$(date -d "tomorrow 00:00:00" +%s)
#seconds_till_midnight=$((midnight_time - current_time))
#
#
#while true; do
#   current_date=$(get_date)
#   echo "$current_date"
#   sleep $seconds_till_midnight
#done

get_date() {
  current_day=$(date +%d)
  current_day_name=$(date +%A | iconv -f UTF-8 -t ASCII//TRANSLIT | tr '[:lower:]' '[:upper:]')
  current_month=$(date +%B | tr '[:lower:]' '[:upper:]')
  json="{\"day\": \"$current_day\", \"day_name\": \"$current_day_name\", \"month\": \"$current_month\"}"
  echo "$json"
}

current_time=$(date +%s)
midnight_time=$(date -d "tomorrow 00:00:00" +%s)
seconds_till_midnight=$((midnight_time - current_time))

while true; do
   current_date=$(get_date)
   echo "$current_date"
   sleep $seconds_till_midnight
done

