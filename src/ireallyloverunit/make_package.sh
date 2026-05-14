#!/bin/sh

version=0.1

ms_now() {
    date +%s%N
}

if [ -e package ]; then
    start=$(ms_now)

    printf "cleaning old build... "
    rm -rf package *.tar.zst

    end=$(ms_now)
    ms=$(( (end - start) / 1000000 ))
    echo "      done (${ms}ms)"
fi

start=$(ms_now)
printf "rebuilding... "
dub build --build=optimized --force >/dev/null
end=$(ms_now)
ms=$(( (end - start) / 1000000 ))
echo "              done (${ms}ms)"

start=$(ms_now)
mkdir -p package/usr/bin
printf "moving package files... "
cp ./ireallyloverunit package/usr/bin
end=$(ms_now)
ms=$(( (end - start) / 1000000 ))
echo "    done (${ms}ms)"

start=$(ms_now)
printf "creating package... "
echo "version $version" > package/car
tar -I zstd -cf ireallyloverunit.tar.zst package/
end=$(ms_now)
ms=$(( (end - start) / 1000000 ))
echo "        done (${ms}ms)"
