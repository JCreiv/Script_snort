#!/bin/bash

# Function to print messages in red and green
print_red() {
    echo -e "\033[31m$1\033[0m"
}
print_green() { 
	echo -e "\e[32m$1\e[0m"
}

ctrl_c(){
  echo -e "\n\n[!] Saliendo...\n"
  exit 1
}

# Ctrl+C
trap ctrl_c INT

# Define el token de GitHub
read -p "Introduce tu tooken de github:  " TOKEN

path="/usr/src"
cd "$path" || { print_red "Error: No se pudo cambiar al directorio $path."; exit 1; }


# Actualizar el sistema 
sudo apt update
sudo apt upgrade -y

# Install packages and dependencies if not already installed
packages=(
	cmake
	jq
    libboost-all-dev
    ragel
    git
    cmake
    libdaq-dev
    libdnet-dev
    flex
    g++
    hwloc
    libluajit-5.1-dev
    libssl-dev
    libpcap-dev
    libpcre3-dev
    pkg-config
    zlib1g-dev
    asciidoc
    cpputest
    dblatex
    libflatbuffers-dev
    libhyperscan-dev
    libunwind-dev
    liblzma-dev
    libsafec-dev
    source-highlight
    w3m
    uuid-dev
    autoconf
    libtool
    libhwloc-dev
    bison
    build-essential
    curl
    ethtool
    libcmocka-dev
    libmnl-dev
    libnetfilter-queue-dev
    libsqlite3-dev
    libpcre3
    libpcre3-dbg
    openssl
    wget
    xz-utils
)


# Funcion para verificar si un paquete esta ya instalado 
is_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>&1
}

# Bucle para comprobar e instalar los paquetes 
for package in "${packages[@]}"; do
    status=$(is_package_installed "$package")
    if [[ "$status" == *"install ok installed"* ]]; then
        print_red "$package is already installed."
    elif [[ "$status" == *"unknown ok not-installed"* ]]; then
        print_red "$package is not installed. Installing..."
        sudo apt install -y "$package"
    elif [[  "$status" == *"dpkg-query: no packages found matching $package"*  ]]; then
        print_red "$package is not installed. Installing..."
        sudo apt install -y "$package"
    else
        print_red "Unable to determine the status of $package. Skipping."
    fi
done

#Solucion a la falla de instalacion de los repositorios

git config --global http.postBuffer 524288000
git config --global http.maxRequests 100
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999



# Descargar safeclib

if [[ ! -f "$path/safeclib.tar.bz2" ]]; then
	sleep 1
fi

safeclib_url=$(curl --silent -H "Authorization: token $TOKEN" "https://api.github.com/repos/rurban/safeclib/releases/latest" | jq -r '.assets[] | select(.name | endswith(".tar.bz2")) | .browser_download_url')


if [[ -z "$safeclib_url" ]]; then
  print_red "Error: No se pudo obtener la URL de descarga de safeclib."
elif [[ ! -f "$path/safeclib.tar.bz2" ]]; then
  sudo wget "$safeclib_url" -O "$path/safeclib.tar.bz2" || { print_red "Error: Falló la descarga de safeclib."; exit 1; }
else
  print_red "El archivo safeclib.tar.bz2 ya existe en $path."
fi



if [[ ! -f "$path/gperftools.tar.gz" ]]; then
	sleep 1
fi

# Descargar gperftools
gperftools_url=$(curl --silent -H "Authorization: token $TOKEN" "https://api.github.com/repos/gperftools/gperftools/releases/latest" | jq -r '.assets[0].browser_download_url')

if [[ -z "$gperftools_url" ]]; then
  print_red "Error: No se pudo obtener la URL de descarga de gperftools."
elif [[ ! -f "$path/gperftools.tar.gz" ]]; then
  sudo wget "$gperftools_url" -O "$path/gperftools.tar.gz" || { print_red "Error: Falló la descarga de gperftools."; exit 1; }
else
  print_red "El archivo gperftools.tar.gz ya existe en $path."
fi



