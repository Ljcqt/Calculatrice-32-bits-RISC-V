# Calculatrice 32-bits RISC-V

Ce projet est une calculatrice bas niveau écrite en assembleur RISC-V. Elle permet de lire, d'analyser et de résoudre des expressions mathématiques saisies par l'utilisateur directement dans la console, en supportant trois notations mathématiques différentes. Le programme est conçu pour être exécuté via le simulateur RARS.

## Fonctionnalités

Le programme propose un menu permettant de choisir le mode de calcul :

1. Notation Postfixée (Polonaise Inverse) : ex. `23,3,+`
2. Notation Préfixée (Polonaise) : ex. `+,23,3`
3. Notation Infixée (Classique) : ex. `23,+,3`

La calculatrice prend en charge les quatre opérations arithmétiques fondamentales :
* Addition (`+`)
* Soustraction (`-`)
* Multiplication (`*`)
* Division (`/`)

## Architecture

Le code source (`main.asm`) illustre plusieurs concepts de la programmation bas niveau et de l'architecture RISC-V :

* Gestion de la pile (Stack) : Utilisation rigoureuse des registres `sp` (Stack Pointer) et `fp` (Frame Pointer) pour la sauvegarde du contexte, des adresses de retour (`ra`), et la gestion de la mémoire locale lors des appels de fonctions.
* Structures de données : Implémentation de piles dédiées (`pile_val` pour les opérandes, `pile_op` pour les opérateurs) pour évaluer les expressions.
* Parsing de chaînes de caractères :
  * Postfixe : Parcours classique de gauche à droite.
  * Préfixe : Calcul préalable de la taille de la chaîne, puis parcours inversé de droite à gauche.
  * Infixe : Algorithme "Shunting-yard" simplifié, avec évaluation des priorités des opérateurs (fonction `prio`) et gestion des blocs entre parenthèses.

## Instructions d'exécution

Ce projet nécessite l'environnement de simulation **RARS** (RISC-V Assembler and Runtime Simulator).
