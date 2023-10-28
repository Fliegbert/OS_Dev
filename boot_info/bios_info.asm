
mov si, welcome_lbl
call print

welcome_lbl db 'Welcome to Sector 2', ENDL, 0
times 512 db 0
