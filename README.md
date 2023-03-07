# process_image

Pentru explicarea implementari, am ales sa discut cateva lucruri generale despre fiecare stare a automatului. Astfel, avem:
-	Pentru TASK 1: Conversia imaginii din RGB in grayscale
*INIT - reprezinta o prima stare unde initializam anumite variabile cu valori initiale 	
*GRAY - starea in care sparg fiecare pixel in 3 parti, R, G, si B, calculez maximul si minimul dintre acestia, apoi fac media lor pentru a o aplica in pixel, pe pozitia din mijloc(pe cei 8 biti din mijloc). In aceeasi stare incrementez row si col pentru a trece la pixelul urmator. Verific de asemenea daca am ajuns la finalul imaginii. Mentionez ca imaginea a fost parcursa de la stanga la dreapta, de sus in jos.
*DONE	- este starea in care pun gray_done pe 1 pentru a anunta terminarea conversiei.
-	Pentru TASK 2: Compresia imaginii folosind metoda AMBTC
*AMBTC - este o stare de inceput a compresiei imaginii, unde initializez cateva variabile, pentru parcurgerea imaginii. Am divizat imaginea mea intr-o matrice de 16 pe 16 bloculete, fiecare bloculet reprezentand o matrice de 4 pe 4 pixeli.
*BLOCKINIT - in aceasta stare initializez cu 0 variabile necesare si caracteristice fiecarui bloculet, precum Lm, Hm, avg, var si cele urmatoare cu next, pentru schimbarea in fiecare ciclu de ceas.
*AVG - in mod clar, in aceasta stare calculez media elementelor din bloculet, parcurgand bloculetul de la stanga la dreapta, de sus in jos.
*VAR - in aceasta stare calculez deviatia standard si totodata tin evidenta bitilor cu valoare 1 din bitmap. 
*LH - este starea in care calculez Lm si Hm pentru fiecare bloculet, tinand cont de anumite conditii. In cazul in care nu exista biti de 1 in bitmap, Lm si Hm vor fi initializate cu 1.
*RECONS - in aceasta stare, pun pe iesire Lm sau Hm in functie de valoarea pixelului in comparatie cu media calculata, pentru fiecare pixel dintr-un bloculet.
*BLOCK - ultima stare necesara compresiei imaginii, are rolul de a trece la bloculetul urmator. Pentru bloculete, apelez la acelasi tip de parcurgere, de la stanga la dreapta, de sus in jos. 
