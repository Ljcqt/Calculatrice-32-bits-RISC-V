.data 
	#message pour l'utilisateur
	menu: .asciz "CALCULATRICE : Postfixe(ex : 23,3,+)->numero 1 , Préfixe(ex : +,23,3)->numero 2 , Infixe(ex : 23,+,3)->numero 3.\n"
	mess_inv: .asciz "Entrez votre calcul\n"
	mess_res: .asciz "Le resultat est :\n"
	mess_err: .asciz "Erreur !\n"
	
	#memoire
	.align 2
	expr: .space 100 #stockage de la chaine utilisateur
	.align 2
	pile_val: .space 400 #stockage des nombres
	.align 2
	pile_op: .space 100 #stockage des operateurs
	
.text
.globl main
main:
	
	addi sp,sp,-64 #on se reserve 64 octets
	sw fp,60(sp) #sauvegarde du fp
	addi fp,sp,64 #sauvegarde de l'adresse de retour
	
	li a7,4
	la a0,menu
	ecall #affichage du message "menu"
	
	li a7,5
	ecall #lecture d'un entier (choix du mode)
	mv s11, a0 #on sauvegarde le choix dans s11
	
	li a7,4
	la a0,mess_inv
	ecall #affichage du message "mess_inv"
	
	li a7,8 #lire chaine de caractère
	la a0,expr #charge l'adresse de l'espace du .data
	li a1,100 #taille disponible pour l'expression
	ecall
	
	li t0,1
	beq s11,t0,postfixe_suiv #si valeur rentree=1 -> postfixe
	
	li t0,2
	beq s11,t0,prefixe_suiv #si valeur rentree=2 -> prefixe
	
	li t0,3
	beq s11,t0,infixe_suiv #si valeur rentree=3 -> infixe
	
	li a7, 4 #utilisateur rentre autre chose que {1,2,3} -> erreur
        la a0, mess_err
        ecall
        j fin_main
        
postfixe_suiv: #si entree=1 -> on appelle postfixe avec la chaine dans a0
    	la a0, expr
    	jal Postfixe
    	j afficher_resultat 

prefixe_suiv: #si entree=2 -> on appelle prefixe avec la chaine dans a0
    	la a0, expr
    	jal Prefixe
    	j afficher_resultat

infixe_suiv: #si entree=3 -> on appelle infixe avec la chaine dans a0
    	la a0, expr
    	jal Infixe
    	j afficher_resultat
	
afficher_resultat:
	mv s0,a0 #on sauvegarde le resultat dans a0
	
	li a7,4
	la a0,mess_res #on charge le message "mess_res"
	ecall #affichage
	
	li a7,1
	mv a0,s0
	ecall #affichage du résultat
	
fin_main:
	#on restitue les 64 octets reserves
	lw ra,56(sp)
	lw fp,60(sp)
	addi sp,sp,64
	
	li a7,10
	ecall #fin du programme
	
#Fonction 1 -> postfixe(a0: adresse de la chaine)
Postfixe :
    	#on se reserve de la place dans la pile
    	addi sp, sp, -64
    	sw fp, 60(sp)
    	addi fp, sp, 64
    	sw ra, 56(sp)
    
    	li t0, 48 #correspond au 0
    	li t1, 57 #correspond au 9
    	la t3, pile_val  #pile      
   	li t4, 43 #correspond au +
    	li t5, 45 #correspond au -
    	li t6, 42 #correspond au *
    	li s1, 47 #correspond au /
    
    	li s2, 0 #initalisation du total
    
post_while :         
    	lb t2, 0(a0) #on lit un caractere
    	beq t2, zero, post_suite_while #si c'est \0, passe a la suite
 
    	blt t2, t0, post_sinon #si <48 ("0")->sinon
    	bgt t2, t1, post_sinon #si >57 ("9")->sinon
    
    	sub t2, t2, t0 #char -> chiffre
    	li a2, 10
    	mul s2, s2, a2 #decale le total
    	add s2, s2, t2 #ajoute le nouveau chiffre


    	lb a2, 1(a0) #caractere suivant
    	blt a2, t0, post_push_num #si le prochain n'est pas un chiffre
    	bgt a2, t1, post_push_num #si le nombre est fini, on l'empile
    	j post_fin_if #si c'est encore un chiffre, on boucle

post_push_num:
    	sw s2, 0(t3) #on empile le nombre
    	addi t3, t3, 4 #on avance le pointeur
    	li s2, 0 #on remet le total à 0
    	j post_fin_if

post_sinon:
    #verification de l'operateur
    	beq t2, t4, suiv_op
    	beq t2, t5, suiv_op
    	beq t2, t6, suiv_op
    	beq t2, s1, suiv_op
    	j post_fin_if
     
