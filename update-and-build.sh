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
    build_all=true
  else
    selected=("${submodules[$((selection-1))]}")
    build_all=false
  fi
else
  echo "❌ Opción inválida."
  exit 1
fi

# Actualizar submódulos seleccionados
echo -e "\n🔄 Actualizando submódulos..."
for sub in "${selected[@]}"; do
  echo "📦 $sub"
  (cd "$sub" && git checkout main && git pull origin main)
done

# Construir solo si es uno solo
if [ "$build_all" = false ]; then
  sub="${selected[0]}"
  service=$(echo "$sub" | tr '[:upper:]' '[:lower:]')

  echo -e "\n🧱 Ejecutando 'yarn build' en el contenedor: $service"
  docker compose exec "$service" yarn build

  echo -e "\n🔁 Reiniciando contenedor: $service"
  docker compose restart "$service"

else
  echo -e "\n🧱 Ejecutando 'yarn build' en TODOS los servicios activos..."
  running_services=($(docker compose ps --services --filter status=running))
  for service in "${running_services[@]}"; do
    echo "🔧 $service"
    docker compose exec "$service" yarn build
    docker compose restart "$service"
  done
fi

echo -e "\n✅ Proceso completo."
