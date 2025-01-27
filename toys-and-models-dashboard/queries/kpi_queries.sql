USE toys_and_models;


# KPI Ventes :

#Le nombre de produits vendus par catégorie et par mois, avec comparaison et taux de variation par rapport au même mois de l’année précédente.
WITH derniere_annee AS (
	SELECT MAX(EXTRACT(YEAR FROM orderDate)) AS annee_courante
    FROM orders
),
vente_avec_comparaison AS (
	SELECT EXTRACT(YEAR FROM ord.orderDATE) AS annee,
		   EXTRACT(MONTH FROM ord.orderDATE) AS mois,
		   p.productLine,
           SUM(ordD.quantityOrdered) AS total_produit_vendu,
           LAG(SUM(ordD.quantityOrdered), 1, 0) OVER(PARTITION BY p.productLine, EXTRACT(MONTH FROM ord.orderDATE) ORDER BY EXTRACT(YEAR FROM ord.orderDATE)) 
           AS vente_annee_precedente,
           ROUND((SUM(ordD.quantityOrdered) - LAG(SUM(ordD.quantityOrdered), 1, 0) OVER (
			PARTITION BY p.productLine, EXTRACT(MONTH FROM ord.orderDATE)
			ORDER BY EXTRACT(YEAR FROM ord.orderDATE)
			)) / LAG(SUM(ordD.quantityOrdered), 1, 0) OVER (
			PARTITION BY p.productLine, EXTRACT(MONTH FROM ord.orderDATE)
			ORDER BY EXTRACT(YEAR FROM ord.orderDATE)
			) * 100, 2
			) AS taux_variation
	FROM orders AS ord
	INNER JOIN orderdetails AS ordD ON ord.orderNumber = ordD.orderNumber
	INNER JOIN products AS p ON ordD.productCode = p.productCode
	INNER JOIN derniere_annee ON EXTRACT(YEAR FROM ord.orderDATE) IN (annee_courante, annee_courante-1)
	WHERE EXTRACT(YEAR FROM ord.orderDATE) IN (annee_courante, annee_courante-1)
	GROUP BY EXTRACT(YEAR FROM ord.orderDATE), EXTRACT(MONTH FROM ord.orderDATE), p.productLine
)
SELECT *
FROM vente_avec_comparaison
WHERE annee = (SELECT annee_courante
FROM derniere_annee);

# requete mis sur power bi pour les catégorie des produit
With cte1 AS
	(SELECT productLine, year(orderDate) AS annee, month(orderDate) AS mois, sum(od.quantityOrdered) AS quantite_produit,
	DATE_FORMAT(orderDate, "%Y%m") AS annee_mois,
	LAG(sum(od.quantityOrdered),1,0) OVER(PARTITION BY productLine, month(orderDate) ORDER BY year(orderDate)) AS previous_quantite
	FROM orderdetails AS od
	INNER JOIN orders AS o ON o.orderNumber = od.orderNumber
	INNER JOIN products AS p ON p.productCode = od.productCode
	GROUP BY productLine,year(orderDate), month(orderDate), DATE_FORMAT(orderDate, "%Y%m"))
SELECT productLine, annee, mois, quantite_produit, previous_quantite,(quantite_produit-previous_quantite)AS Comparaison,(quantite_produit-previous_quantite)/previous_quantite As variation
FROM cte1
ORDER BY annee desc, mois desc;



# requete mis sur power bi pour les produit
With cte1 AS
(SELECT productName, productLine, year(orderDate) AS annee, month(orderDate) AS mois, sum(od.quantityOrdered) AS quantite_produit,
DATE_FORMAT(orderDate, "%Y%m") AS annee_mois,
LAG(sum(od.quantityOrdered),1,0) OVER(PARTITION BY productName, month(orderDate) ORDER BY year(orderDate)) AS previous_quantite
FROM orderdetails AS od
INNER JOIN orders AS o ON o.orderNumber = od.orderNumber
INNER JOIN products AS p ON p.productCode = od.productCode
GROUP BY productName, productLine, year(orderDate), month(orderDate), DATE_FORMAT(orderDate, "%Y%m"))