# Obtener la versión de Snort 3
snort3_version=$(curl -fsSL -H "Authorization: token $TOKEN" "https://api.github.com/repos/snort3/snort3/releases/latest" | jq -r '.tag_name')
snort3_url=$(curl -fsSL -H "Authorization: token $TOKEN" "https://api.github.com/repos/snort3/snort3/releases/latest" | jq -r '.tarball_url')

if [[ ! -f "$path/snort-$snort3_version.tar.gz" ]]; then
	sleep 1
fi


if [[ -z "$snort3_version" ]]; then
  print_red "Error: No se pudo obtener la versión de Snort 3."
elif [[ -z "$snort3_url" ]]; then
  print_red "Error: No se pudo obtener la URL de Snort 3."
elif [[ ! -f "$path/snort-$snort3_version.tar.gz" ]]; then
  sudo wget "$snort3_url" -O "$path/snort-$snort3_version.tar.gz" || { print_red "Error: Falló la descarga de Snort 3."; exit 1; }
else
  print_red "El archivo snort-$snort3_version.tar.gz ya existe en $path."
fi

# Obtener la versión de libdaq y descargar
libdaq_version=$(curl -fsSL -H "Authorization: token $TOKEN" "https://api.github.com/repos/snort3/libdaq/releases/latest" | jq -r '.tag_name')

if [[ ! -f "$path/libdaq-$libdaq_version.tar.gz" ]]; then
	sleep 1
fi

if [[ -z "$libdaq_version" ]]; then
  print_red "Error: No se pudo obtener la versión de libdaq."
else
  libdaq_url=$(curl -fsSL -H "Authorization: token $TOKEN" "https://api.github.com/repos/snort3/libdaq/releases/latest" | jq -r '.tarball_url')
  if [[ -z "$libdaq_url" ]]; then
    print_red "Error: No se pudo obtener la URL de libdaq."
  elif [[ ! -f "$path/libdaq-$libdaq_version.tar.gz" ]]; then
    sudo wget "$libdaq_url" -O "$path/libdaq-$libdaq_version.tar.gz" || { print_red "Error: Falló la descarga de libdaq."; exit 1; }
  else
    print_red "El archivo libdaq-$libdaq_version.tar.gz ya existe en $path."
  fi
fi


# Descargar Snort Extra
snort3_extra_url=$(curl -fsSL -H "Authorization: token $TOKEN" "https://api.github.com/repos/snort3/snort3_extra/tags" | jq -r --arg snort3_version "$snort3_version" '.[] | select(.name==$snort3_version) | .tarball_url')

if [[ ! -f "$path/snort3_extras-$snort3_version.tar.gz" ]]; then
	sleep 1
fi

if [[ -z "$snort3_extra_url" ]]; then
  print_red "Error: No se pudo obtener la URL de Snort Extra."
elif [[ ! -f "$path/snort3_extras-$snort3_version.tar.gz" ]]; then
  sudo wget "$snort3_extra_url" -O "$path/snort3_extras-$snort3_version.tar.gz" || { print_red "Error: Falló la descarga de Snort Extra."; exit 1; }
else
  print_red "El archivo snort3_extras-$snort3_version.tar.gz ya existe en $path."
fi


# Descargar OpenAppID

if [[ ! -f "$path/snort-openappid.tar.gz" ]]; then
	sleep 1
fi

if [[ ! -f "$path/snort-openappid.tar.gz" ]]; then
  sudo wget "https://snort.org/downloads/openappid/snort-openappid.tar.gz" -O "$path/snort-openappid.tar.gz" || { print_red "Error: Falló la descarga de OpenAppID."; exit 1; }
else
  print_red "El archivo snort-openappid.tar.gz ya existe en $path."
fi

# Clonar repositorios de GitHub
repos=(
  "https://github.com/shirkdog/pulledpork3"
  "https://github.com/VectorCamp/vectorscan"
)


# Cambiar al directorio especificado
cd "$path" || { print_red "Error: No se pudo acceder al directorio $path"; exit 1; }