suiv_op:
    	#recuperation des nombres
    	lw s3, -4(t3) #on recule d'un octet     
    	lw s4, -8(t3) #on recule de 2 octets  
    	addi t3, t3, -8 #met à jour le pointeur de pile

    	bne t2, t4, post_sinon1 #si différent de + -> suite
    	add s2, s4, s3 #addition
    	j post_store_res

post_sinon1:
    	bne t2, t5, post_sinon2 #si différent de - -> suite
    	sub s2, s4, s3 #soustraction
    	j post_store_res

post_sinon2:
    	bne t2, t6, post_sinon3 #si différent de * -> suite
    	mul s2, s4, s3 #multiplication
    	j post_store_res

post_sinon3:
   	div s2, s4, s3 # division

post_store_res:
    	sw s2, 0(t3) #on sauvegarde le resultat de la pile
    	addi t3, t3, 4 #on avance le pointeur
    	li s2, 0 #on met le total a 0
    
post_fin_if :
    	addi a0, a0, 1 #caractere suivant
    	j post_while

post_suite_while:
    	addi t3, t3, -4  #on recule pour lire le dernier resultat
    	lw a0, 0(t3)  #on met ce résultat dans a0
    
    	#on restore le stockage qu'on avais reserve
    	lw ra, 56(sp)
    	lw fp, 60(sp)
    	addi sp, sp, 64
    	ret
    
#Fonction 2 -> prefixe(a0: adresse de la chaine)
Prefixe:
	#on se réserve de la place dans la pile
	addi sp, sp, -64
	sw fp, 60(sp)
	addi fp, sp, 64
	sw ra, 56(sp)
	sw a0, 0(sp) #sauvegarde de l'adresse de la chaine

	jal TailleChaine #renvoie la taille de la chaine dans a1

	lw a0, 0(sp) #on recharge l'adresse de la chaine

	sw s5, 52(sp) #sauvegarde du compteur
	mv s5, a1

	add a0, a0, a1
	addi a0, a0, -1 #on se place a l'adresse du dernier caractère

	li t0, 48 #correspond au 0
	li t1, 57 #correspond au 9
	la t3, pile_val #pile      
	li t4, 43 #correspond au +
	li t5, 45 #correspond au -
	li t6, 42 #correspond au *
	li s1, 47 #correspond au /

	li s2, 0 #total
	li a3, 1 #multiplicateur

pre_while:
	beq s5, zero, pre_suite_while #si s5 vaut 0 on a fait tout les char
	lb t2, 0(a0) #on lit un caractère

	blt t2, t0, pre_sinon #si < 48 ("0") -> sinon
	bgt t2, t1, pre_sinon #si > 57 ("9") -> sinon

	sub t2, t2, t0 #char -> chiffre
	mul t2, t2, a3 #chiffre*multiplicateur
	add s2, s2, t2 #total += Valeur

	li a2, 10
	mul a3, a3, a2 #on multiplie le multiplicateur par 10

	lb a2, -1(a0) #caractere précedent      
	blt a2, t0, pre_num #si pas un chiffre
	bgt a2, t1, pre_num #si nombre fini
	j pre_fin_if

pre_num:
	sw s2, 0(t3) #on empile le nombre
	addi t3, t3, 4 #on avance le pointeur de pile
	li s2, 0 #on remet le total à 0
	li a3, 1 #on remet le multiplicateur à 1
	j pre_fin_if

pre_sinon:
	#verification de l'operateur
	beq t2, t4, pre_suiv_op
	beq t2, t5, pre_suiv_op
	beq t2, t6, pre_suiv_op
	beq t2, s1, pre_suiv_op
	j pre_fin_if
	
pre_suiv_op:
	#recuperation des nombres
	lw s3, -4(t3) #on recule d'un octet     
	lw s4, -8(t3) #on recule de 2 octets  
	addi t3, t3, -8 #met à jout pointeur de pile

    
	bne t2, t4, pre_sinon1 #si different de + -> suite
	add s2, s4, s3  #addition
	j pre_store_res

pre_sinon1:
	bne t2, t5, pre_sinon2 #si c'est pas un -
	sub s2, s3, s4 
	j pre_store_res

pre_sinon2:
	bne t2, t6, pre_sinon3 #si c'est pas un *
	mul s2, s3, s4  
	j pre_store_res

pre_sinon3:
	div s2, s3, s4

pre_store_res:
	sw s2, 0(t3) #on sauvegarde le résultat dans la pile
	addi t3, t3, 4 #on met le pointeur de pile a jour
	li s2, 0 #on vide le total
    