SELECT productName, productLine, annee, mois, quantite_produit, previous_quantite,(quantite_produit-previous_quantite)AS Comparaison,(quantite_produit-previous_quantite)/previous_quantite As variation
FROM cte1
ORDER BY annee desc, mois desc;


# analyse produit et catégorie dans le temps
WITH cte1 AS (
    SELECT 
        p.productName, 
        p.productLine AS categorie,
        YEAR(o.orderDate) AS annee, 
        MONTH(o.orderDate) AS mois, 
        SUM(od.quantityOrdered) AS quantite_produit,
        -- Comparaison avec le même mois de l'année précédente
        LAG(SUM(od.quantityOrdered), 12, 0) OVER (
            PARTITION BY p.productName, p.productLine 
            ORDER BY YEAR(o.orderDate), MONTH(o.orderDate)
        ) AS previous_quantite
    FROM 
        orderdetails AS od
    INNER JOIN 
        orders AS o ON o.orderNumber = od.orderNumber
    INNER JOIN 
        products AS p ON p.productCode = od.productCode
    GROUP BY 
        p.productName, p.productLine, YEAR(o.orderDate), MONTH(o.orderDate)
)
SELECT 
    productName, 
    categorie, 
    annee, 
    mois, 
    quantite_produit, 
    previous_quantite, 
    (quantite_produit - previous_quantite) AS comparaison, 
    CASE 
        WHEN previous_quantite > 0 THEN (quantite_produit - previous_quantite) / previous_quantite
        ELSE NULL 
    END AS variation
FROM 
    cte1
ORDER BY 
    categorie, annee DESC, mois DESC;

# Top 10 des produits par catégorie
WITH cte1 AS (
    SELECT 
        p.productName, 
        p.productLine AS categorie,
        YEAR(o.orderDate) AS annee, 
        MONTH(o.orderDate) AS mois, 
        SUM(od.quantityOrdered) AS quantite_produit,
        -- Comparaison avec le même mois de l'année précédente
        LAG(SUM(od.quantityOrdered), 12, 0) OVER (
            PARTITION BY p.productName, p.productLine 
            ORDER BY YEAR(o.orderDate), MONTH(o.orderDate)
        ) AS previous_quantite
    FROM 
        orderdetails AS od
    INNER JOIN 
        orders AS o ON o.orderNumber = od.orderNumber
    INNER JOIN 
        products AS p ON p.productCode = od.productCode
    GROUP BY 
        p.productName, p.productLine, YEAR(o.orderDate), MONTH(o.orderDate)
),
cte_ranking AS (
    SELECT 
        productName, 
        categorie, 
        annee, 
        mois, 
        quantite_produit, 
        previous_quantite, 
        (quantite_produit - previous_quantite) AS comparaison, 
        CASE 
            WHEN previous_quantite > 0 THEN (quantite_produit - previous_quantite) / previous_quantite
            ELSE NULL 
        END AS variation,
        RANK() OVER (
            PARTITION BY categorie 
            ORDER BY quantite_produit DESC ) AS `rank`
    FROM 
        cte1
)
SELECT 
	`rank`,
    productName, 
    categorie, 
    annee, 
    mois, 
    quantite_produit, 
    previous_quantite, 
    comparaison, 
    variation
FROM 
    cte_ranking
WHERE 
    `rank` <= 10
ORDER BY 
    categorie, `rank`, annee DESC, mois DESC;

# ventes des differents bureaux


SELECT EXTRACT(YEAR FROM `or`.orderDate) AS annee,
       EXTRACT(MONTH FROM `or`.orderDate) AS mois,
	   o.officeCode, 
	   o.city, 
	   o.country, 
	   COUNT(ord.orderNumber) AS nombre_commandes,
       round(COUNT(ord.orderNumber) / 
       SUM(COUNT(ord.orderNumber)) OVER(PARTITION BY EXTRACT(YEAR FROM `or`.orderDate), EXTRACT(MONTH FROM `or`.orderDate)), 4) AS part_poucentage
FROM offices AS o
INNER JOIN employees AS e ON o.officeCode = e.officeCode
INNER JOIN customers AS c ON e.employeeNumber = c.salesRepEmployeeNumber
INNER JOIN orders AS `or` ON c.customerNumber = `or`.customerNumber
INNER JOIN orderdetails AS ord ON `or`.orderNumber = ord.orderNumber
WHERE `or`.status != 'Cancelled'
GROUP BY annee, mois, o.officeCode, o.city, o.country
ORDER BY o.officeCode, o.city, nombre_commandes DESC;