if [[ ! -d "$path/vectorscan" ]]; then
	# Procesar cada archivo comprimido
	for file in *.{tar.gz,tar.bz2}; do
	    # Verificar si el archivo existe (en caso de que no haya coincidencias con el patrón)
	    if [[ ! -f "$file" ]]; then
	        print_red "No se encontraron archivos compatibles en $path."
	        exit 1
	    fi

	    print_green "Procesando archivo: $file"

	    # Extraer según el tipo de archivo
	    if [[ "$file" == *.tar.gz ]]; then
	        tar -xzvf "$file" || { print_red "Error: Fallo al extraer $file"; exit 1; }
	    elif [[ "$file" == *.tar.bz2 ]]; then
	        tar -xjvf "$file" || { print_red "Error: Fallo al extraer $file"; exit 1; }
	    else
	        print_red "Tipo de archivo no reconocido: $file"
	    fi
	done
fi

print_green "Todos los archivos se extrajeron correctamente."


for repo in "${repos[@]}"; do
  repo_name=$(basename "$repo")
  repo_path="$path/$repo_name"
  if [[ -d "$repo_path" ]]; then
    print_red "El repositorio $repo_name ya está clonado en $repo_path."
  else
    sleep 1
    git clone "$repo" "$repo_path" || { print_red "Error: Falló el clon de $repo_name."; exit 1; }
  fi
done



#flags controladores 

flag_config="./.configure_done"
flag_make="./.make_done"
flag_install="./.install_done"
flag_cmake="./.cmake_done"
flag_copied="./.odp_copied"

######################################################

# gperftools-2.16
if [[ -d "$path/gperftools-2.16" ]]; then
	# Cambiar al directorio de gperftools
	cd "$path/gperftools-2.16" || { print_red "Error: No se pudo acceder a gperftools-2.16"; exit 1; }
	    if [[ ! -f "$flag_config" ]]; then
            sudo ./configure || { print_red "Error: La configuración falló."; exit 1; }
            touch "$flag_config" # Crear el flag de configuración
        else
            print_green "Configuración ya completada. Saltando..."
        fi
        
        # Paso de compilación
        if [[ ! -f "$flag_make" ]]; then
            sudo make -j$(nproc) || { print_red "Error: La compilación falló."; exit 1; }
            touch "$flag_make" # Crear el flag de compilación
        else
            print_green "Compilación ya completada. Saltando..."
        fi
        
        # Paso de instalación
        if [[ ! -f "$flag_install" ]]; then
            sudo make install || { print_red "Error: La instalación falló."; exit 1; }
            touch "$flag_install" # Crear el flag de instalación
        else
            print_green "Instalación ya completada. Saltando..."
        fi
fi

######################################################
sleep 3

# safeclib-3.8.1.0-gdfea26
if [[ -d "$path/safeclib-3.8.1.0-gdfea26" ]]; then
	# Cambiar al directorio de safeclib
	cd "$path/safeclib-3.8.1.0-gdfea26" || { print_red "Error: No se pudo acceder a safeclib-3.8.1.0-gdfea26"; exit 1; }
	    if [[ ! -f "$flag_config" ]]; then
            sudo ./configure || { print_red "Error: La configuración falló."; exit 1; }
            touch "$flag_config" # Crear el flag de configuración
        else
            print_green "Configuración ya completada. Saltando..."
        fi
        
        # Paso de compilación
        if [[ ! -f "$flag_make" ]]; then
            sudo make -j$(nproc) || { print_red "Error: La compilación falló."; exit 1; }
            touch "$flag_make" # Crear el flag de compilación
        else
            print_green "Compilación ya completada. Saltando..."
        fi
        
        # Paso de instalación
        if [[ ! -f "$flag_install" ]]; then
            sudo make install || { print_red "Error: La instalación falló."; exit 1; }
            touch "$flag_install" # Crear el flag de instalación
        else
            print_green "Instalación ya completada. Saltando..."
        fi
fi

sleep 3

######################################################

