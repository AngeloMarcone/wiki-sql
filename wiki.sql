PGDMP  +                    |            wiki2.0    16.1    16.1 )    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    41190    wiki2.0    DATABASE     �   CREATE DATABASE "wiki2.0" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE "wiki2.0";
                postgres    false            d           1247    90113    reputazionedomain    DOMAIN     �   CREATE DOMAIN public.reputazionedomain AS double precision
	CONSTRAINT reputazionedomain_check CHECK (((VALUE >= (0)::double precision) AND (VALUE <= (100)::double precision)));
 &   DROP DOMAIN public.reputazionedomain;
       public          postgres    false            k           1247    106497    statodominio    DOMAIN     q   CREATE DOMAIN public.statodominio AS integer
	CONSTRAINT statodominio_check CHECK ((VALUE = ANY (ARRAY[0, 1])));
 !   DROP DOMAIN public.statodominio;
       public          postgres    false            �            1255    49185 .   aggiorna_caratteri_dopo_inserimento_modifica()    FUNCTION     �  CREATE FUNCTION public.aggiorna_caratteri_dopo_inserimento_modifica() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 E   DROP FUNCTION public.aggiorna_caratteri_dopo_inserimento_modifica();
       public          postgres    false            �            1255    49165 %   aggiorna_pagina_dopo_modifica_stato()    FUNCTION     1  CREATE FUNCTION public.aggiorna_pagina_dopo_modifica_stato() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.stato = 1 THEN
        UPDATE Frase
        SET caratteri = NEW.frasemodificata
        WHERE codfrase = NEW.codfrase AND pagina = NEW.pagina;
    END IF;
    RETURN NEW;