# ventes des differents bureaux par catégorie
SELECT 
	EXTRACT(YEAR FROM ord.orderDate) AS annee,
    EXTRACT(MONTH FROM ord.orderDate) AS mois,
    o.city AS `Bureau`,
    SUM(CASE WHEN p.productLine = 'Classic Cars' THEN od.quantityOrdered ELSE 0 END) AS `Classic Cars`,
    round(SUM(CASE WHEN p.productLine = 'Classic Cars' THEN od.quantityOrdered ELSE 0 END) / 
	SUM(od.quantityOrdered), 10) AS part_Classic_Cars,
    SUM(CASE WHEN p.productLine = 'Motorcycles' THEN od.quantityOrdered ELSE 0 END) AS `Motorcycles`,
    round(SUM(CASE WHEN p.productLine = 'Motorcycles' THEN od.quantityOrdered ELSE 0 END) / 
	SUM(od.quantityOrdered), 10) AS part_Motorcycles,
    SUM(CASE WHEN p.productLine = 'Planes' THEN od.quantityOrdered ELSE 0 END) AS `Planes`,
    round(SUM(CASE WHEN p.productLine = 'Planes' THEN od.quantityOrdered ELSE 0 END) / 
	SUM(od.quantityOrdered), 10) AS part_Planes,
    SUM(CASE WHEN p.productLine = 'Ships' THEN od.quantityOrdered ELSE 0 END) AS `Ships`,
    round(SUM(CASE WHEN p.productLine = 'Ships' THEN od.quantityOrdered ELSE 0 END) / 
	SUM(od.quantityOrdered), 10) AS part_Ships,
    SUM(CASE WHEN p.productLine = 'Trains' THEN od.quantityOrdered ELSE 0 END) AS `Trains`,
    round(SUM(CASE WHEN p.productLine = 'Trains' THEN od.quantityOrdered ELSE 0 END) / 
	SUM(od.quantityOrdered), 10) AS part_Trains,
    SUM(CASE WHEN p.productLine = 'Trucks and Buses' THEN od.quantityOrdered ELSE 0 END) AS `Trucks and Buses`,
    round(SUM(CASE WHEN p.productLine = 'Trucks and Buses' THEN od.quantityOrdered ELSE 0 END) / 
	SUM(od.quantityOrdered), 10) AS `part_Trucks and Buses`,
    SUM(CASE WHEN p.productLine = 'Vintage Cars' THEN od.quantityOrdered ELSE 0 END) AS `Vintage Cars`,
    round(SUM(CASE WHEN p.productLine = 'Vintage Cars' THEN od.quantityOrdered ELSE 0 END) / 
	SUM(od.quantityOrdered), 10) AS `part_Vintage Cars`,
    -- Nouvelle colonne pour le total par bureau
    SUM(od.quantityOrdered) AS `Total Produits`
FROM offices AS o
INNER JOIN employees AS e ON o.officeCode = e.officeCode
INNER JOIN customers AS c ON e.employeeNumber = c.salesRepEmployeeNumber
INNER JOIN orders AS ord ON c.customerNumber = ord.customerNumber
INNER JOIN orderdetails AS od ON ord.orderNumber = od.orderNumber
INNER JOIN products AS p ON od.productCode = p.productCode
WHERE ord.status != 'Cancelled' -- Exclure les commandes annulées
GROUP BY annee, mois, o.city
ORDER BY o.city;

# requete sur vendeur et client
-- Nombre total de clients (total, avec vendeurs et sans vendeurs)
SELECT
    customers.country AS `Pays_client`,
    COALESCE(offices.country, "NON AFFECTÉ") AS `Bureau`,
    COUNT(*) AS `Clients`,
    SUM(CASE WHEN salesRepEmployeeNumber IS NOT NULL THEN 1 ELSE 0 END) AS `Clients_avec_vendeurs`,
    SUM(CASE WHEN salesRepEmployeeNumber IS NULL THEN 1 ELSE 0 END) AS `Clients_sans_vendeurs`