# snort3-libdaq-4807f58
if [[ -d "$path/snort3-libdaq-4807f58" ]]; then
	# Cambiar al directorio de snort3-libdaq-4807f58
	cd "$path/snort3-libdaq-4807f58" || { print_red "Error: No se pudo acceder a snort3-libdaq-4807f58"; exit 1; }
	    if [[ ! -f "$flag_config" ]]; then
		    sudo ./bootstrap || { print_red "Error: La bootstrap falló."; exit 1; }
            sudo ./configure || { print_red "Error: La configuración falló."; exit 1; }
            touch "$flag_config" # Crear el flag de configuración
        else
            print_green "Configuración ya completada. Saltando..."
        fi
        
        # Paso de compilación
        if [[ ! -f "$flag_make" ]]; then
            sudo make -j$(nproc) || { print_red "Error: La compilación falló."; exit 1; }
            touch "$flag_make" # Crear el flag de compilación
        else
            print_green "Compilación ya completada. Saltando..."
        fi
        
        # Paso de instalación
        if [[ ! -f "$flag_install" ]]; then
            sudo make install || { print_red "Error: La instalación falló."; exit 1; }
            touch "$flag_install" # Crear el flag de instalación
        else
            print_green "Instalación ya completada. Saltando..."
        fi
fi

sleep 3

######################################################


# Verificar si el directorio vectorscan existe
if [[ -d "$path/vectorscan" ]]; then
    print_green "El directorio 'vectorscan' existe. Procediendo con la compilación..."
    cd "$path/vectorscan" || { print_red "Error al acceder a $path/vectorscan"; exit 1; }
    
    # Crear el directorio build si no existe
    [[ -d build ]] || sudo mkdir build
    cd build || { print_red "Error al acceder a $path/vectorscan/build"; exit 1; }
    
    # Paso de cmake
    if [[ ! -f "$flag_cmake" ]]; then
        cmake -DUSE_CPU_NATIVE=on -DFAT_RUNTIME=off -DBUILD_AVX2=ON ../ || {
            print_red "Error al ejecutar cmake. Verifica los parámetros.";
            exit 1;
        }
        touch "$flag_cmake" # Crear el flag para cmake
    else
       print_green "CMake ya completado. Saltando..."
    fi

    # Paso de make
    if [[ ! -f "$flag_make" ]]; then
        make -j$(nproc) || {
            print_red "Error durante la compilación con 'make'. Verifica los errores."
            exit 1;
        }
        touch "$flag_make" # Crear el flag para make
    else
        print_green "Make ya completado. Saltando..."
    fi
    
    # Paso de instalación
    if [[ ! -f "$flag_install" ]]; then
        sudo make install || {
            print_red "Error durante la instalación con 'make install'."
            exit 1;
        }
        touch "$flag_install" # Crear el flag para instalación
    else
        print_green "Instalación ya completada. Saltando..."
    fi
    
else
    print_red "El directorio 'vectorscan' no existe. Verifica la ruta."
    exit 1
fi

sleep 3

######################################################




# Comprobar si el directorio snort3-snort3-d8f500e existe
if [[ -d "$path/snort3-snort3-006fe7a" ]]; then
        # Cambiar al directorio de Snort
        cd "$path/snort3-snort3-006fe7a" || { print_red "Error: No se pudo acceder a snort3-snort3-006fe7a"; exit 1; }

        # Paso de configuración
        if [[ ! -f "$flag_config" ]]; then
            sudo ./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc || {
                print_red "Error: La configuración falló.";
                exit 1;
            }
            touch "$flag_config" # Crear el flag de configuración
        else
            print_green "Configuración ya completada. Saltando..."
        fi

        # Cambiar al directorio build
        cd build || { print_red "Error: El cambio de directorio falló."; exit 1; }

        # Paso de compilación
        if [[ ! -f "$flag_make" ]]; then
            sudo make -j$(nproc) || { print_red "Error: La compilación falló."; exit 1; }
            touch "$flag_make" # Crear el flag de compilación
        else
            print_green "Compilación ya completada. Saltando..."
        fi

        # Paso de instalación
        if [[ ! -f "$flag_install" ]]; then
            sudo make install || { print_red "Error: La instalación falló."; exit 1; }
            sudo ldconfig
            touch "$flag_install" # Crear el flag de instalación
        else
            print_green "Instalación ya completada. Saltando..."
        fi

        print_green "snort3 se instaló correctamente."
