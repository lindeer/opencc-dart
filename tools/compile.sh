echo '--- Inside ARM container ---'

echo 'Verifying glibc version inside container...'
ldd --version || true
dpkg -s libc6 | grep Version || true

echo 'Installing build tools (g++, make, cmake) inside container...'
apt-get update && apt-get install -y build-essential cmake python-3

cd lib-src/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
cmake --build . --config Release --target Dictionaries
cd -