FROM customers
LEFT JOIN employees ON employees.employeeNumber = customers.salesRepEmployeeNumber
LEFT JOIN offices ON offices.officeCode = employees.officeCode
GROUP BY `Pays_client`, `Bureau`
ORDER BY `Pays_client`;


# KPI Finances :

#Le chiffre d’affaires des commandes des deux derniers mois par pays.
WITH dernier_annee AS(
	SELECT MAX(EXTRACT(YEAR FROM orderDate)) AS dern_annee
    FROM orders
),
dernier_mois AS (
	SELECT MAX(EXTRACT(MONTH FROM orderDate)) AS dern_mois
    FROM orders
    WHERE EXTRACT(YEAR FROM orderDATE) = ( SELECT dern_annee
											   FROM dernier_annee)
)
SELECT  EXTRACT(YEAR FROM ord.orderDATE) AS annee,
		EXTRACT(MONTH FROM ord.orderDATE) AS mois,
		c.country,
		SUM(ordD.quantityOrdered * priceEach) AS CA
FROM orders AS ord
INNER JOIN orderdetails AS ordD ON ord.orderNumber = ordD.orderNumber
INNER JOIN customers AS c ON c.customerNumber = ord.customerNumber
INNER JOIN dernier_mois ON EXTRACT(MONTH FROM orderDATE) IN (dern_mois, dern_mois-1) 
WHERE EXTRACT(YEAR FROM ord.orderDate) = (
SELECT EXTRACT(YEAR FROM MAX(orderDate))
FROM orders
)
AND EXTRACT(MONTH FROM ord.orderDATE) IN (dern_mois, dern_mois-1)
GROUP BY annee, mois, c.country;

# CA  par produit, catégorie (achat, vente et bénéfice) dans le temps
SELECT  EXTRACT(YEAR FROM od.orderDATE) AS annee,
		EXTRACT(MONTH FROM od.orderDATE) AS mois,
		p.productName, 
		p.productLine, 
        sum(ord.quantityOrdered * p.buyPrice) AS achat,
        sum(ord.quantityOrdered * ord.priceEach) AS vente,
        sum(ord.quantityOrdered * ord.priceEach) - sum(ord.quantityOrdered * p.buyPrice) AS bénéfice,
        LAG(SUM(ord.quantityOrdered * ord.priceEach), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) AS vente_annee_precedente,
        LAG(SUM(ord.quantityOrdered * p.buyPrice), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) AS achat_annee_precedente,
        LAG(SUM(ord.quantityOrdered * ord.priceEach), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) -
        LAG(SUM(ord.quantityOrdered * p.buyPrice), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) AS bénéfice_annee_precedente
FROM orderdetails AS ord
INNER JOIN orders AS od ON ord.orderNumber = od.orderNumber
INNER JOIN products AS p ON ord.productCode = p.productCode
GROUP BY annee, mois, p.productCode, p.productLine;


#Analyse CA complète (pays, ville produit et catégorie) dans le temps
SELECT  
    EXTRACT(YEAR FROM od.orderDATE) AS annee,
    EXTRACT(MONTH FROM od.orderDATE) AS mois,
    o.country,
    o.city,
    p.productName,
    p.productLine,
    sum(ord.quantityOrdered * p.buyPrice) AS achat,
    sum(ord.quantityOrdered * ord.priceEach) AS vente,
    sum(ord.quantityOrdered * ord.priceEach) - sum(ord.quantityOrdered * p.buyPrice) AS bénéfice,
        LAG(SUM(ord.quantityOrdered * ord.priceEach), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) AS vente_annee_precedente,
    LAG(SUM(ord.quantityOrdered * p.buyPrice), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) AS achat_annee_precedente,
     LAG(SUM(ord.quantityOrdered * ord.priceEach), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) -
    LAG(SUM(ord.quantityOrdered * p.buyPrice), 12, 0) OVER (PARTITION BY p.productCode ORDER BY EXTRACT(YEAR FROM od.orderDATE), EXTRACT(MONTH FROM od.orderDATE)) AS bénéfice_annee_precedente
