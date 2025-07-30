uname -ar
ldd --version || true
dpkg -s libc6 | grep Version || true

echo 'Installing build tools (g++, make, cmake) inside container...'
apt-get update && apt-get install -y build-essential python wget
wget https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4-linux-$ARCH.tar.gz
tar xvf cmake-3.26.4-linux-$ARCH.tar.gz -C /usr --strip-components=1

cd lib-src/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
cmake --build . --config Release --target Dictionaries
