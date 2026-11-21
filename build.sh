#!/bin/bash
echo "A descarregar o Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

echo "A configurar o PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "A instalar dependências..."
flutter pub get

echo "A compilar para a Web..."
flutter build web