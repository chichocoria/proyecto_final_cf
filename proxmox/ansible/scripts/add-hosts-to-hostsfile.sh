#!/bin/bash
# Ruta al archivo
archivo="/etc/hosts"

# Textos a agregar
texto1="192.168.52.104 kubernetes-master-1"
texto2="192.168.52.102 kubernetes-node-1"
texto3="192.168.52.103 kubernetes-node-2"

# Comprobar si los textos ya existen en el archivo
agregar_texto1=false
agregar_texto2=false
agregar_texto3=false

if ! grep -qF "$texto1" "$archivo"; then
    agregar_texto1=true
fi

if ! grep -qF "$texto2" "$archivo"; then
    agregar_texto2=true
fi

if ! grep -qF "$texto3" "$archivo"; then
    agregar_texto3=true
fi

# Agregar los textos que no existen
if $agregar_texto1; then
    echo "$texto1" | sudo tee -a "$archivo"
fi

if $agregar_texto2; then
    echo "$texto2" | sudo tee -a "$archivo"
fi

if $agregar_texto3; then
    echo "$texto3" | sudo tee -a "$archivo"
fi

# Mensajes de estado
if ! $agregar_texto1 && ! $agregar_texto2 && ! $agregar_texto3; then
    echo "Los tres textos ya existen en el archivo."
elif $agregar_texto1 && ! $agregar_texto2 && ! $agregar_texto3; then
    echo "El primer texto se ha agregado al archivo."
elif ! $agregar_texto1 && $agregar_texto2 && ! $agregar_texto3; then
    echo "El segundo texto se ha agregado al archivo."
elif ! $agregar_texto1 && ! $agregar_texto2 && $agregar_texto3; then
    echo "El tercer texto se ha agregado al archivo."
elif $agregar_texto1 && $agregar_texto2 && ! $agregar_texto3; then
    echo "El primer y segundo texto se han agregado al archivo."
elif $agregar_texto1 && ! $agregar_texto2 && $agregar_texto3; then
    echo "El primer y tercer texto se han agregado al archivo."
elif ! $agregar_texto1 && $agregar_texto2 && $agregar_texto3; then
    echo "El segundo y tercer texto se han agregado al archivo."
else
    echo "Los tres textos se han agregado al archivo."
fi