fi


sleep 3

######################################################

# Verificar si el directorio odp existe
if [[ ! -d "/usr/local/lib/odp" ]]; then
    # Verificar si ya se realizó la copia previamente
    if [[ ! -f "$flag_copied" ]]; then
        # Copiar el directorio odp a /usr/local/lib
        cp -R "$path/odp/" "/usr/local/lib" || { print_red "Error: No se pudo copiar odp a /usr/local/lib"; exit 1; }
        touch "$flag_copied" # Crear el flag de copia completada
        print_green "odp se copió correctamente."
    else
        print_green "La carpeta 'odp' ya se copió anteriormente. Saltando..."
    fi
else
    print_green "La carpeta odp ya existe en /usr/local/lib"
fi

sleep 3

######################################################


# Comprobar si el directorio snort3-snort3_extra-b5eb667 existe
if [[ -d "$path/snort3-snort3_extra-b5eb667" ]]; then
    # Verificar si ya se ha copiado el archivo
    if [[ ! -f "$flag_config" ]]; then
        # Cambiar al directorio snort3-snort3_extra-b5eb667
        cd "$path/snort3-snort3_extra-b5eb667" || { print_red "Error: No se pudo acceder a snort3-snort3_extra-b5eb667"; exit 1; }

        # Exportar PKG_CONFIG_PATH
        export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig || { print_red "Error: No se pudo exportar la variable PKG_CONFIG_PATH"; exit 1; }

        # Configurar el proyecto
        ./configure_cmake.sh --prefix=/usr/local || { print_red "Error: La configuración falló."; exit 1; }
        touch "$flag_config" # Crear el flag de configuración
    else
        print_green "Configuración ya completada. Saltando..."
    fi

    # Cambiar al directorio build
    cd build || { print_red "Error: El cambio de directorio falló."; exit 1; }

    # Verificar si la compilación ya se ha realizado
    if [[ ! -f "$flag_make" ]]; then
        # Compilar el proyecto
        sudo make -j$(nproc) || { print_red "Error: La compilación falló."; exit 1; }
        touch "$flag_make" # Crear el flag de compilación
    else
        print_green "Compilación ya completada. Saltando..."
    fi

    # Verificar si la instalación ya se ha hecho
    if [[ ! -f "$flag_install" ]]; then
        # Instalar el proyecto
        sudo make install || { print_red "Error: La instalación falló."; exit 1; }
        sudo ldconfig
        touch "$flag_install" # Crear el flag de instalación
    else
        print_green "Instalación ya completada. Saltando..."
    fi

    print_green "snort3_extras se instaló correctamente."
fi

sleep 3

######################################################


#PulledPork3 y nuevas rules


# Mover el directorio pulledpork3 a /usr/local/etc/snort/
if [[ ! -d /usr/local/etc/snort/pulledpork3 ]]; then 
	mv $path/pulledpork3/ /usr/local/etc/snort/ && print_green "Movido pulledpork correctamente" || { print_red "Error al mover el directorio 'pulledpork3'."; exit 1; }
fi

if [[ ! -d /usr/local/etc/snort/pulledpork3 ]]; then 
	cd /usr/local/etc/snort/ || { print_red "Error al cambiar al directorio '/usr/local/etc/snort/pulledpork3/etc/'."; exit 1; }
	git clone "https://github.com/shirkdog/pulledpork3"
fi

# Cambiar al directorio /usr/local/etc/snort/pulledpork3/etc/
cd /usr/local/etc/snort/pulledpork3/etc/ || { print_red "Error al cambiar al directorio '/usr/local/etc/snort/pulledpork3/etc/'."; exit 1; }

# Renombrar el archivo pulledpork.conf a pulledpork.conf.orig
mv pulledpork.conf pulledpork.conf.orig || { print_red "Error al renombrar 'pulledpork.conf'."; exit 1; }



# Nombre del archivo de configuración
CONFIG_FILE="pulledpork.conf"


