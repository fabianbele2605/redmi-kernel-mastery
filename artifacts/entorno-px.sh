# Carga el entorno de compilación del kernel de PixelExperience en ESTA terminal.
# uso (desde cualquier carpeta):   source ~/Escritorio/Mobil/artifacts/entorno-px.sh
#
# Define KSRC/KOUT (kernel-px y out-px) y la función kmake. Las funciones de bash solo
# viven en la terminal donde se cargan: en una terminal nueva hay que volver a ejecutarlo.
export KSRC="$HOME/Escritorio/Mobil/src/kernel-px"
export KOUT="$HOME/Escritorio/Mobil/out-px"
source "$HOME/Escritorio/Mobil/artifacts/build-env.sh"
