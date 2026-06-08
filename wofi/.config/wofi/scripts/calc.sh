#!/usr/bin/env bash

expr=$(printf "" \
    | wofi --show dmenu \
           --prompt "= " \
           --width 420 --height 80 \
           --no-actions \
           --lines 0)

[[ -z "$expr" ]] && exit 0

result=$(python3 -c "
import math, cmath
try:
    print(eval('$expr', {'__builtins__': {}}, vars(math)))
except Exception as e:
    print('Error: ' + str(e))
" 2>&1)

notify-send -t 4000 -a "Calculator" "$expr = $result"