# Solicitar el oinkcode al usuario
read -p "https://www.snort.org/oinkcodes - Introduce tu oinkcode:  " oinkcode

# Crear el archivo con las configuraciones
cat << EOF > $CONFIG_FILE
LightSPD_ruleset = true
oinkcode = $oinkcode
snort_blocklist = true
et_blocklist = true
blocklist_path = /usr/local/etc/lists/default.blocklist
pid_path = /var/log/snort/snort.pid
ips_policy = security
rule_mode = simple
rule_path = /usr/local/etc/rules/snort.rules
local_rules = /usr/local/etc/rules/local.rules
ignored_files = includes.rules, snort3-deleted.rules
include_disabled_rules = true
sorule_path = /usr/local/etc/so_rules/
distro = ubuntu-x64
CONFIGURATION_NUMBER = 3.0.0.3
EOF

# Mostrar mensaje de confirmación
print_green "Archivo de configuración creado: $CONFIG_FILE"

# Crear el directorio /usr/local/etc/lists
mkdir -p /usr/local/etc/lists || { print_red "Error al crear el directorio '/usr/local/etc/lists'."; exit 1; }

# Crear el directorio /usr/local/etc/rules
mkdir -p /usr/local/etc/rules || { print_red "Error al crear el directorio '/usr/local/etc/rules'."; exit 1; }

# Crear el directorio /usr/local/etc/so_rules
mkdir -p /usr/local/etc/so_rules || { print_red"Error al crear el directorio '/usr/local/etc/so_rules'."; exit 1; }

# Crear el directorio /var/log/snort
mkdir -p /var/log/snort || { print_red "Error al crear el directorio '/var/log/snort'."; exit 1; }

# Crear el archivo vacío /usr/local/etc/rules/snort.rules
touch /usr/local/etc/rules/snort.rules || { print_red "Error al crear el archivo '/usr/local/etc/rules/snort.rules'."; exit 1; }

# Crear el archivo vacío /usr/local/etc/rules/local.rules
touch /usr/local/etc/rules/local.rules || { print_red "Error al crear el archivo '/usr/local/etc/rules/local.rules'"; exit 1; }

python3 /usr/local/etc/snort/pulledpork3/pulledpork.py -c /usr/local/etc/snort/pulledpork3/etc/pulledpork.conf -i -vv || { print_red "Error al ejecutar 'pulledpork.py'. Verifique el comando y la configuración."; exit 1; }

# Verificar si el archivo 'custom.lua' ya existe antes de descargarlo
if [ ! -f /usr/local/etc/snort/ ]; then
  cd /usr/local/etc/snort/
  wget https://gist.githubusercontent.com/da667/69e4c0bd8e8ab99d1ef851494567ac6c/raw/b39327a6e758bbe469ef198f068ff9bd8559853b/custom.lua || { print_red "Error al descargar 'custom.lua'. Verifique la URL o la conexión."; exit 1; }
else
  print_green "'custom.lua' ya existe, no se descargará."
fi

# Añadir la línea al archivo 'snort.lua'
echo "include 'custom.lua'" >> /usr/local/etc/snort/snort.lua || { print_red "Error al agregar la línea al archivo '/usr/local/etc/snort/snort.lua'. Verifica los permisos."; exit 1; }

# Ejecutar Snort
sudo snort --plugin-path=/usr/local/lib/snort --plugin-path=/usr/local/etc/so_rules/ -c /usr/local/etc/snort/snort.lua -T -v || { print_red "Error al ejecutar Snort. Verifica los parámetros y la configuración."; exit 1; }

# Crear el grupo 'snort'
groupadd snort || { print_red "Error al crear el grupo 'snort'. Verifica si ya existe."; exit 1; }

# Crear el usuario 'snort' asociado al grupo 'snort'
useradd -r -s /sbin/nologin -g snort snort || { print_red "Error al crear el usuario 'snort'. Verifica si ya existe."; exit 1; }

# Establecer permisos en el directorio de logs de Snort
chmod 5775 /var/log/snort || { print_red "Error al cambiar los permisos de '/var/log/snort'. Verifica los permisos actuales."; exit 1; }

