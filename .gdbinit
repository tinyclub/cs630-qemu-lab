shell echo -e "\nWaiting for 2 secs..."
shell sleep 2
shell echo -e "Executing gdb commands in local .gdbinit ..."

shell echo -e "\n(gdb) target remote :1234"
target remote :1234

shell sleep 1
shell echo -e "\n(gdb) break start"
b start
b _start

shell sleep 1
shell echo -e "\n(gdb) break main"
b main

shell sleep 1
shell echo -e "\n(gdb) continue"
c

shell sleep 1
shell echo -e "\n(gdb) backtrace"
bt

shell sleep 1
shell echo -e "\n(gdb) list"
l