END;
$$;
 <   DROP FUNCTION public.aggiorna_pagina_dopo_modifica_stato();
       public          postgres    false            �            1255    98311 	   rep_aut()    FUNCTION     :  CREATE FUNCTION public.rep_aut() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
     DROP FUNCTION public.rep_aut();
       public          postgres    false            �            1259    41198    autore    TABLE     '  CREATE TABLE public.autore (
    nomedarte character varying(128) NOT NULL,
    annoiniziocarriera date NOT NULL,
    utente character varying(128) NOT NULL,
    CONSTRAINT check_annoiniziocarriera CHECK (((annoiniziocarriera >= '1900-01-01'::date) AND (annoiniziocarriera <= CURRENT_DATE)))
);
    DROP TABLE public.autore;
       public         heap    postgres    false            �            1259    49170    collegamento    TABLE     �   CREATE TABLE public.collegamento (
    codfrase integer,
    pagina_frase character varying(128),
    pagina_riferimento character varying(128)
);
     DROP TABLE public.collegamento;
       public         heap    postgres    false            �            1259    41223    frase    TABLE     �   CREATE TABLE public.frase (
    codfrase integer NOT NULL,
    caratteri character varying(1000),
    pagina character varying(128) NOT NULL
);
    DROP TABLE public.frase;
       public         heap    postgres    false            �            1259    73728    modifica_id_sequence    SEQUENCE     }   CREATE SEQUENCE public.modifica_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.modifica_id_sequence;
       public          postgres    false            �            1259    41235    modifica    TABLE     (  CREATE TABLE public.modifica (
    codmod integer DEFAULT nextval('public.modifica_id_sequence'::regclass) NOT NULL,
    fraseoriginale character varying(1000),
    codfrase integer NOT NULL,
    pagina character varying(128) NOT NULL,
    frasemodificata character varying(1000),
    dataoramod timestamp without time zone NOT NULL,
    utente character varying(128) NOT NULL,
    autore character varying(128) NOT NULL,
    stato public.statodominio DEFAULT NULL::integer,
    CONSTRAINT check_dataoramod CHECK ((dataoramod <= CURRENT_TIMESTAMP))
);
    DROP TABLE public.modifica;
       public         heap    postgres    false    221    875    875            �            1259    98304    numero_di_modifiche_proposte    TABLE     G   CREATE TABLE public.numero_di_modifiche_proposte (
    count bigint
);
 0   DROP TABLE public.numero_di_modifiche_proposte;
       public         heap    postgres    false            �            1259    41213    pagina    TABLE     �  CREATE TABLE public.pagina (
    link character varying(128) NOT NULL,
    titolo character varying(128) NOT NULL,
    dataoracreazione timestamp without time zone NOT NULL,
    autore character varying(128) NOT NULL,
    CONSTRAINT check_dataoracreazione CHECK ((dataoracreazione <= CURRENT_TIMESTAMP)),
    CONSTRAINT check_lunghezza_titolo CHECK ((length((titolo)::text) <= 255))
);
    DROP TABLE public.pagina;
       public         heap    postgres    false            �            1259    41191    utente    TABLE       CREATE TABLE public.utente (
    mail character varying(128) NOT NULL,
    nome character varying(128) NOT NULL,
    cognome character varying(128) NOT NULL,
    password character varying(128) NOT NULL,
    reputazione public.reputazionedomain,
    CONSTRAINT check_password_valida CHECK ((((password)::text ~ '[A-Z]'::text) AND ((password)::text ~ '[a-z]'::text) AND ((password)::text ~ '[0-9]'::text) AND (length((password)::text) >= 8))),
    CONSTRAINT checkemail_valida CHECK (((mail)::text ~~ '%@%.%'::text))
);
    DROP TABLE public.utente;
       public         heap    postgres    false    868            �          0    41198    autore 
   TABLE DATA           G   COPY public.autore (nomedarte, annoiniziocarriera, utente) FROM stdin;
    public          postgres    false    216   R>       �          0    49170    collegamento 
   TABLE DATA           R   COPY public.collegamento (codfrase, pagina_frase, pagina_riferimento) FROM stdin;
    public          postgres    false    220   �?       �          0    41223    frase 
   TABLE DATA           <   COPY public.frase (codfrase, caratteri, pagina) FROM stdin;
    public          postgres    false    218   @       �          0    41235    modifica 
   TABLE DATA           �   COPY public.modifica (codmod, fraseoriginale, codfrase, pagina, frasemodificata, dataoramod, utente, autore, stato) FROM stdin;
    public          postgres    false    219   _E       �          0    98304    numero_di_modifiche_proposte 
   TABLE DATA           =   COPY public.numero_di_modifiche_proposte (count) FROM stdin;
    public          postgres    false    222   OI       �          0    41213    pagina 
   TABLE DATA           H   COPY public.pagina (link, titolo, dataoracreazione, autore) FROM stdin;
    public          postgres    false    217   nI       �          0    41191    utente 
   TABLE DATA           L   COPY public.utente (mail, nome, cognome, password, reputazione) FROM stdin;
    public          postgres    false    215   gJ       �           0    0    modifica_id_sequence    SEQUENCE SET     C   SELECT pg_catalog.setval('public.modifica_id_sequence', 68, true);
          public          postgres    false    221            H           2606    41202    autore autore_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.autore
    ADD CONSTRAINT autore_pkey PRIMARY KEY (nomedarte);
 <   ALTER TABLE ONLY public.autore DROP CONSTRAINT autore_pkey;
       public            postgres    false    216            L           2606    41229    frase frase_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT frase_pkey PRIMARY KEY (codfrase, pagina);
 :   ALTER TABLE ONLY public.frase DROP CONSTRAINT frase_pkey;
       public            postgres    false    218    218            N           2606    73732    modifica modifica_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.modifica
    ADD CONSTRAINT modifica_pkey PRIMARY KEY (codmod);
 @   ALTER TABLE ONLY public.modifica DROP CONSTRAINT modifica_pkey;
       public            postgres    false    219            J           2606    41217    pagina pagina_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT pagina_pkey PRIMARY KEY (link);
 <   ALTER TABLE ONLY public.pagina DROP CONSTRAINT pagina_pkey;
       public            postgres    false    217            F           2606    41197    utente utente_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.utente
    ADD CONSTRAINT utente_pkey PRIMARY KEY (mail);
 <   ALTER TABLE ONLY public.utente DROP CONSTRAINT utente_pkey;
       public            postgres    false    215            W           2620    81925 #   modifica aggiorna_caratteri_trigger    TRIGGER     �   CREATE TRIGGER aggiorna_caratteri_trigger AFTER INSERT ON public.modifica FOR EACH ROW EXECUTE FUNCTION public.aggiorna_caratteri_dopo_inserimento_modifica();
 <   DROP TRIGGER aggiorna_caratteri_trigger ON public.modifica;
       public          postgres    false    219    223            X           2620    49166     modifica aggiorna_pagina_trigger    TRIGGER     �   CREATE TRIGGER aggiorna_pagina_trigger AFTER UPDATE ON public.modifica FOR EACH ROW EXECUTE FUNCTION public.aggiorna_pagina_dopo_modifica_stato();
 9   DROP TRIGGER aggiorna_pagina_trigger ON public.modifica;
       public          postgres    false    219    224            Y           2620    98312    modifica tr_rep_aut    TRIGGER     t   CREATE TRIGGER tr_rep_aut AFTER INSERT OR UPDATE ON public.modifica FOR EACH ROW EXECUTE FUNCTION public.rep_aut();
 ,   DROP TRIGGER tr_rep_aut ON public.modifica;
       public          postgres    false    219    236            O           2606    41203    autore autore_utente_fkey    FK CONSTRAINT     z   ALTER TABLE ONLY public.autore
    ADD CONSTRAINT autore_utente_fkey FOREIGN KEY (utente) REFERENCES public.utente(mail);
 C   ALTER TABLE ONLY public.autore DROP CONSTRAINT autore_utente_fkey;
       public          postgres    false    4678    216    215            U           2606    49173 4   collegamento collegamento_codfrase_pagina_frase_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.collegamento
    ADD CONSTRAINT collegamento_codfrase_pagina_frase_fkey FOREIGN KEY (codfrase, pagina_frase) REFERENCES public.frase(codfrase, pagina);
 ^   ALTER TABLE ONLY public.collegamento DROP CONSTRAINT collegamento_codfrase_pagina_frase_fkey;
       public          postgres    false    218    218    4684    220    220            V           2606    49178 1   collegamento collegamento_pagina_riferimento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.collegamento
    ADD CONSTRAINT collegamento_pagina_riferimento_fkey FOREIGN KEY (pagina_riferimento) REFERENCES public.pagina(link);
 [   ALTER TABLE ONLY public.collegamento DROP CONSTRAINT collegamento_pagina_riferimento_fkey;
       public          postgres    false    217    220    4682            Q           2606    41230    frase frase_pagina_fkey    FK CONSTRAINT     x   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT frase_pagina_fkey FOREIGN KEY (pagina) REFERENCES public.pagina(link);
 A   ALTER TABLE ONLY public.frase DROP CONSTRAINT frase_pagina_fkey;
       public          postgres    false    217    218    4682            R           2606    41247    modifica modifica_autore_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.modifica
    ADD CONSTRAINT modifica_autore_fkey FOREIGN KEY (autore) REFERENCES public.autore(nomedarte);
 G   ALTER TABLE ONLY public.modifica DROP CONSTRAINT modifica_autore_fkey;
       public          postgres    false    216    219    4680            S           2606    41257 &   modifica modifica_codfrase_pagina_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.modifica
    ADD CONSTRAINT modifica_codfrase_pagina_fkey FOREIGN KEY (codfrase, pagina) REFERENCES public.frase(codfrase, pagina);
 P   ALTER TABLE ONLY public.modifica DROP CONSTRAINT modifica_codfrase_pagina_fkey;
       public          postgres    false    4684    219    219    218    218            T           2606    41242    modifica modifica_utente_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.modifica
    ADD CONSTRAINT modifica_utente_fkey FOREIGN KEY (utente) REFERENCES public.utente(mail);
 G   ALTER TABLE ONLY public.modifica DROP CONSTRAINT modifica_utente_fkey;
       public          postgres    false    219    215    4678            P           2606    41218    pagina pagina_autore_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT pagina_autore_fkey FOREIGN KEY (autore) REFERENCES public.autore(nomedarte);
 C   ALTER TABLE ONLY public.pagina DROP CONSTRAINT pagina_autore_fkey;
       public          postgres    false    216    217    4680            �   [  x�e�An� E�p�i�8H7��Q0D��qN_���U%��<�烛!3F�:�wB}�1��f�d��ti�a�3���US�)�"�N�t�tD�3��Ah-t�Vd�e���ă�|�\�[�в��^ЌD	b��.�o�r�x�v���ؓ��;�L�sT
�I���hߎm��xt9M��_lrgԺ媶E�}2c�]�3M�RZ��E���L��_ng*'�84��u�VlE&��0sk3�����bD��^��F��U��)ET}[�>K':�ؖ'�G���c�<���a���V�P��ג2mIp��G�X~��z����1���=0�Z�-�ق�ۯ��΁��%�$���F֬      �   F   x�3�,�����K����K�3AL.c��Ԣ�DGtq#��Ĝ�L�z�.΂���D�pAb^
������ T��      �   <  x�}V=oG�O�b;I C��lKqeX�!�v�8�(*�{�� w������I�.e�T�R�2���f�H���x�ܝ}3���To���q��'r�`1�<3}�.;+d��}v_���{��K���ͱ���dg��c#�Zу�����<^.���̮OoL��z�U�iz������ϫr���`QY}ɾA<n[2?q���s�zrB��~�;�#c%��?M�)hH���
)�]O������b{jv�:l�(0?�m�?d����j�vZ�𮦄�H����0���2�-�44>��u6)��z�%]�C)٘�kj �e`p��pQ{������eBָ@�q������*� ��D�qyRx��I�>��N��Z�q���6G���8&�x|%��83�'��w��ֲ��m�3#�*"���W���e��%�r��$%�G�Q*:]��N ����Upb6���yU��*�}0���3�#X�.�����'D���������Cp��B_kaE�7�z�P�',���
�6�����F�d[�hT��c/PKn�)s���!��js�ny_ŏ<A]ر�
\7��+�g3������M�U���6�9n�">��X16y��?�� �y�o~�z�C�\Ki]���8�.J5EW@{�Jk�9�^ܨ4P��b�έ�Z,Q�4kp�g5˱F��MƢ0(�؏��^ޘF�� �W�LL�EG����r�O�?�p�V��@o^p+�j7X
x�� �A�����u���c	
�x<Q�SH�:�Q [1kĭe^�GF.���j�td�n�'��8h�k�s�ݰ��h�U`XSћ���5Ӯ��<��D� �V�_"kK��
ݷ�j�]=JS�I�A֊K�u�et��B��&p��4#~=Qg�*l^W�����;Y<��>�/�����al��M� ��������
�*ʃ5��ŭ� ��諾P�C̵볛㹹�O3i�e��Q���������%Tx�>�j��C����4��j�6�1a� ���.?��뎞I����"�h��3��6Rà�_��^���L��"�Y��Fi���7�M��x�.��pd.��r��)����~�frO'A�����i�� �V���,I�:���a��3M��U˝����8� ;�A�/A���A���l����_�L������^wόo��C��R���/��'��cp/��u���0R|g呵��в�=(���*��w�m���ZԲ��W��Tq�щ
r��z�Ϫ78S~���EI�T�O`=����pQ~&)�:?88�Mh�b      �   �  x��V�n�6=3_A�e[ !(��d�6詗��Z�S饤 �/깿�?�Gɭ-َ,�!b�qf���HNh\������j��{���8�q{M3�`bc���V�ҹ5�|�����4:j=h�7T��/C��i����n�n����ԭ��̩����ES?��!ZM�"��>�hQ�Ѯ��5�%�Dp!�x�U�6u�Y�$iu�!���_�[m����A�}����=�����沖�B�g����|�@2rH���;sD�xF��Y�bY^q<��#pN�tԇj,�f��	����Ѻ5
;M[���&99h��.�W<�g����^D�gu�X��+*	�LL��A�@��7����G�SAҗ~���'�yD��%۠��W�ı��5�XJ�B"�����JL�G�s�W;G+�|5Ϙ������M���d��. �.�D�UL�a+pŕ��Xy-s&W�rI�����1�kǧ>��N�Ȁ�A�Qll 9fn&vz�ϣ�N$Mt񣧡mp��m�˩1�#ET��F,s�"���=��Tՙ`"/�-ȓM��)������H�O¥__M��=T���2�4��O*٘8v�T(�`�5�v���%���<ۢ�U���m��Sjc������� ��4OS_"�q�r�"�y�!Y������%,�Z����cB����ۭ=M���Ą`�Z���Z/��װO����5�6ō�r*��l��F2n���
�1�����O%~c>�x���`YyoVxL��!�/�6��G�G�o�ݗ����4�
�Xң[���B��G�OE��v���"p��&XQ�UV���DI��En�C��wD�����9x�i���M��9�}��ɰWvN�6����M���a\&7����8�:+��R�hV�aj��[��kgw��Q=Z&��7	�b��.�%�&�[��ᕣ�9��om�>���`��[��%\.�X��o����_���      �      x�3������ S �      �   �   x�e���� ���S���z+���ea���!+E0Zb�ۯ5��,x�~�?3�.)x>������;;��,(���ހ�f�ɧ�j�א�v��������׼�7(�����&O���uGv`ߎƭl���t(u�P���L�6]�e��<h�W��
�5>
�_#�*n��%@>��_����ɟ)�n#��B�i{���VSZV��S2L쭐{��,>�޶��vq�      �   �  x��WkSۼ����r-��ƹ����$��J(�Nf�,+��-�NHZ��ߕzr�3��}��e��]�.H�+&JX����)��u�1g�@�ޜLF�7��d�.yʹ,�.����Ⳙ���:��_{�8�o^�`�˘��	���x,ѽ�����O�6O��ڛƟ�p)*8�2���ƨ3ŵ&�5�W�v��~r��{L��3N9��*��-��N�"��E�}�c>�t�gѸm���I$g��5�G� ]	"h������_Ge޻�6n����'��=ϳ���3�kF�Em��3zƛ$NBD�ͥ��?c*��o�-�B�)�hZG�ܕ�;w[�d�k�f!�>ď$��āe���+�Z�'�ٷ'�Y�<��r�@*�!c��Q�/�V~e��M^?�3&�d�ɞ�\��T��͉�Pr����w���=��EJ�"ʊ�u<��F����e������49�r�IA10,k�1��ݾB(��?���hP:��R&�r�����q���]��R��z!ڭ����M~S����1���rh�0Mr���M�DmkE����)}x��R�D�DeS�p�1H�Q�C0)�h�Sx ���8�����Moʈ��0�&�{	{�V �F���Zս��f{9?؂�H@vB�1
�H�W�+�i�.pD���{ܻ�.��WvCO�, �I�ʊ��)Hy�bh�-M&�����D=�0�/�W�\Š�!�(����[�ڣy�3��a�Q�y��t���(ʛ�y��}�<p7!�61��<�L;�)�k �D'�ĸ��ޯ���ȣ�%�h+�6ZqB�%�bP��56?]G/6lDy9�b&p��0�.х)t��
Cq�q���ǭ�h����$�%�!H۱:���C:/P�O����q�xi�Nxq�b�2[�����jYEW���Mv��R��'�c�):a�N/�2����|����?����?J���\��e\a��@������"���n��|�2���0Έ3�*�^�!��leFӮ���9X��GO�S�S衰Xf�)���朘��@鸴Y	�����LR-E�}��r4��p�I
3z֏����~ԙTjEf|Z��/L����Т�����9�N�x��1�CC�P���f��L��Ӷ.��罫��\�Gb�e���1��*�����Cj�b倲V��OR8_��ڽ!�DC��B�	6SuVR_�8���!L��h���l���Τg����E���s����s:���2���[��2��ւG�Q9�Ư��t兖%�;�H��}�f;E�4b��g�\Jشm��Wv:���Y����O
�&�v��#�ϋ�.�T1�@�|�xJߒ�Fэr�A_p+��4WEk��4z�V}��������у�O�Xu�&*|:�,H�	�v�>�]� V��R��vkx�fh�<V݈(�M�@�nk�_��nQ�޶pa��S��E�E�E}w2i=�;/���J�c���p8S[�m�x���#5�|8��-��`)��,v1{&0W����<���߯U�C��f&���!�V'��� �ǵ���]����F+V��T٤v�f8ƌ���9ltg���۷��r�䮇y�őZP��L� ������{��K�>�T�Kq�%aE��l���)`D�{�G��y��tPT
��
��D������FZ��v'����lʧ�K,Ⱥ��r�>�*��#S�\�5��F���P��$[s��Ap\ N�[�Tk��F��ˠf�(7րz\���dJa��Re�ti,D\D ��h[�
�[���v���7{�fN3h�b�he{G�TJ_cd@��^?e0��zT�T����+�I�J�����Wor���k�$�$k�ğ���6��N��N�~Q����f����Bmͽ�T�j�V/����hԋ\��F�q���h��J�\IN�7�)zs��i~:0����]AyKxט'��A�ai#a[���k�&λw�����     