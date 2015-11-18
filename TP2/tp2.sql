DROP materialized VIEW log on client;
DROP materialized VIEW log on facture;
DROP materialized VIEW log on produit;
DROP materialized VIEW log on ligne_facture;


DROP materialized VIEW fait_vente;
DROP materialized VIEW produit_dim;
DROP materialized VIEW lieu_dim;
DROP materialized VIEW client_dim;
DROP materialized VIEW temps_dim;

-- pour créer une vue materialisee avec la clause "refresh fast",
-- il faut d'abord créer un log sur la table de base

--
-- Dimension produit
--

create materialized view log on produit;

create materialized view produit_dim
refresh fast on commit
as select num as id_prod,
regexp_substr(designation, '[^.]', 1, 1) as nom,
regexp_substr(designation, '[^.]', 1, 2) as categorie,
regexp_substr(designation, '[^.]', 1, 3) as souscategorie
from produit;
-- drop materialized view produit_dim


--
-- Dimension client
--

create materialized view log on client;

create materialized view client_dim
refresh force on demand
as select unique num as id_client,
floor(months_between(sysdate, date_nais)/12) as age,
case 
when floor(months_between(sysdate, date_nais)/12) < 30 then '<30'
when floor(months_between(sysdate, date_nais)/12) < 45 then '30-44'
when floor(months_between(sysdate, date_nais)/12) < 60 then '45-59'
else '>=60'
end as tranche_age,
upper(substr(sexe, 1, 1)) as sexe
from client;

execute dbms_mview.refresh('CLIENT_DIM');

--
-- Dimension temps
--

create materialized view log on facture;

create materialized view temps_dim
refresh force on demand
as select unique
facture.date_etabli as date_vente,
TO_CHAR(facture.date_etabli, 'mm') as num_mois,
TO_CHAR(facture.date_etabli, 'month') as mois,
TO_CHAR(facture.date_etabli, 'yyyy') as annee,
TO_CHAR(facture.date_etabli, 'ddd') as jour_annee,
TO_CHAR(facture.date_etabli, 'ww') as semaine_annee,
TO_CHAR(facture.date_etabli, 'dy') as lib_jour
from facture;

--
-- Dimension lieu
--

create materialized view lieu_dim
refresh force on demand
as select unique
     regexp_substr(client.adresse, '[^,]+', 1, 2) || '_' || regexp_substr(client.adresse, '[^,]+', 1, 3) as id_adresse,
     regexp_substr(adresse,'[^,]+',1,2) AS zip_code,
     regexp_substr(adresse,'[^,]+',1,3) AS ville,
     regexp_substr(adresse,'[^,]+',1,4) AS pays 
from client;


--
-- Fait
--

create materialized view log on ligne_facture;

create materialized view fait_vente
refresh force on demand
as select 
ligne_facture.facture as id_facture,
facture.date_etabli as date_vente,
ligne_facture.produit as id_produit,
facture.client as id_client,
regexp_substr(client.adresse, '[^,]+', 1, 2) || '_' || regexp_substr(client.adresse, '[^,]+', 1, 3) as id_adresse,
prix_date.remise as remise,
ligne_facture.qte as qte,
prix_date.prix as prix_unit,
ligne_facture.qte * prix_date.prix as prix_vente
from ligne_facture
join facture on ligne_facture.facture = facture.num
join prix_date on ligne_facture.id_prix = prix_date.num
join client on facture.client = client.num;

-- Question implementations

-- 1
alter materialized view temps_dim
add constraint  pk_dim_temps primary key (date_vente);

--DEMANDER PROF POURQUOI PAS BESOIN ! POURQUOIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII ?!
--alter materialized view produit_dim
--add constraint  pk_dim_produit primary key (id_prod);

alter materialized view client_dim
add constraint  pk_dim_client primary key (id_client);

alter materialized view lieu_dim
add constraint  pk_dim_lieu primary key (id_adresse);

-- 2

alter materialized view fait_vente
add (
     constraint pk_fait_vente primary key (id_facture, date_vente, id_produit, id_adresse), 
     constraint fk_fait_vente_date foreign key (date_vente) references temps_dim (date_vente),
     constraint fk_fait_vente_prod foreign key (id_produit) references produit_dim (id_prod),
     constraint fk_fait_vente_client foreign key (id_client) references client_dim (id_client),
     constraint fk_fait_vente_lieu foreign key (id_adresse) references lieu_dim (id_adresse)
     );

-- 3
--insert into ligne_facture (facture, produit, qte, id_prix) values (3,61,61,5);
--insert into ligne_facture (facture, produit, qte, id_prix) values (45,20,10,2);
--insert into ligne_facture (facture, produit, qte, id_prix) values (80,15,12,11);

select * 
from fait_vente 
where 
id_facture = 3 
or
id_facture = 45 
or
id_facture = 80;

--On a bien les produits 61, 20 et 80.


