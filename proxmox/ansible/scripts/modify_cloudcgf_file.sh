#!/bin/bash

# Ruta al archivo
archivo="/etc/cloud/cloud.cfg"

# Número de línea a modificar
linea=37

# Leer la línea específica
linea_actual=$(sed "${linea}q;d" "$archivo")

# Verificar si la línea ya comienza con #
if [[ $linea_actual != \#* ]]; then
    # Agregar # al principio de la línea
    sed -i "${linea}s/^/#/" "$archivo"
fi