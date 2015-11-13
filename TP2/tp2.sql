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
as select num as id_client,
floor(months_between((sysdate, datenaiss)/12)) as age,
case 
when floor(months_between((sysdate, datenaiss)/12)) < 30 then '<30'
when floor(months_between((sysdate, datenaiss)/12)) < 45 then '30-44'
when floor(months_between((sysdate, datenaiss)/12)) < 60 then '45-59'
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
as select
facture.date_etabli as date_vente,
TO_CHAR(facture.date_etabli, 'mm') as num_mois,
TO_CHAR(facture.date_etabli, 'month') as mois,
TO_CHAR(facture.date_etabli, 'yyyy') as annee,
TO_CHAR(facture.date_etabli, 'ddd') as jour_annee,
TO_CHAR(facture.date_etabli, 'ww') as semaine_annee,
TO_CHAR(facture.date_etabli, 'dy') as lib_jour
from facture;
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
regexp_substr(client.adresse, '[^.]+', 1, 2) || '_' || regexp_substr(client.adresse, '[^.]+', 2, 3) as id_adresse,
prix_date.remise as remise,
ligne_facture.qte as qte,
prix_date.prix as prix_unit,
ligne_facture.qte * prix_date.prix as prix_vente
from ligne_facture
join facture on ligne_facture.facture = facture.num
join prix_date on ligne_facture.id_prix = prix_date.num
join client on facture.client = client.num;

insert into ligne_facture (facture, produit, qte, id_prix) values (3,5,10,5);
insert into ligne_facture (facture, produit, qte, id_prix) values (45,2,10,2);
insert into ligne_facture (facture, produit, qte, id_prix) values (80,11,12,11);



SELECT TO_CHAR(date_etabli, 'ww') as d
from FACTURE
;
select now();