FROM orderdetails AS ord
INNER JOIN products AS p ON ord.productCode = p.productCode
INNER JOIN orders AS od ON ord.orderNumber = od.orderNumber
INNER JOIN customers AS c ON od.customerNumber = c.customerNumber
INNER JOIN employees AS e ON e.`employeeNumber` = c.salesRepEmployeeNumber
INNER JOIN offices AS o ON e.officeCode = o.officeCode
GROUP BY annee, mois, o.country, o.city, p.productName, p.productLine, p.productCode
ORDER BY bénéfice DESC;

# achat auprés des 5 plus gros fournisseur
SELECT  productVendor,
		SUM(ord.quantityOrdered) AS total_produit_vendu,
        SUM(p.quantityInStock) AS total_stock,
        SUM(ord.quantityOrdered) + SUM(p.quantityInStock) AS total_produit_stock_vente,
	    SUM(p.quantityInStock * p.buyPrice) AS valeur_stock_actuel_prix_fournisseur,
        SUM(ord.quantityOrdered * p.buyPrice) AS valeur_stock_vendu_prix_fournisseur,
        SUM(p.quantityInStock * p.buyPrice) + SUM(ord.quantityOrdered * p.buyPrice) AS total_achat_fournisseur
FROM products AS p
INNER JOIN orderdetails AS ord ON ord.productCode = p.productCode
INNER JOIN orders AS od ON ord.orderNumber = od.orderNumber
WHERE od.status != 'Cancelled'
GROUP BY productVendor
ORDER BY total_achat_fournisseur DESC
LIMIT 5;

# 5 client ayant apporter le plus de bénéfice
SELECT
    c.customerNumber AS customer_id,
    c.customerName AS customer_name,
    sum(ord.quantityOrdered * ord.priceEach) AS CA_cient_apporter,
    sum(ord.quantityOrdered * p.buyPrice) AS achat_produit_commander,
    sum(ord.quantityOrdered * ord.priceEach) - sum(ord.quantityOrdered * p.buyPrice) AS bénéfice_apporter
FROM customers c
inner JOIN orders o ON c.customerNumber = o.customerNumber
inner JOIN orderdetails ord ON o.orderNumber = ord.orderNumber
INNER JOIN products AS p ON ord.productCode = p.productCode
group by customer_id, customer_name
order by bénéfice_apporter DESC
LIMIT 5;

# clients ayant des dettes (bon)
WITH aggregated_payments AS (
    SELECT 
        customerNumber,
        SUM(amount) AS total_payment
    FROM payments
    GROUP BY customerNumber
)
SELECT
    c.customerNumber AS customer_id,
    c.customerName AS customer_name,
    c.creditLimit AS credit_limit,
    SUM(oc.priceEach * oc.quantityOrdered) AS total_achat, -- CA total
    COALESCE(ap.total_payment, 0) AS total_payment, -- Paiements agrégés
    SUM(oc.priceEach * oc.quantityOrdered) - COALESCE(ap.total_payment, 0) AS total_impaye -- Impayés calculés
FROM customers c
INNER JOIN orders o ON c.customerNumber = o.customerNumber
INNER JOIN orderdetails oc ON o.orderNumber = oc.orderNumber
LEFT JOIN aggregated_payments ap ON c.customerNumber = ap.customerNumber
GROUP BY c.customerNumber, c.customerName, c.creditLimit, ap.total_payment
HAVING total_impaye > 0 -- Filtrer uniquement les clients avec des dettes
ORDER BY total_impaye DESC;



# clients dans la base de données mais nayant jaimais fait de commande et jamais passer commande
# possibilité de prospecter ces clients
select c.customerNumber,
	   C.customerName,
	   c.contactFirstName,
       c.contactLastName,
       phone,
       o.orderDate
from customers AS c
left join payments AS p ON c.customerNumber = p.customerNumber
left join orders AS o ON c.customerNumber = o.customerNumber
where checkNumber is NULL;



# KPI Logistique :

#  Le stock des 5 produits les plus commandés
SELECT  
    EXTRACT(YEAR FROM od.orderDate) AS annee,
    EXTRACT(MONTH FROM od.orderDate) AS mois,
    p.productCode,
    p.productName, 
    productLine,
    p.quantityInStock, 
    SUM(ord.quantityOrdered) AS quantiteVendu,
    SUM(ord.quantityOrdered * ord.priceEach) AS CA_quantiteVendu,
    p.quantityInStock - SUM(ord.quantityOrdered) AS quantite_restant
