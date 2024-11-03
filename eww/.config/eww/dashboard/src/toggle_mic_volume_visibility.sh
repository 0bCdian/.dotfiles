#!/bin/bash

mic_volume_visibility=$1

if [ "$mic_volume_visibility" = "false" ]
then
mic_volume_visibility="true"
else
mic_volume_visibility="false"
fi
eww update mic_volume_visibility=$mic_volume_visibility
