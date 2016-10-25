TITLE  SmallTetris

Comment #
                        Small Tetris
                        ~~~~~~~~~~~~
par FLAMENT Alexandre
commencé le    : 24/03/96 v1.0  (290 octets)
                 21/04/97 v1.1      
dernière modif : 01/05/97

BH = 0
CX = Tempo
DX = Position de la pièce (DH,DL)
BP = Rotation de la pièce
SI = Pièce
        #

JeuDX    equ  1                 ; Colonne de départ du jeu
JeuFX    equ  16                ; Colonne de fin du jeu
JeuFY    equ  20                ; Ligne de fin du jeu (ligne de début = 0)
Tour     equ  '.'               ; Caractère du bord du jeu
Piece    equ  '.'               ; Caractère des pièces
ColTour  equ  9h                ; Couleur du bord du jeu
ColPiece equ  7h                ; Couleur des pièces
Tempo    equ  5                 ; Attente avant la descente = Tempo*1/18.2 s
                
.MODEL TINY  
.386

.CODE         

ORG 100H
START:
;** programme principal
        ;Init de l'écran
        mov     al,3                    ; AH déjà à 0 <= DOS
        int     10h
        mov     ax,1112h                ; 80x50
;        xor     bl,bl                  ; BL déjà à 0 <= DOS
        int     10h             
        ;ES=0B800h, FS=40h
        Push    0B800h
        pop     es
        push    40h
        pop     fs

        ;Affiche l'écran du jeu
          ;les cotés du jeu
;        mov     di,(JeuDX-1)*2         ; DI=0 <= DOS
        xor     di,di
        mov     ax,ColTour*256+Tour
        mov     cl,JeuFY                ; CH=0 <= DOS
b1:
        stosw
        add     di,(JeuFX-JeuDX+1)*2
        stosw
        add     di,160-(JeuFX-JeuDX+3)*2
        loop    b1

        mov     cl,JeuFX-JeuDX+3
        rep     stosw
          ;le score
        mov     al,'0'
        mov     cl,5
        rep     stosw
        ;une nouvelle pièce
newp:
        ; Score=Score+3
        mov     cl,3
        call    shows
        ; une pièce au hazard
        mov     al,fs:[6Ch]
        and     ax,7
        mov     si,ax
;        xor     bp,bp
        ;  position = en haut au milieu
        mov     dx,8+1*256      
        ;init du compteur de temp
bmain_tempo:
        mov     cl,Tempo
bmain:
        ; Affiche la pièce
        mov     ax,Piece        
        call    ShowP
        ; Attend une touche ou un 1/18.2 seconde
        hlt
        ; Efface la pièce
        mov     al,' '                  ; ah = 0 <- mov ax,Piece
        call    ShowP
        mov     ah,1
        int     16h
        jz      attendre
        xor     ax,ax
        int     16h
        cmp     al,'8'
        jne     pas8
        inc     bp
        call    testp
        jnc     bmain
        dec     bp
;        jmp     bmain
pas8:
        cmp     al,'5'
        je      downp
        sub     al,'4'
        cmp     al,2
        ja      pas46
        push    dx
        dec     al
        add     dl,al
        call    testp
        jc      pasbon
        pop     di
        push    dx
pasbon:        
        pop     dx
;        jmp     bmain
pas46:
        cmp     al,27-'4'
        jne     bmain
finprg:
        ret
        ;boucle d'attente        
attendre:
        loop    bmain
downp:
        inc     dh
        call    testp
        jnc     bmain_tempo
        ;La pièce est en haut ? oui -> perdu
fini:
        dec     dh
        mov     ax,Piece
        call    ShowP
        dec     dh
        je      finprg
        ;Test s'il y a des lignes
        mov     dh,JeuFY-1
b2_0:
        mov     dl,JeuDX-1
b2:
        inc     dl
        mov     ah,2h
        int     10h
        mov     ah,8h
        int     10h
        cmp     al,Piece
        jne     pasdeligne        
        cmp     dl,JeuFX
        jb      b2
          ; Une ligne de trouvée
        mov     ax,0701h
        mov     bh,7
        mov     cl,JeuDX                ; CH tjrs à 0
        int     10h
        xor     bh,bh                   ; BH = 0 pour le reste du prog
        inc     dh
        mov     cl,7                    ; Une ligne = 7 points
        call    shows
pasdeligne:
        dec     dh
        jnz     b2_0
        jmp     newp                    ; Saut long <= Delta = 149

;** codage des pièces
t       db    00001011b         ;4
carre   db    01001110b         ;0
ld      db    00010111b         ;2
ld2     db    00010111b         ;2 pour avoir 7 possibilitées
zg      db    01000111b         ;6
zd      db    01100111b         ;5
lg      db    10010111b         ;3
;barre   db    11111101b        ;1 codé dans le STD de ShowS

;** Ajout CL au score et l'affiche
ShowS   proc near
        std
ssb:
        mov   di,(JeuFY)*160+(JeuFX+6)*2
        mov   si,di
ssb2:
        lods  word ptr es:[si]     
        cmp   al,'9'
        jne   nooverf
        mov   al,'0'
        stosw
        jmp   ssb2
nooverf:
        inc   byte ptr es:[di]
        loop  ssb  
        ret
ShowS   endp

;** Test si la pièce peut s'afficher
TestP   proc near
        mov     ah,6
TestP   endp

;** Affiche ou test la pièce CurP,CurR en (DL,DH) avec le caractère AL
ShowP   proc near
        pusha
        mov     saut,ah
        mov     bl,ds:[si+t]    
        mov     cl,5
bsp:
        ;positione le curseur
        mov     ah,02h
        int     10h
        ;calcul le déplacement
        push    ax
        mov     al,bl
        add     ax,bp
        and     al,3
        shl     al,2
        add     al,0C2h
        mov     ctm,al
        pop     ax

        shr     bl,2
        db      0EBh
saut    db      00h
        ;Affichage du caractère dans AL
on_aff:
        mov     ah,0Eh
        int     10h
        jmp     next
        ;Test si la pièce peut s'afficher
on_test:
        mov     ah,08h
        int     10h
        cmp     al,' '          ; AL détruit mais pas important pour le test
        stc
        jne     cantdoit
        ;effectue le déplacement        
next:   db      0FEh            ; Code pour Inc/Dec dl/dh
ctm     db      0C2h            ; C2:Droite, C6:Bas, CA:Gauche, CE:Haut
        loop    bsp
        clc
cantdoit:
        popa
        ret
ShowP   endp

END START