FROM orderdetails AS ord
INNER JOIN products AS p ON ord.productCode = p.productCode
INNER JOIN orders AS od ON od.orderNumber = ord.orderNumber
GROUP BY 
    annee, 
    mois, 
    p.productCode, 
    p.productName, 
    p.quantityInStock
ORDER BY quantiteVendu DESC;


# temps de livraison
SELECT 
    ord.orderNumber,
    od.orderDate,
    od.shippedDate,
    DATEDIFF(od.shippedDate, od.orderDate) AS temps_livraison,
    AVG(DATEDIFF(od.shippedDate, od.orderDate)) OVER () AS delai_moyen,
    MAX(DATEDIFF(od.shippedDate, od.orderDate)) OVER () AS delai_max,
    MIN(DATEDIFF(od.shippedDate, od.orderDate)) OVER () AS delai_min,
    AVG(DATEDIFF(od.shippedDate, od.orderDate)) OVER (PARTITION BY EXTRACT(YEAR FROM od.orderDate), EXTRACT(MONTH FROM od.orderDate)) AS delai_moyen_par_mois
FROM orders AS od
INNER JOIN orderdetails AS ord ON od.orderNumber = ord.orderNumber
WHERE od.shippedDate IS NOT NULL
ORDER BY temps_livraison DESC;



#KPI Ressources humaines : 
  
# TOP 2 des meilleurs vendeurs dans le temps
WITH ventes_mensuelles AS (
    SELECT EXTRACT(YEAR FROM ord.orderDate) AS annee,
           EXTRACT(MONTH FROM ord.orderDate) AS mois,
           e.employeeNumber,
           CONCAT(e.lastName, " ", e.firstName) AS name,
           o.country AS pays,
           SUM(ordD.quantityOrdered * ordD.priceEach) AS chiffre_affaire_mensuel,
           SUM(SUM(ordD.quantityOrdered * ordD.priceEach)) OVER(PARTITION BY EXTRACT(YEAR FROM ord.orderDate), EXTRACT(MONTH FROM ord.orderDate)) AS CA_Total_Mensuel,
           LAG(SUM(ordD.quantityOrdered * ordD.priceEach), 12, 0) OVER (PARTITION BY e.employeeNumber ORDER BY EXTRACT(YEAR FROM ord.orderDate), EXTRACT(MONTH FROM ord.orderDate)) AS ca_annee_precedente
    FROM employees AS e
    INNER JOIN customers AS c ON e.employeeNumber = c.salesRepEmployeeNumber
    INNER JOIN orders AS ord ON c.customerNumber = ord.customerNumber
    INNER JOIN orderdetails AS ordD ON ord.orderNumber = ordD.orderNumber
    INNER JOIN offices AS o ON e.officeCode = o.officeCode
    GROUP BY e.employeeNumber, annee, mois, o.country
),
Clasement_vendeur AS (
    SELECT annee,
           mois,
           employeeNumber,
           name,
           pays,
           chiffre_affaire_mensuel,
           ca_annee_precedente,
           CA_Total_Mensuel,
           RANK() OVER(PARTITION BY annee, mois ORDER BY chiffre_affaire_mensuel DESC) AS rang
    FROM ventes_mensuelles
),
Top2_vendeur AS (
    SELECT annee,
           mois,
           rang,
           employeeNumber,
           name,
           pays,
           chiffre_affaire_mensuel,
           ca_annee_precedente,
           CA_Total_Mensuel
    FROM Clasement_vendeur
    WHERE rang <= 2
),
CA_Mensuel_Par_Pays AS (
    SELECT EXTRACT(YEAR FROM ord.orderDate) AS annee,
           EXTRACT(MONTH FROM ord.orderDate) AS mois,
           o.country AS pays,
           SUM(ordD.quantityOrdered * ordD.priceEach) AS CA_total_pays
    FROM orders AS ord
    INNER JOIN orderdetails AS ordD ON ord.orderNumber = ordD.orderNumber
    INNER JOIN customers AS c ON ord.customerNumber = c.customerNumber
    INNER JOIN employees AS e ON e.employeeNumber = c.salesRepEmployeeNumber
    INNER JOIN offices AS o ON o.officeCode = e.officeCode
    GROUP BY annee, mois, o.country
)
SELECT t.annee,
       CASE t.mois
           WHEN 1 THEN 'janvier'
           WHEN 2 THEN 'février'
           WHEN 3 THEN 'mars'
           WHEN 4 THEN 'avril'
           WHEN 5 THEN 'mai'
           WHEN 6 THEN 'juin'
           WHEN 7 THEN 'juillet'
           WHEN 8 THEN 'août'
           WHEN 9 THEN 'septembre'
           WHEN 10 THEN 'octobre'
           WHEN 11 THEN 'novembre'
           ELSE 'décembre'
       END AS mois,
       t.rang,
       t.employeeNumber,
       t.name,
       t.pays,
       t.chiffre_affaire_mensuel,
       ca_annee_precedente,
       ROUND(t.chiffre_affaire_mensuel / ctp.CA_total_pays, 2) AS percent_CA_Employe_pays,
       t.CA_Total_Mensuel,
       ROUND(t.chiffre_affaire_mensuel / t.CA_Total_Mensuel, 2) AS percent_CA_Employe_total
