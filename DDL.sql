#### CREACION SCHEMA ####
CREATE SCHEMA `rockingdata` DEFAULT CHARACTER SET utf8mb4 COLLATE= utf8mb4_spanish_ci;
USE rockingdata;

#### SETTINGS ####
SELECT @@global.secure_file_priv;
SET GLOBAL local_infile=1;
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS=0;
SET SESSION group_concat_max_len = 10000;

#### TABLAS ####
## RAW DATA - tabla inicial
CREATE TABLE IF NOT EXISTS `rawdata`(
`IndexId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
`ShowId` VARCHAR(50) NOT NULL, 
`Type` VARCHAR(50),
`Title` VARCHAR(500),
`Director` INTEGER,
`Cast` INTEGER,
`Country` INTEGER,
`DateAdded` DATE,
`ReleaseYear` INTEGER,
`Rating` TEXT,
`Duration` INTEGER,
`ListedIn` INTEGER,
`Description` VARCHAR(500),
`Origin` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Tabla de hecho ##
# Shows
CREATE TABLE IF NOT EXISTS `shows`(
`ShowId` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT, 
`ShowIdFromOrigin` VARCHAR(10), 
`OriginID` INTEGER NOT NULL,
`TypeID` INTEGER NOT NULL,
`Title` TEXT,
`DirectorId` INTEGER,
`CastId` INTEGER,
`CountryId` INTEGER,
`DateAdded` DATE,
`ReleaseYear` INTEGER,
`RatingId` TEXT,
`Duration` INTEGER,
`ListedId` INTEGER,
`Description` TEXT
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Tablas dimensionales ##
# Origin ==> Almacena origen del dato - Si es un show listado en Netflix o Disney
DROP TABLE IF EXISTS `origin`;
CREATE TABLE IF NOT EXISTS `origin`(
`OriginId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

# Type ==> Pelicula o TV show
DROP TABLE IF EXISTS `type`;
CREATE TABLE IF NOT EXISTS `type`(
`TypeId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Rating ==> global - para Netflix y Disney
DROP TABLE IF EXISTS `rating`;
CREATE TABLE IF NOT EXISTS `rating`(
`RatingId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(100)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#### INSERTS ####
## Insertar tipos de show (TV/Movie) en tabla dimensional
INSERT INTO type (Name)
SELECT DISTINCT(TYPE) FROM RAWDATA;

## Insertar origen del show (Netflix/Disney) en tabla dimensional
INSERT INTO origin (Name)
SELECT DISTINCT(origin) FROM RAWDATA;

## Insertar lista con unique ratings global 
INSERT INTO rating (Name)
SELECT DISTINCT(rating) FROM RAWDATA;

## Insertar datos normalizados en tabla de hecho
INSERT INTO shows (ShowIdFromOrigin, OriginId, TypeID, Title, 
					DirectorId, CastId, CountryId, DateAdded, ReleaseYear, 
					RatingId, Duration, ListedId, Description)
SELECT ShowId, 
		CASE WHEN Origin = 'Disney' THEN 1 ELSE 2 END AS OriginCoded, 
        CASE WHEN type = 'Movie' THEN 1 ELSE 2 END AS TypeCoded, 
        Title, Director, Cast, Country, DateAdded, ReleaseYear, Rating, Duration, ListedIn, Description
FROM rawdata;

## Insertar datos de origen (Netflix/Disney) en tabla dimensional
INSERT INTO origin (Name)
SELECT DISTINCT(origin)
from rawdata;

#### UPDATES ####

## Tabla Shows
UPDATE `shows`
SET shows.RatingId = (SELECT rating.RatingId FROM rating WHERE shows.RatingId = rating.Name);

ALTER TABLE `shows` 
CHANGE COLUMN `RatingId` `RatingId` INT NULL DEFAULT NULL ;


#### DENORMALIZACION #####

##TABLA CAST
#a) Creamos la tabla
DROP TABLE IF EXISTS cast_ok; 
CREATE TABLE cast_ok (
  AllActors VARCHAR(255),
  CastId INT
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) Guardamos el primer resultado con todo los actores
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllCast, castid FROM cast WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'cast'
  AND column_name LIKE 'Cast_%';
  
#c) Y ejecutamos el siguiente statement para guardar todo en la tabla denormalizada
SET @query2 = CONCAT('INSERT INTO cast_ok (AllActors, CastId) SELECT AllCast, CastID FROM (', @query1, ') AS temp');
PREPARE stmt FROM @query2;
EXECUTE stmt;

#TABLA DIRECTORS
#a) Creamos la tabla denormalizada
DROP TABLE IF EXISTS director_ok; 
CREATE TABLE director_ok (
  AllDirectors VARCHAR(255),
  DirectorId INT
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) Guardamos el primer resultado con todo los directores
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllDirectors, DirectorId FROM director WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'director'
  AND column_name LIKE 'Director_%';
  
#c) Y ejecutamos el siguiente statement para guardar todo en la tabla denormalizada
SET @query2 = CONCAT('INSERT INTO director_ok (AllDirectors, DirectorId) SELECT AllDirectors, DirectorId FROM (', @query1, ') AS temp');
PREPARE stmt FROM @query2;
EXECUTE stmt;

#TABLA COUNTRY
#a) Creamos la tabla denormalizada
DROP TABLE IF EXISTS country_ok; 
CREATE TABLE country_ok (
  AllCountries VARCHAR(255),
  CountryId INT
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) Guardamos el primer resultado con todo los directores
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllCountries, CountryId FROM country WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'country'
  AND column_name LIKE 'Country_%';
  
#c) Y ejecutamos el siguiente statement para guardar todo en la tabla denormalizada
SET @query2 = CONCAT('INSERT INTO country_ok (AllCountries, CountryId) SELECT AllCountries, CountryId FROM (', @query1, ') AS temp');
PREPARE stmt FROM @query2;
EXECUTE stmt;


# TABLA LISTED 
#a) Creamos la tabla
DROP TABLE IF EXISTS listed_ok; 
CREATE TABLE listed_ok (
  AllListed VARCHAR(255),
  ListedId INT
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) Guardamos el primer resultado con todo los directores
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllListed, ListedId FROM listed WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'listed'
  AND column_name LIKE 'ListedIn_%';
  
#c) Y ejecutamos el siguiente statement para guardar todo en la tabla denormalizada
SET @query2 = CONCAT('INSERT INTO listed_ok (AllListed, ListedId) SELECT AllListed, ListedId FROM (', @query1, ') AS temp');
PREPARE stmt FROM @query2;
EXECUTE stmt;

#### RENAME TABLES ####
DROP TABLE `country`;
DROP TABLE `director`;
DROP TABLE `listed`;
DROP TABLE `cast`;

RENAME TABLE `country_ok` to `country`;
RENAME TABLE `cast_ok` to `cast`;
RENAME TABLE `director_ok` to `director`;
RENAME TABLE `listed_ok` to `listed`;

#### INDEXS ####
ALTER TABLE `shows` 
ADD INDEX `Date_Index` (`DateAdded` ASC);

ALTER TABLE `cast` 
ADD INDEX `Cast_Index` (`AllActors` ASC);

ALTER TABLE `director` 
ADD INDEX `Director_Index` (`AllDirectors` ASC);

ALTER TABLE `country` 
ADD INDEX `Country_Index` (`AllCountries` ASC);

ALTER TABLE `listed` 
ADD INDEX `Listed_Index` (`AllListed` ASC);

ALTER TABLE `cast` 
ADD INDEX `CastID_Index` (`CastId` ASC);

ALTER TABLE `director` 
ADD INDEX `DirectorID_Index` (`DirectorId` ASC);

ALTER TABLE `country` 
ADD INDEX `CountryID_Index` (`CountryId` ASC);

ALTER TABLE `listed` 
ADD INDEX `ListedID_Index` (`ListedId` ASC);

#### FOREING KEYS ####
ALTER TABLE `shows` 
ADD CONSTRAINT `OriginId`
  FOREIGN KEY (`OriginId`)
  REFERENCES `origin` (`OriginId`),
ADD CONSTRAINT `TypeID`
  FOREIGN KEY (`TypeID`)
  REFERENCES `type` (`TypeID`),
ADD CONSTRAINT `RatingId`
  FOREIGN KEY (`RatingId`)
  REFERENCES `rating` (`RatingId`),
ADD CONSTRAINT `DirectorId`
  FOREIGN KEY (`DirectorId`)
  REFERENCES `director` (`DirectorId`),
ADD CONSTRAINT `CastId`
  FOREIGN KEY (`CastId`)
  REFERENCES `cast` (`CastId`),
ADD CONSTRAINT `CountryId`
  FOREIGN KEY (`CountryId`)
  REFERENCES `country` (`CountryId`),
ADD CONSTRAINT `ListedId`
  FOREIGN KEY (`ListedId`)
  REFERENCES `listed` (`ListedId`);

#### DROP RAW DATA ####
DROP TABLE rawdata;


#### RESOLUCION DE QUERIES - PARTE 4  #####
#### 1) Considerando únicamente la plataforma de Netflix, ¿qué actor aparece más veces?
SELECT C.AllActors,COUNT(C.AllActors) AS Total
FROM cast AS C
LEFT JOIN shows AS S ON (C.CastId = S.CastId)
WHERE  S.OriginId = (SELECT OriginId FROM Origin WHERE Name = 'Netflix')
AND C.AllActors != 'None'
GROUP BY C.AllActors
ORDER BY 2 DESC
LIMIT 10;

### 2) Top 10 de actores participantes considerando ambas plataformas en el año actual
SELECT C.AllActors,COUNT(C.AllActors) as Total
FROM cast AS C
LEFT JOIN shows AS S ON (C.CastId = S.CastId)
WHERE YEAR(S.DateAdded) = 2021
AND C.AllActors != 'None'
GROUP BY C.AllActors
ORDER BY 2 DESC
LIMIT 10;

### 3) Crear un Stored Proceadure que tome como parámetro un año y devuelva una tabla con las 5 películas con mayor duración en minutos.
DROP PROCEDURE IF EXISTS TopFiveMovies;
DELIMITER $$
CREATE PROCEDURE TopFiveMovies (IN Release_Year INT)
BEGIN
  SELECT Title, Duration
  FROM shows 
  WHERE ReleaseYear = Release_Year
  AND TypeID = (SELECT TypeId FROM type WHERE Name ='Movie')
  ORDER BY Duration DESC
  LIMIT 5;
END $$
DELIMITER ;

# Llamo al procedure para año 2021
CALL TopFiveMovies(2021);
# Llamo al procedure para año 2020
CALL TopFiveMovies(2020);
# Llamo al procedure para año 2019
CALL TopFiveMovies(2019);


