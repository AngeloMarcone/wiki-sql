# Wiki Progetto 2023/2024

- [Tabelle](#tabelle)
  - [Utente](#utente)
  - [Autore](#autore)
  - [Modifica](#modifica)
  - [Pagina](#pagina)
  - [Frase](#frase)
  - [Collegamento](#collegamento)
- [Domini](#domini)
  - [reputazionedomain](#reputazionedomain)
  - [statodominio](#statodominio)
- [Funzioni e Trigger](#funzioni-e-trigger)
  - [rep_aut()](#funzione-rep_aut)
  - [tr_rep_aut](#trigger-tr_rep_aut)
  - [aggiorna_caratteri_dopo_inserimento_modifica()](#funzione-aggiorna_caratteri_dopo_inserimento_modifica)
  - [aggiorna_caratteri_trigger](#trigger-aggiorna_caratteri_trigger)
  - [aggiorna_pagina_dopo_modifica_stato()](#funzione-aggiorna_pagina_dopo_modifica_stato)
  - [aggiorna_pagina_trigger](#trigger-aggiorna_pagina_trigger)

## Tabelle

1. **Utente**
   - `mail`: Indirizzo email dell'utente (Chiave Primaria).
   - `nome`: Nome dell'utente.
   - `cognome`: Cognome dell'utente.
   - `password`: Password dell'utente, con requisiti specifici.

2. **Autore**
   - `nomedarte`: Nome d'arte dell'autore (Chiave Primaria).
   - `annoiniziocarriera`: Anno di inizio della carriera dell'autore.
   - `utente`: Chiave esterna collegata all'utente.

3. **Modifica**
   - `codmod`: Codice univoco per ogni modifica (Chiave Primaria).
   - `fraseoriginale`: Frase originale prima della modifica.
   - `codfrase`: Codice della frase modificata.
   - `pagina`: Pagina associata alla modifica.
   - `frasemodificata`: Frase dopo la modifica.
   - `stato`: Stato della modifica (valore predefinito: NULL).
   - `dataoramod`: Data e ora della modifica.
   - `utente`: Chiave esterna collegata all'utente.
   - `autore`: Chiave esterna collegata all'autore.

4. **Pagina**
   - `link`: Link unico per ogni pagina (Chiave Primaria).
   - `titolo`: Titolo della pagina.
   - `dataoracreazione`: Data e ora di creazione della pagina.
   - `autore`: Chiave esterna collegata all'autore.

5. **Frase**
   - `codfrase`: Codice univoco per ogni frase.
   - `caratteri`: Testo della frase.
   - `pagina`: Chiave esterna collegata alla pagina (Chiave Primaria composta con codFrase).

6. **Collegamento**
   - `codfrase`: Chiave esterna collegata alla frase.
   - `pagina_frase`: Chiave esterna collegata alla pagina della frase.
   - `pagina_riferimento`: Chiave esterna collegata alla pagina di riferimento.
  
## Domini

1. `reputazionedomain`: Dominio che rappresenta la reputazione dell'utente come valore double (`double precision`). La reputazione è vincolata tra 0 e 100.

2. `statodominio`: Dominio che rappresenta lo stato di una modifica come valore intero (`integer`). Lo stato è vincolato ad essere uno tra i valori 0, 1 e Null.

## Funzione e Trigger

1. ### Funzione rep_aut()
   - Una funzione che calcola e aggiorna automaticamente la reputazione di un autore in base alle modifiche proposte.
   - La funzione tiene conto del numero di modifiche proposte, della frazione di modifiche accettate e del numero di pagine realizzate dall'autore.
   - La reputazione viene aggiornata nella tabella Utente.

1.1. ### Trigger tr_rep_aut
   - Un trigger che esegue la funzione rep_aut() automaticamente dopo l'inserimento o l'aggiornamento di una riga nella tabella Modifica.

```sql
CREATE OR REPLACE FUNCTION rep_aut()
RETURNS TRIGGER AS $$
DECLARE
    nomedarteDB VARCHAR(128);
    numero_di_modifiche_proposte INT;
    numero_di_pagine_realizzate INT;
    frazione_di_modifiche_accettate DOUBLE PRECISION;
    autore_rep DOUBLE PRECISION;
BEGIN
    SELECT Autore.nomedarte INTO nomedarteDB
    FROM Autore
    INNER JOIN Modifica ON Autore.utente = Modifica.utente
    WHERE Autore.utente = NEW.utente;

    SELECT COUNT(*) INTO numero_di_modifiche_proposte
    FROM Modifica m
    WHERE m.utente = NEW.utente;

    IF numero_di_modifiche_proposte > 0 THEN
		--calcolo frazione_di_modifiche_accettate che rappresenta la percentuale di modifiche proposte dall'utente che sono state accettate.
		SELECT COUNT(CASE WHEN m.stato = 1 THEN 1 END) * 100.0 / COUNT(*) 
		INTO frazione_di_modifiche_accettate
		FROM Modifica m
		WHERE m.utente = NEW.utente;
		
		IF nomedarteDB is NULL THEN
			autore_rep = frazione_di_modifiche_accettate / numero_di_modifiche_proposte;
		ELSE
			--calcolo in numero di pagine realizzate da un utente
			SELECT COUNT(DISTINCT p.link) INTO numero_di_pagine_realizzate
			FROM Pagina p JOIN Autore a 
			ON p.autore = a.nomedarte 
			JOIN Utente u 
			ON a.utente = u.mail
			WHERE u.mail = NEW.utente;

			--se il numero di pagine realizzate > 0 significa che e' un autore che creato una pagina. avra' una propria reputazione
			--se e' < 0 calcoliamo la reputazione come se fosse un nomrale utente.
			IF numero_di_pagine_realizzate > 0 THEN
				autore_rep = (frazione_di_modifiche_accettate * numero_di_pagine_realizzate) / numero_di_modifiche_proposte;
			ELSE
				autore_rep = frazione_di_modifiche_accettate / numero_di_modifiche_proposte;
			END IF;

		END IF;
		
		UPDATE Utente
		SET reputazione = autore_rep
		WHERE mail = NEW.utente;
		
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER tr_rep_aut
AFTER INSERT OR UPDATE ON Modifica
FOR EACH ROW
EXECUTE FUNCTION rep_aut();
```
   
2. ### Funzione aggiorna_caratteri_dopo_inserimento_modifica()

  - La funzione PostgreSQL `aggiorna_caratteri_dopo_inserimento_modifica()` è progettata per essere utilizzata come trigger dopo l'inserimento in una tabella `Modifica`. La funzione verifica se l'utente nella nuova riga corrisponde
  - all'utente associato a un autore nella tabella `autore`. In caso di corrispondenza, aggiorna le informazioni nelle tabelle `Frase` e `Modifica`.
  - riassumendo se un autore fa una modifica questa viene applicata immediatamente.
    
2.1. ### Trigger aggiorna_caratteri_trigger

  -Il trigger `aggiorna_caratteri_trigger` viene attivato automaticamente dopo l'inserimento di una nuova riga nella tabella Modifica. Esso esegue la funzione `aggiorna_caratteri_dopo_inserimento_modifica()` per gestire l'aggiornamento   
  -delle tabelle Frase e Modifica in base alle condizioni specificate.

```sql
CREATE OR REPLACE FUNCTION aggiorna_caratteri_dopo_inserimento_modifica()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.utente = (SELECT utente FROM autore WHERE nomedarte = NEW.autore) THEN
        UPDATE Frase
        SET caratteri = NEW.frasemodificata
        WHERE codfrase = NEW.codfrase AND pagina = NEW.pagina;
		
		UPDATE Modifica
        SET stato = 1
        WHERE codmod = NEW.codmod;
		
    END IF; 
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aggiorna_caratteri_trigger
AFTER INSERT ON Modifica
FOR EACH ROW
EXECUTE FUNCTION aggiorna_caratteri_dopo_inserimento_modifica();
```

3. ### Funzione: `aggiorna_pagina_dopo_modifica_stato()`
  - La funzione `aggiorna_pagina_dopo_modifica_stato()` è progettata per essere utilizzata come trigger. La funzione verifica se lo stato della modifica è impostato a 1 e, in caso affermativo,
  - aggiorna la colonna `caratteri` nella tabella `Frase` in base ai parametri specificati.

3.1 ### Trigger 'aggiorna_pagina_trigger'
  - Il trigger `aggiorna_pagina_trigger` viene attivato automaticamente dopo l'aggiornamento di una riga nella tabella `Modifica`. Esso esegue la funzione `aggiorna_pagina_dopo_modifica_stato()` per gestire l'aggiornamento della tabella
  - `Frase` in base allo stato specificato nella tabella `Modifica`.

```sql
CREATE OR REPLACE FUNCTION aggiorna_pagina_dopo_modifica_stato()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stato = 1 THEN
        UPDATE Frase
        SET caratteri = NEW.frasemodificata
        WHERE codfrase = NEW.codfrase AND pagina = NEW.pagina;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aggiorna_pagina_trigger
AFTER UPDATE ON Modifica
FOR EACH ROW
EXECUTE FUNCTION aggiorna_pagina_dopo_modifica_stato();
```