FROM Top2_vendeur AS t
INNER JOIN CA_Mensuel_Par_Pays AS ctp ON t.annee = ctp.annee AND t.mois = ctp.mois AND t.pays = ctp.pays
ORDER BY t.annee DESC, t.mois, t.rang;


# requête pour tableau recapitulatif employés

select  EXTRACT(YEAR FROM od.orderDate) AS annee,
	    EXTRACT(MONTH FROM od.orderDate) AS mois,
		CONCAT(e.lastName, " ", e.firstName) AS name,
		o.city,
        o.country,
        count(c.customerNumber) AS nombre_client,
        sum(ord.quantityOrdered * priceEach) AS CA_par_pays,
        SUM(ord.quantityOrdered * ord.priceEach) / SUM(SUM(ord.quantityOrdered * ord.priceEach)) OVER (PARTITION BY o.city) AS part_repartition_pays,
		SUM(ord.quantityOrdered * ord.priceEach) / SUM(SUM(ord.quantityOrdered * ord.priceEach)) OVER () AS part_repartition_global,
        count(ord.orderNumber) AS total_commande,
        SUM(ord.quantityOrdered * ord.priceEach) / COUNT(ord.orderNumber) AS CA_par_commande,
        count(e.employeeNumber) AS total_employee,
        count(distinct e.employeeNumber) AS total_employee_distinct
from employees as e
INNER JOIN offices AS o ON e.officeCode = o.officeCode
INNER JOIN customers AS c ON e.employeeNumber = c.salesRepEmployeeNumber
INNER JOIN orders AS od ON c.customerNumber = od.customerNumber
INNER JOIN orderdetails AS ord ON ord.orderNumber = od.orderNumber
group by annee, mois, name, o.city, o.country;

# répartion des employés par poste
SELECT  CONCAT(lastName, " ", firstName) AS name,
		jobTitle,
        SUM(CASE WHEN jobTitle =  "President" THEN 1 ELSE 0 END) AS president,
        SUM(CASE WHEN jobTitle =  "VP Sales" THEN 1 ELSE 0 END) AS `VP Sales`,
        SUM(CASE WHEN jobTitle =  "VP Marketing" THEN 1 ELSE 0 END) AS `VP Marketing`,
        SUM(CASE WHEN jobTitle =  "Sales Manager (APAC)" THEN 1 ELSE 0 END) AS `Sales Manager (APAC)`,
        SUM(CASE WHEN jobTitle =  "Sale Manager (EMEA)" THEN 1 ELSE 0 END) AS `Sale Manager (EMEA)`,
        SUM(CASE WHEN jobTitle =  "Sales Manager (NA)" THEN 1 ELSE 0 END) AS `Sales Manager (NA)`,
        SUM(CASE WHEN jobTitle =  "Sales Rep" THEN 1 ELSE 0 END) AS `Sales Rep`,
        COUNT(employeeNumber) AS count_employee
FROM employees
GROUP BY jobTitle, name;