pre_fin_if :
	addi a0, a0, -1 #on recule d'un caractere
	addi s5, s5, -1 #on décremente le compteur de caractere restant
	j pre_while
    
pre_suite_while:
	addi t3, t3, -4 #on recule de 4 octets
	lw a0, 0(t3) #on remet le caractere dans a0
    
	#on restore le stockage qu'on avais reservé
	lw s5, 52(sp)
	lw ra, 56(sp)
	lw fp, 60(sp)
	addi sp, sp, 64
	ret
    
#Fonction 3 -> Taille chaine (a0: adresse de la chaine)
TailleChaine:

	#on reserve de la memoire pour la fonction
	addi sp, sp, -64
	sw fp, 60(sp)
	addi fp, sp, 64
	sw ra, 56(sp)

	#on met le pointeur dans t0 et on crée initialise le compteur à 0
	mv t0, a0
	li t1, 0

boucle:          
	lb t2, 0(t0) #on charge le caractère
	beq t2, zero,suite #si c'est \0 -> suite  
	li t3, 10 #charge \n      
	addi t0, t0, 1 #on avance le pointeur d'un octet
	addi t1, t1, 1 #on incrémente le compteur de 1
	j boucle

suite:
	mv a1, t1 #on met la taille dans t1

	#on restaure la mémoire reservé
	lw ra, 56(sp)
	lw fp, 60(sp)
	addi sp, sp, 64
	ret

#Fonction 4 -> infixe(a0: adresse de la chaine)
Infixe:
	#on se réserve de la place dans la pile
	addi sp, sp, -64
	sw fp, 60(sp)
	addi fp, sp, 64
	sw ra, 56(sp)
	
	la t3, pile_val #pointeur pile valeurs
	la s4, pile_op #pointeur pile opérateur
	mv s5, s4 # garde l'adresse de base de pile_op
	
	li s6, 40 # '('
	li s7, 41 # ')'
	li s2, 0 #variable pour total
	
in_while:
	li t0, 48 #correspond à 0
	li t1, 57 #correspond à 9
	li t4, 43 #correspond à +
	li t5, 45 #correspond à -
	li t6, 42 #correspond à *
	li s1, 47 #correspond à /

	lb t2, 0(a0) #on lit le caractere
	beq t2, zero, in_suite_while #si \0 -> suite

	blt t2, t0, in_sinon #si < 48 ("0") -> sinon
	bgt t2, t1, in_sinon #si > 57 ("9") -> sinon


	sub t2, t2, t0 #char -> chiffre
	li a2, 10
	mul s2, s2, a2 #decale l'ancien total
	add s2, s2, t2 #ajoute nouveau chiffre


	lb a2, 1(a0) #char suivant
	blt a2, t0, in_num #si pas un chiffre, on continue
	bgt a2, t1, in_num #nb fini, on continue
	j in_fin_if

in_num:
	sw s2, 0(t3) #on empile le nombre
	addi t3, t3, 4 #on avance le pointeur de pile
	li s2, 0 #on remet le total à 0 pour le prochain nombre
	j in_fin_if

in_sinon:
	bne t2, s6, in_sinon_2 # si different de (  -> sinon2
	sb t2, 0(s4) #on range ( au sommet de la pile des opérateurs
	addi s4, s4, 1 #on avance le pointeur de la pile des opérateurs
	j in_fin_if

in_sinon_2:
	bne t2, s7, in_sinon_prio #si ce n'est pas ) -> Sinon prio

in_boucle_parenthese:
	ble s4, s5, in_fin_parenthese  #si on trouve la base de la pile, on arrete
	lb a2, -1(s4) #on regarde l'operateur precedent
	beq a2, s6, in_pop_parenthese #si ( -> fin
    
	sw a0, 0(sp) #on sauvegarde l'adresse du texte
	sw t2, 4(sp) #on sauvegarde )
	jal ra, depiler_et_calculer #on réalise le calcul et range le resultat
	lw t2, 4(sp) #on restaure )
	lw a0, 0(sp) #on restaure l'adresse du texte
	j in_boucle_parenthese    

in_pop_parenthese:
	addi s4, s4, -1 #on retire la dernière parenthese

in_fin_parenthese:
	j in_fin_if #fini pour ce char  
	
in_sinon_prio:
	#verification que c'est un operateur (+,-,*,/)
	beq t2, t4, in_boucle_prio
	beq t2, t5, in_boucle_prio
	beq t2, t6, in_boucle_prio
	beq t2, s1, in_boucle_prio
	j in_fin_if                  

