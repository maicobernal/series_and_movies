## Creación de schema
CREATE SCHEMA `rockingdata` DEFAULT CHARACTER SET utf8mb4 COLLATE= utf8mb4_spanish_ci;
USE rockingdata;

## Settings
SELECT @@global.secure_file_priv;
SET GLOBAL local_infile=1;

## Tabla inicial donde volcar datos sin procesar
CREATE TABLE IF NOT EXISTS `rawdata`(e
`IndexId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
`ShowId` VARCHAR(50) NOT NULL, 
`Type` VARCHAR(50),
`Title` VARCHAR(500),
`Director` TEXT,
`Cast` TEXT,
`Country` TEXT,
`DateAdded` DATE,
`ReleaseYear` INTEGER,
`Rating` TEXT,
`Duration` INTEGER,
`ListedIn` TEXT,
`Description` VARCHAR(500),
`Origin` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Tabla de hecho - AllShows
CREATE TABLE IF NOT EXISTS `allshows`(
`ShowId` INTEGER NOT NULL, 
`ShowIdFromOrigin` VARCHAR(10), 
`OriginID` INTEGER NOT NULL,
`TypeID` INTEGER NOT NULL
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Tabla "dimensional" Movie
CREATE TABLE IF NOT EXISTS `movie`(
`MovieId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`ShowId` INTEGER NOT NULL, 
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

## Tabla "dimensional" TV
CREATE TABLE IF NOT EXISTS `tv`(
`TVId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`ShowId` INTEGER NOT NULL, 
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

## Tabla dimensional Origin
# Almacena origen del dato - Si es un show listado en Netflix o Disney
DROP TABLE `origin`;
CREATE TABLE IF NOT EXISTS `origin`(
`OriginId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Tabla dimensional para tipo de show: Pelicula o TV show
DROP TABLE `type`;
CREATE TABLE IF NOT EXISTS `type`(
`TypeId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Tabla dimensional con valores unicos de rating - global - para Netflix y Disney
CREATE TABLE IF NOT EXISTS `rating`(
`RatingId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(100)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Insertar tipos de show (TV/Movie) en tabla dimensional
INSERT INTO type (Name)
SELECT DISTINCT(TYPE) FROM RAWDATA;

## Insertar origen del show (Netflix/Disney) en tabla dimensional
INSERT INTO origin (Name)
SELECT DISTINCT(origin) FROM RAWDATA;

## Insertar lista con unique ratings global 
INSERT INTO rating (Name)
SELECT DISTINCT(rating) FROM RAWDATA;


## Insertar datos desnormalizados en tabla de hecho
INSERT INTO allshows (ShowId, ShowIdFromOrigin, OriginId, TypeID)
SELECT IndexId, ShowId, CASE WHEN Origin = 'Disney' THEN 1 ELSE 2 END AS origin_coded, CASE WHEN type = 'Movie' THEN 1 ELSE 2 END AS type_coded
from rawdata;

## Insertar datos de origen (Netflix/Disney) en tabla dimensional
INSERT INTO origin (Name)
SELECT DISTINCT(origin)
from rawdata;

SET SQL_SAFE_UPDATES = 0;
## Tabla movies
INSERT INTO movie (ShowId, Title, DirectorId, CastId,CountryId, DateAdded, ReleaseYear, RatingId, Duration, ListedId, Description)
SELECT IndexId, Title, IndexId,IndexId,IndexId,DateAdded,ReleaseYear,Rating,Duration,IndexId,Description 
from rawdata 
where type = 'Movie';

UPDATE movie
SET movie.RatingId = (SELECT rating.RatingId FROM rating WHERE movie.RatingId = rating.Name);

## Tabla TV shows
INSERT INTO tv (ShowId, Title, DirectorId, CastId,CountryId, DateAdded, ReleaseYear, RatingId, Duration, ListedId, Description)
SELECT IndexId, Title, IndexId,IndexId,IndexId,DateAdded,ReleaseYear,Rating,Duration,IndexId,Description 
from rawdata 
where type = 'TV Show';

## Update rating con ID's de tabla dimensional
UPDATE tv
SET tv.RatingId = (SELECT rating.RatingId FROM rating WHERE tv.RatingId = rating.Name);


## Creacion y carga de tabla dimensional director
DROP TABLE `director`;
CREATE TABLE IF NOT EXISTS `director`(
`DirectorId` INTEGER NOT NULL PRIMARY KEY, 
`FullNames` TEXT
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

INSERT INTO director (DirectorId, FullNames)
SELECT IndexId, Director
from rawdata;

## Creacion y carga de tabla dimensional cast
DROP TABLE `cast`;
CREATE TABLE IF NOT EXISTS `cast`(
`CastId` INTEGER NOT NULL PRIMARY KEY, 
`FullNames` TEXT
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

INSERT INTO cast (CastId, FullNames)
SELECT IndexId, Cast
from rawdata;

## Creacion y carga de tabla dimensional country
DROP TABLE `country`;
CREATE TABLE IF NOT EXISTS `country`(
`CountryId` INTEGER NOT NULL PRIMARY KEY, 
`FullNames` TEXT
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

INSERT INTO country (CountryId, FullNames)
SELECT IndexId, Country
from rawdata;

## Creacion y carga de tabla dimensional category (Listed_In en CSV original)
DROP TABLE `category`;
CREATE TABLE IF NOT EXISTS `category`(
`CategoryId` INTEGER NOT NULL PRIMARY KEY, 
`FullNames` TEXT
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

INSERT INTO category (CategoryId, FullNames)
SELECT IndexId,ListedIn
from rawdata;


## Setteo de PK y indexs 
ALTER TABLE `rockingdata`.`allshows` 
ADD PRIMARY KEY (`ShowID`),
ADD UNIQUE INDEX `ShowID_UNIQUE` (`ShowID` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`category` 
#Already setted PK
ADD UNIQUE INDEX `CategoryId_UNIQUE` (`CategoryId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`country`
#Already setted PK
ADD UNIQUE INDEX `CountryId_UNIQUE` (`CountryId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`director`
#Already setted PK
ADD UNIQUE INDEX `DirectorId_UNIQUE` (`DirectorId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`cast`
#Already setted PK
ADD UNIQUE INDEX `CastId_UNIQUE` (`CastId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`origin`
#Already setted PK
ADD UNIQUE INDEX `OriginId_UNIQUE` (`OriginId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`rating`
#Already setted PK
ADD UNIQUE INDEX `RatingId_UNIQUE` (`RatingId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`type`
#Already setted PK
ADD UNIQUE INDEX `TypeId_UNIQUE` (`TypeId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`movie`
#Already setted PK
ADD UNIQUE INDEX `MovieId_UNIQUE` (`MovieId` ASC) VISIBLE;

ALTER TABLE `rockingdata`.`tv`
#Already setted PK
ADD UNIQUE INDEX `TVId_UNIQUE` (`TVId` ASC) VISIBLE;

## Setteo de foreing keys
SET FOREIGN_KEY_CHECKS=0;

ALTER TABLE `rockingdata`.`allshows` 
ADD INDEX `ShowId_idx` (`ShowId` ASC) VISIBLE,
ADD INDEX `ShowIdFromOrigin_idx` (`ShowIdFromOrigin` ASC) VISIBLE,
ADD INDEX `OriginId_idx` (`OriginId` ASC) VISIBLE
;

ALTER TABLE `rockingdata`.`allshows` 
ADD CONSTRAINT `OriginId`
  FOREIGN KEY (`OriginId`)
  REFERENCES `rockingdata`.`origin` (`OriginId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
ADD CONSTRAINT `TypeID`
  FOREIGN KEY (`TypeID`)
  REFERENCES `rockingdata`.`type` (`TypeID`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `rockingdata`.`movie` 
CHANGE COLUMN `RatingId` `RatingId` INT,
ADD CONSTRAINT `ShowId`
  FOREIGN KEY (`ShowId`)
  REFERENCES `rockingdata`.`allshows` (`ShowId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
ADD CONSTRAINT `RatingId`
  FOREIGN KEY (`RatingId`)
  REFERENCES `rockingdata`.`rating` (`RatingId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
ALTER TABLE `rockingdata`.`tv` 
CHANGE COLUMN `ShowId` `ShowIdAll` INTEGER NOT NULL,
CHANGE COLUMN `RatingId` `RatingIdAll` INTEGER,
ADD CONSTRAINT `ShowIdAll`
  FOREIGN KEY (`ShowIdAll`)
  REFERENCES `rockingdata`.`allshows` (`ShowId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
ADD CONSTRAINT `RatingIdAll`
  FOREIGN KEY (`RatingIdAll`)
  REFERENCES `rockingdata`.`rating` (`RatingId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
ALTER TABLE `rockingdata`.`director` 
ADD CONSTRAINT `DirectorId`
  FOREIGN KEY (`DirectorId`)
  REFERENCES `rockingdata`.`allshows` (`ShowId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `rockingdata`.`cast` 
ADD CONSTRAINT `CastId`
  FOREIGN KEY (`CastId`)
  REFERENCES `rockingdata`.`allshows` (`ShowId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
ALTER TABLE `rockingdata`.`country` 
ADD CONSTRAINT `CountryId`
  FOREIGN KEY (`CountryId`)
  REFERENCES `rockingdata`.`allshows` (`ShowId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE `rockingdata`.`category` 
ADD CONSTRAINT `CategoryId`
  FOREIGN KEY (`CategoryId`)
  REFERENCES `rockingdata`.`allshows` (`ShowId`)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

#### RESOLUCION DE QUERIES - PARTE 4  #####

#### 1) Considerando únicamente la plataforma de Netflix, ¿qué actor aparece más veces?
# La forma más eficiente de hacer queries en una lista de strings separados por coma que encontré es
# usando recursives CTE (al menos en MySQL 8.0).

WITH RECURSIVE
#CTE que filtra solo shows de Netflix
netflix_cast as (
select fullnames
from cast
where castid in (select showid 
				from allshows 
				where originid = (select originid 
								from origin where name = 'Netflix'))),
# Recursive CTE y split de strings separados por comas
DATA as (SELECT CONCAT(netflix_cast.fullnames, ',') REST from netflix_cast),

WORDS_listedin as (
        SELECT SUBSTRING(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from data
        union all
        select substring(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from WORDS_listedin
        where locate(',', rest) > 0
)
select distinct word as actors_netflix, count(word) as n_appearence from WORDS_listedin
group by actors_netflix
order by n_appearence desc
LIMIT 1;

### 2) Top 10 de actores participantes considerando ambas plataformas en el año actual
#Interpreto que con flexibilidad se refieren a la posibilidad de que el query busque automaticamente el ultimo año en el dataset 

WITH RECURSIVE 
#CTE no recursivo que busca ultimo año en database
#Tanto para movies como TV shows
last_year as(
select year(max(dateadded)) as max
				from movie
				union
				select year(max(dateadded)) as s
				from tv
			),
#CTE no recursivo que busca lista de nombres
#tanto para TV como movies
last_year_names as(
select fullnames
from cast
where castid in (select showid
				from allshows
				where showid in (select showid 
								from tv 
                                where year(dateadded) = (select max(max)
														from last_year)
				and showid in (select showid 
								from movie 
								where year(dateadded) = (select max(max)
														from last_year))))
				),
#Recursive CTE
DATA as (
SELECT CONCAT(last_year_names.fullnames, ',') REST 
from last_year_names
		),
 WORDS_listedin as (
	SELECT SUBSTRING(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
	from data
	union all
	select substring(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
	from WORDS_listedin
	where locate(',', rest) > 0
					)
select distinct word as actors, count(word) as n_appearence from WORDS_listedin
group by actors
order by n_appearence desc
LIMIT 10;


### 3) Crear un Stored Proceadure que tome como parámetro un año y devuelva una tabla con las 5 películas con mayor duración en minutos.
DELIMITER $$
CREATE PROCEDURE top_five_movies_by_duration (IN release_year INT)
BEGIN
  SELECT title, duration
  FROM movie 
  WHERE releaseyear = release_year
  ORDER BY duration DESC
  LIMIT 5;
END $$
DELIMITER ;

# Llamo al procedure para año 2020
CALL top_five_movies_by_duration(2020);
# Llamo al procedure para año 2019
CALL top_five_movies_by_duration(2019);






### Otras cosas no utilizadas (por ahora)
## Obtener lista de personas unicas (tanto directores como cast)
# Ya vimos que hay superposición de ambas en Python
INSERT INTO people (Name)
with X as (
WITH RECURSIVE 
    DATA as (SELECT CONCAT(director, ',') REST from rawdata),
     WORDS_director as (
        SELECT SUBSTRING(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from data
        union all
        select substring(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from WORDS_director
        where locate(',', rest) > 0
)
select distinct word from WORDS_director  order by word
),
Y as (
WITH RECURSIVE 
    DATA as (SELECT CONCAT(cast, ',') REST from rawdata),
     WORDS_cast as (
        SELECT SUBSTRING(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from data
        union all
        select substring(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from WORDS_cast
        where locate(',', rest) > 0
)
select distinct word from WORDS_cast  order by word
)
SELECT * from X
union
select * from y;

## Obtener lista de paises unicos
INSERT INTO country (Name)
with X as (
WITH RECURSIVE 
    DATA as (SELECT CONCAT(country, ',') REST from rawdata),
     WORDS_country as (
        SELECT SUBSTRING(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from data
        union all
        select substring(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from WORDS_country
        where locate(',', rest) > 0
)
select distinct word from WORDS_country  order by word
)
SELECT * from X;

## Obtener lista de 'categorias' unicas
INSERT INTO category (Name)
with X as (
WITH RECURSIVE e
    DATA as (SELECT CONCAT(listed_in, ',') REST from rawdata),
     WORDS_listedin as (
        SELECT SUBSTRING(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from data
        union all
        select substring(rest, 1, locate(',', rest) - 1) word, substring(rest, locate(',', rest) + 1) rest
        from WORDS_listedin
        where locate(',', rest) > 0
)
select distinct word from WORDS_listedin  order by word
)
SELECT * from X;
