#!/bin/bash

set -e

# Obtener submódulos desde .gitmodules
submodules=($(grep 'path = ' .gitmodules | awk '{print $3}'))

# Mostrar submódulos
echo ""
echo "Submódulos disponibles:"
for i in "${!submodules[@]}"; do
  echo "  $((i+1)). ${submodules[$i]}"
done
echo "  0. Todos"

# Solicitar opción
read -p $'\nSeleccione un submódulo para actualizar (por número): ' selection

# Validar opción
if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 0 ] && [ "$selection" -le "${#submodules[@]}" ]; then
  if [ "$selection" -eq 0 ]; then
    selected=("${submodules[@]}")
  else
    selected=("${submodules[$((selection-1))]}")
  fi
else
  echo "❌ Opción inválida."
  exit 1
fi

# Pedir nombre de la rama
read -p $'\n🔀 Ingrese el nombre de la rama a usar: ' branch

if [ -z "$branch" ]; then
  echo "❌ No se proporcionó ninguna rama."
  exit 1
fi

# Cambiar de rama en el proyecto principal
echo -e "\n📁 Cambiando rama en el proyecto principal..."
git fetch origin
git checkout "$branch" || { echo "❌ La rama '$branch' no existe en el proyecto principal"; exit 1; }
git pull origin "$branch"

# Cambiar de rama y actualizar submódulos
echo -e "\n🔄 Cambiando a rama '$branch' en submódulos seleccionados..."
for sub in "${selected[@]}"; do
  echo "📦 $sub"
  (
    cd "$sub"
    git fetch origin
    git checkout "$branch" || { echo "⚠️  La rama '$branch' no existe en $sub"; exit 1; }
    git pull origin "$branch"
  )
done

echo -e "\n✅ Checkout y actualización completados en rama '$branch'."