in_boucle_prio:
	ble s4, s5, in_fin_boucle_prio #stop si la pile est vide
	lb a2, -1(s4) #on regarde le dernier operateur
	beq a2, s6, in_fin_boucle_prio #stop si c'est une (
    
	sw a0, 0(sp) #sauvegarde de a0
	sw t2, 4(sp) #sauvegarde de t2
	mv a0, a2    #on met l'operateur en haut dans a0
	jal ra, prio #appel fonction prio
	mv a6, a1 #valeur de prio dans a6
    

	lw a0, 4(sp) #opérateur actuel dans a0
	jal ra, prio #appel fonction prio
	mv a7, a1 #valeur de prio dans a7
    
	#on restaure nos variables
	lw t2, 4(sp)                    
	lw a0, 0(sp)
    
	blt a6, a7, in_fin_boucle_prio #si prio(Sommet) < prio(Actuel), on arrête de dépiler.
    
	sw a0, 0(sp)
	sw t2, 4(sp)
	jal ra, depiler_et_calculer #calcul avec l'ancien opérateur
	lw t2, 4(sp)
	lw a0, 0(sp)
	j in_boucle_prio              

in_fin_boucle_prio:
	sb t2, 0(s4) #on ajoute l'opérateur actuel dans la pile op
	addi s4, s4, 1 #on incrémente le pointeur
	
in_fin_if :
	addi a0, a0, 1 #on passe au char suivant
	j in_while                    

in_suite_while:
in_while_reste:
	ble s4, s5, in_fin_tout #si pile operateur vide -> fin
	sw a0, 0(sp)
	jal ra, depiler_et_calculer #on calcule l'opération restante
	lw a0, 0(sp)
	j in_while_reste

in_fin_tout:
	addi t3, t3, -4 #on recule pour pointer le res
	lw a0, 0(t3) #on le met dans a0
    
	#on restaure la mémoire reservé
	lw ra, 56(sp)                 
	lw fp, 60(sp)                  
	addi sp, sp, 64                 
	ret
	
#Fonction 5 -> prio (a0: operateur)
prio :

	addi sp, sp, -64
	sw fp, 60(sp)
	addi fp, sp, 64
	sw ra, 56(sp)
	
	mv t0, a0  #met l'opérateur dans t0
	li t4, 43  #charge +
	li t5, 45  #charge -
	li t6, 42  #charge *
	li t2, 47  #charge /

	beq t0, t4, in_prio_1 #si c'est '+', va à la priorité 1
	beq t0, t5, in_prio_1 #si c'est '-', va à la priorité 1
	beq t0, t6, in_prio_2 #si c'est '*', va à la priorité 2
	beq t0, t2, in_prio_2 #si c'est '/', va à la priorité 2
	li a1, 0 #si c'est autre chose () -> 0
	j fin_prio #on met la prio dans a1.
    
in_prio_1:
	li a1, 1              #la prio est de 1
	j fin_prio            #on on saute à la fin
	
in_prio_2:
	li a1, 2              #la prio est de 2
	j fin_prio            #on saute à la fin

fin_prio:
	lw ra, 56(sp)
	lw fp, 60(sp)
	addi sp, sp, 64
	ret
	
#Fonction 6 -> calcul et stockage
depiler_et_calculer:

	addi sp, sp, -64
	sw fp, 60(sp)
	addi fp, sp, 64
	sw ra, 56(sp)
	lb t5, -1(s4) #lit le dernier opérateur
	addi s4, s4, -1 #avance au prochain opérateur

	lw t6, -4(t3) #lit l'operande 2
	lw a2, -8(t3) #lit l'operande 1
	addi t3, t3, -8 #descend le pointeur de 2 operandes

    
	li a3, 43 #charge '+'
	bne t5, a3, in_c_sou #si différent de + -> suivant
	add a4, a2, t6 #addition
	j in_c_sauv #pour stocker le res

in_c_sou:
	li a3, 45 #charge '-'
	bne t5, a3, in_c_mul #si différent de '-' ->suivant
	sub a4, a2, t6 #soustraction
	j in_c_sauv #pour stocker le res

in_c_mul:
	li a3, 42 #charge '*'       
	bne t5, a3, in_c_div #si différent de '*' -> division
	mul a4, a2, t6 #multiplication
	j in_c_sauv #pour stocker le res

in_c_div:
    	div a4, a2, t6  #division

in_c_sauv:
    	#on range le résultat
    	sw a4, 0(t3) #on met le res en haut de la pile à nombre
    	addi t3, t3, 4 #on monte le pointeur d'un nombre
    
    	lw ra, 56(sp)
	lw fp, 60(sp)
	addi sp, sp, 64
	ret