# Cambiar la propiedad del directorio de logs a 'snort:snort'
chown -R snort:snort /var/log/snort || { print_red "Error al cambiar la propiedad de '/var/log/snort'. Verifica si el directorio existe."; exit 1; }

# Verificar si el archivo 'snort3.service' ya existe antes de descargarlo
if [ ! -f /usr/src/snort3.service ]; then
	cd "$path" || { print_red "Error: No se pudo cambiar al directorio $path."; exit 1; }
	sudo wget https://gist.githubusercontent.com/da667/28ed48c59f163aad31623f319851c07c/raw/96431875ea862ff5d1e4a2f15c6045086e38c2a4/snort3.service || { print_red "Error al descargar 'snort3.service'. Verifica la URL o la conexión."; exit 1; }
else
  print_green "'snort3.service' ya existe, no se descargará."
fi


# Obtener el nombre de la interfaz de red
tarjeta=$(ip --brief a | egrep -v "lo" | head -1 | awk '{print $1}')
if [ -z "$tarjeta" ]; then
    print_red "Error: No se pudo obtener la interfaz de red."
    exit 1
fi
print_green "La interfaz de red es: $tarjeta"

# Reemplazar "snort_iface1" con el nombre de la tarjeta en el archivo snort3.service
sed -i.bak "s/snort_iface1/$tarjeta/g" snort3.service
if [ $? -ne 0 ]; then
    print_red "Error: No se pudo actualizar el archivo snort3.service."
    exit 1
fi
print_green "Archivo snort3.service actualizado correctamente."

# Copiar el archivo al directorio de systemd
cp /usr/src/snort3.service /etc/systemd/system/
if [ $? -ne 0 ]; then
    print_red "Error: No se pudo copiar el archivo snort3.service a /etc/systemd/system/."
    exit 1
fi
print_green "Archivo snort3.service copiado a /etc/systemd/system/."

# Recargar los servicios y habilitar Snort
systemctl daemon-reload
if [ $? -ne 0 ]; then
    print_red "Error: No se pudo recargar los servicios de systemd."
    exit 1
fi

systemctl enable snort3.service
if [ $? -ne 0 ]; then
    print_red "Error: No se pudo habilitar el servicio snort3."
    exit 1
fi

systemctl start snort3.service
if [ $? -ne 0 ]; then
    print_red "Error: No se pudo iniciar el servicio snort3."
    exit 1
fi

systemctl status snort3.service
if [ $? -ne 0 ]; then
    print_red "Error: El servicio snort3 no está funcionando correctamente."
    exit 1
fi
print_green "Servicio snort3 iniciado correctamente."

# Descargar el script updater y darle permisos

CRON_FILE="updater"

cd /etc/cron.weekly/
if [ $? -ne 0 ]; then
    print_red "Error: No se pudo mover al directorio /etc/cron.weekly/."
    exit 1
fi

cat << EOF > $CRON_FILE
#!/bin/bash
#updater.sh - Weekly update script
#checks for updates, downloads them, then reboots the system.
#place this script in /etc/cron.weekly, ensure it is owned by root (chown root:root /etc/cron.weekly/updater)
#ensure the script has execute permissions (chmod 700 /etc/cron.weekly/updater)
#if you want updates to run once daily or monthly, you could also place this script into cron.daily, or cron.weekly.
#alternatively, edit /etc/crontab to create a crontab entry.

export DEBIAN_FRONTEND=noninteractive
apt-get -q update
apt-get -y -q dist-upgrade
python3 /usr/local/etc/snort/pulledpork3/pulledpork.py -c /usr/local/etc/snort/pulledpork3/etc/pulledpork.conf -i -vv
logger updater cron job ran successfully. rebooting system
init 6
exit 0
EOF


chmod 700 updater  
if [ $? -ne 0 ];  then
    print_red "Error: No se pudieron asignar permisos al archivo updater."
    exit 1
fi

print_green "El script updater ha sido descargado y se le han asignado permisos correctamente."