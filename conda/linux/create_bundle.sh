#!/bin/bash

set -x

if [[ -z "$ARCH" ]]; then
  # Get the architecture of the system
  export ARCH=$(uname -m)
fi
conda_env="AppDir/usr"
echo -e "\nCreate the environment"

mamba create --copy -p ${conda_env} \
  -c AstoCAD/label/dev \
  -c freecad/label/dev \
  -c conda-forge \
  astocad[*dev] \
  python=3.11 \
  noqt5 \
  blas=*=openblas \
  blinker \
  calculix \
  docutils \
  ifcopenshell \
  lark \
  lxml \
  matplotlib-base \
  nine \
  numpy=1.26 \
  occt \
  olefile \
  opencamlib \
  opencv \
  pandas \
  pycollada \
  pythonocc-core \
  pyyaml \
  requests \
  scipy \
  sympy \
  typing_extensions \
  vtk \
  xlutils \
  -y

mamba run -p ${conda_env} python ../scripts/get_freecad_version.py
read -r version_name < bundle_name.txt

echo -e "\################"
echo -e "version_name:  ${version_name}"
echo -e "################"

echo -e "\nInstall additional addons"
mamba run -p ${conda_env} python ../scripts/install_addons.py ${conda_env}

mamba list -p ${conda_env} > AppDir/packages.txt
sed -i "1s/.*/\nLIST OF PACKAGES:/" AppDir/packages.txt

echo -e "\nDelete unnecessary stuff"
rm -rf ${conda_env}/include
find ${conda_env} -name \*.a -delete
mv ${conda_env}/bin ${conda_env}/bin_tmp
mkdir ${conda_env}/bin
cp ${conda_env}/bin_tmp/AstoCAD ${conda_env}/bin/
cp ${conda_env}/bin_tmp/AstoCADcmd ${conda_env}/bin/
cp ${conda_env}/bin_tmp/freecad ${conda_env}/bin/
cp ${conda_env}/bin_tmp/freecadcmd ${conda_env}/bin/
cp ${conda_env}/bin_tmp/ccx ${conda_env}/bin/
cp ${conda_env}/bin_tmp/python ${conda_env}/bin/
cp ${conda_env}/bin_tmp/pip ${conda_env}/bin/
cp ${conda_env}/bin_tmp/pyside6-rcc ${conda_env}/bin/
cp ${conda_env}/bin_tmp/gmsh ${conda_env}/bin/
cp ${conda_env}/bin_tmp/dot ${conda_env}/bin/
cp ${conda_env}/bin_tmp/unflatten ${conda_env}/bin/
cp ${conda_env}/bin_tmp/branding.xml ${conda_env}/bin/
sed -i '1s|.*|#!/usr/bin/env python|' ${conda_env}/bin/pip
rm -rf ${conda_env}/bin_tmp

echo -e "\nCopying Icon and Desktop file"
cp ${conda_env}/share/applications/com.astocad.desktop AppDir/
sed -i 's/Exec=FreeCAD/Exec=AppRun/g' AppDir/com.astocad.desktop
cp ${conda_env}/share/icons/hicolor/scalable/apps/AstoCAD.svg AppDir/


# Remove __pycache__ folders and .pyc files
find . -path "*/__pycache__/*" -delete
find . -name "*.pyc" -type f -delete

# reduce size
rm -rf ${conda_env}/conda-meta/
rm -rf ${conda_env}/doc/global/
rm -rf ${conda_env}/share/gtk-doc/
rm -rf ${conda_env}/lib/cmake/

find . -name "*.h" -type f -delete
find . -name "*.cmake" -type f -delete

if [ "$DEPLOY_RELEASE" = "weekly-builds" ]; then
  export tag="weekly-builds"
else
  export tag="latest"
fi

echo -e "\nCreate the appimage"
if [ "$ARCH" = "aarch64" ]; then
  export ARCH=arm_aarch64
fi
export GPG_TTY=$(tty)
export GPG_SIGN_KEY=""
if [[ -n "${GPG_KEY_ID}" ]]; then
  export GPG_SIGN_KEY="-s --sign-key ${GPG_KEY_ID}"
fi

chmod a+x ./AppDir/AppRun
../../appimagetool-$(uname -m).AppImage \
  -v --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
  ${GPG_SIGN_KEY} \
  AppDir ${version_name}.AppImage

echo -e "\nCreate hash"
shasum -a 256 ${version_name}.AppImage > ${version_name}.AppImage-SHA256.txt
