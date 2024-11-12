DROP DATABASE IF EXISTS `db2_projet_long`;
CREATE DATABASE `db2_projet_long`;
USE `db2_projet_long`;

/*

    types

*/

CREATE TABLE `croute`(
    `id`    INTEGER PRIMARY KEY AUTO_INCREMENT,
    `nom`   VARCHAR(32)
);
CREATE TABLE `sauce`(
    `id`    INTEGER PRIMARY KEY AUTO_INCREMENT,
    `nom`   VARCHAR(32)
);
CREATE TABLE `garniture`(
    `id`    INTEGER PRIMARY KEY AUTO_INCREMENT,
    `nom`   VARCHAR(32)
);

/*

    AUTO

*/

CREATE TABLE `client`(
    `id` INTEGER PRIMARY KEY AUTO_INCREMENT,
    `nom` VARCHAR(64),
    `adresse` VARCHAR(255),
    `telephone` VARCHAR(32)
);


CREATE TABLE `commande`(
    `id` INTEGER PRIMARY KEY AUTO_INCREMENT,
    `client_id` INTEGER REFERENCES client(id)
);


CREATE TABLE `pizza`(
    `id` INTEGER PRIMARY KEY AUTO_INCREMENT,
    `commande_id` INTEGER REFERENCES commande(id),
    `croute_id` INTEGER REFERENCES croute(id),
    `sauce_id` INTEGER REFERENCES sauce(id)
);


CREATE TABLE `commande_en_attente`(
    `id` INTEGER PRIMARY KEY AUTO_INCREMENT,
    `commande_id` INTEGER REFERENCES commande(id)
);

/*

    liens

*/


CREATE TABLE `pizza_garniture`(
    `id` INTEGER PRIMARY KEY AUTO_INCREMENT,
    `pizza_id` INTEGER REFERENCES pizza(id),
    `garniture_id` INTEGER REFERENCES garniture(id)
);

/*

    inserts

*/

INSERT INTO `croute` (nom) VALUES ("Classique");
INSERT INTO `croute` (nom) VALUES ("Mince");
INSERT INTO `croute` (nom) VALUES ("Épaisse");

INSERT INTO `sauce` (nom) VALUES ("Tomate");
INSERT INTO `sauce` (nom) VALUES ("Spaghetti");
INSERT INTO `sauce` (nom) VALUES ("Alfredo");

INSERT INTO `garniture` (nom) VALUES ("Aucune");
INSERT INTO `garniture` (nom) VALUES ("Pepperonis");
INSERT INTO `garniture` (nom) VALUES ("Champignons");
INSERT INTO `garniture` (nom) VALUES ("Oignons");
INSERT INTO `garniture` (nom) VALUES ("Poivrons");
INSERT INTO `garniture` (nom) VALUES ("Olives");
INSERT INTO `garniture` (nom) VALUES ("Anchois");
INSERT INTO `garniture` (nom) VALUES ("Bacon");
INSERT INTO `garniture` (nom) VALUES ("Poulet");
INSERT INTO `garniture` (nom) VALUES ("Maïs");
INSERT INTO `garniture` (nom) VALUES ("Fromage");
INSERT INTO `garniture` (nom) VALUES ("Piments forts");


/*

    triggers

*/
DELIMITER $$

CREATE TRIGGER max_4_garnitures AFTER INSERT ON pizza_garniture FOR EACH ROW
    BEGIN
        DECLARE nb INTEGER;
        SET nb = (SELECT count(id) FROM pizza_garniture WHERE pizza_id = NEW.pizza_id );
        IF (nb = 5) THEN 
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = "Il y a trop de garnitures.";
        END IF;
    END $$

CREATE TRIGGER en_attente AFTER INSERT ON commande FOR EACH ROW
    BEGIN
        INSERT INTO commande_en_attente (commande_id) VALUES (NEW.id);
    END $$

CREATE PROCEDURE ajout_commande(
    IN _croute VARCHAR(32),
    IN _sauce VARCHAR(32), 
    IN _garniture1 VARCHAR(32),
    IN _garniture2 VARCHAR(32),
    IN _garniture3 VARCHAR(32),
    IN _garniture4 VARCHAR(32),
    IN _nom VARCHAR(64),
    IN _adresse VARCHAR(255),
    IN _telephone VARCHAR(32)
)
BEGIN
    DECLARE _client INTEGER;

    START TRANSACTION;
    
    SET _client = (SELECT count(id) FROM client WHERE client.adresse = _adresse AND client.nom = _nom AND client.telephone = _telephone);

    IF (_client = 0) THEN
        INSERT INTO client (nom, adresse, telephone) VALUES (_nom, _adresse, _telephone);
    END IF;

    SET _client = LAST_INSERT_ID();
    INSERT INTO commande (client_id) VALUES (_client);

    SET _client = LAST_INSERT_ID();
    INSERT INTO pizza (commande_id, sauce_id, croute_id) VALUES (_client, _sauce, _croute);

    SET _client = LAST_INSERT_ID();
    INSERT INTO pizza_garniture (pizza_id, garniture_id) VALUES (_client, _garniture1);
    INSERT INTO pizza_garniture (pizza_id, garniture_id) VALUES (_client, _garniture2);
    INSERT INTO pizza_garniture (pizza_id, garniture_id) VALUES (_client, _garniture3);
    INSERT INTO pizza_garniture (pizza_id, garniture_id) VALUES (_client, _garniture4);

    COMMIT;
END $$