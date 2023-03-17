#### SCHEMA DEFINITION ####
CREATE SCHEMA `series_and_movies` DEFAULT CHARACTER SET utf8mb4 COLLATE= utf8mb4_spanish_ci;
USE series_and_movies;

#### SETTINGS ####
SELECT @@global.secure_file_priv;
SET GLOBAL local_infile=1;
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS=0;
SET SESSION group_concat_max_len = 10000;

#### TABLES ####
## RAW DATA - initial table
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

## Fact table ##
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

## Dimension tables ##
# Origin ==>  Stores data source - If it is a show listed on Netflix or Disney.
DROP TABLE IF EXISTS `origin`;
CREATE TABLE IF NOT EXISTS `origin`(
`OriginId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

# Type ==> Movies o TV show
DROP TABLE IF EXISTS `type`;
CREATE TABLE IF NOT EXISTS `type`(
`TypeId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(50)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

## Rating ==> global - for Netflix and Disney
DROP TABLE IF EXISTS `rating`;
CREATE TABLE IF NOT EXISTS `rating`(
`RatingId` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
`Name` VARCHAR(100)
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#### INSERTS ####
## To insert types of shows (TV/Movie) into the dimensional table.
INSERT INTO type (Name)
SELECT DISTINCT(TYPE) FROM RAWDATA;

## To insert show source (Netflix/Disney) into the dimensional table
INSERT INTO origin (Name)
SELECT DISTINCT(origin) FROM RAWDATA;

## To insert a list with unique global ratings.
INSERT INTO rating (Name)
SELECT DISTINCT(rating) FROM RAWDATA;

## To insert normalized data into the fact table
INSERT INTO shows (ShowIdFromOrigin, OriginId, TypeID, Title, 
					DirectorId, CastId, CountryId, DateAdded, ReleaseYear, 
					RatingId, Duration, ListedId, Description)
SELECT ShowId, 
		CASE WHEN Origin = 'Disney' THEN 1 ELSE 2 END AS OriginCoded, 
        CASE WHEN type = 'Movie' THEN 1 ELSE 2 END AS TypeCoded, 
        Title, Director, Cast, Country, DateAdded, ReleaseYear, Rating, Duration, ListedIn, Description
FROM rawdata;

## To insert source data (Netflix/Disney) into the dimensional table.
INSERT INTO origin (Name)
SELECT DISTINCT(origin)
from rawdata;

#### UPDATES ####

## Shows Table
UPDATE `shows`
SET shows.RatingId = (SELECT rating.RatingId FROM rating WHERE shows.RatingId = rating.Name);

ALTER TABLE `shows` 
CHANGE COLUMN `RatingId` `RatingId` INT NULL DEFAULT NULL ;


#### DENORMALIZATION #####

## CAST TABLE
#a) Create table
DROP TABLE IF EXISTS cast_ok; 
CREATE TABLE cast_ok (
  AllActors VARCHAR(255),
  CastId INT
)
ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) Save the first result with all the actors
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllCast, castid FROM cast WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'cast'
  AND column_name LIKE 'Cast_%';
  
#c) And execute the following statement to save everything in the denormalized table
SET @query2 = CONCAT('INSERT INTO cast_ok (AllActors, CastId) SELECT AllCast, CastID FROM (', @query1, ') AS temp');
PREPARE stmt FROM @query2;
EXECUTE stmt;

# DIRECTORS TABLE
#a) Creates table
DROP TABLE IF EXISTS director_ok; 
CREATE TABLE director_ok (
  AllDirectors VARCHAR(255),
  DirectorId INT
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) Saves the first result with all the directors
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllDirectors, DirectorId FROM director WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'director'
  AND column_name LIKE 'Director_%';
  
#c) And we execute the following statement to save everything in the denormalized table
SET @query2 = CONCAT('INSERT INTO director_ok (AllDirectors, DirectorId) SELECT AllDirectors, DirectorId FROM (', @query1, ') AS temp');
PREPARE stmt FROM @query2;
EXECUTE stmt;

# COUNTRY TABLE
#a) We create the table
DROP TABLE IF EXISTS country_ok; 
CREATE TABLE country_ok (
  AllCountries VARCHAR(255),
  CountryId INT
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) We save the first result with all the countries
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllCountries, CountryId FROM country WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'country'
  AND column_name LIKE 'Country_%';
  
#c) We execute the following statement to save everything in the denormalized table
SET @query2 = CONCAT('INSERT INTO country_ok (AllCountries, CountryId) SELECT AllCountries, CountryId FROM (', @query1, ') AS temp');
PREPARE stmt FROM @query2;
EXECUTE stmt;


# LISTED TABLE
#a) We create the table
DROP TABLE IF EXISTS listed_ok; 
CREATE TABLE listed_ok (
  AllListed VARCHAR(255),
  ListedId INT
)ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE= utf8mb4_spanish_ci;

#b) We save the first result with all the listed
SET @query1 = NULL;

SELECT GROUP_CONCAT(
    CONCAT('SELECT ', column_name, ' AS AllListed, ListedId FROM listed WHERE ', column_name, ' IS NOT NULL')
    SEPARATOR ' UNION ALL '
) INTO @query1
FROM information_schema.columns
WHERE table_name = 'listed'
  AND column_name LIKE 'ListedIn_%';
  
#c) We execute the following statement to save everything in the denormalized table
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


