/* COVID 19 Data Exploration (February 2020 - March 2022)

Skills used: JOIN, CTE, Temporary Table, CONVERT/CAST Data Types, CREATE VIEW, Aggregations

*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Select data that I am going to be using. Order by location and date
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in your country (The US in my case)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
--WHERE location like '%state%'
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows the percentage of population that got COVID (in the US in my case)
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PopulationInfectedPercent
FROM PortfolioProject..CovidDeaths
--WHERE location like '%state%'
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at the countries with the highest infection rate compared to their respective population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PopulationInfectedPercent
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PopulationInfectedPercent DESC;

-- Looking at countries with highest death count
-- Convert total_deaths data type to integer for the result to work properly 
SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeath DESC;

-- LOOKING AT THE DATA BY CONTINENT
-- Continents with the highest death count
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeath DESC;

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
--WHERE location like '%state%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;

-- Looking at Total population vs Vaccinations
-- Finding the rolling number of people got vaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USE CTE to perform the previous query
-- In addition, finding the percentage of population got vaccinated
WITH VacvPop (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS VacPercent
FROM VacvPop;

-- USE TEMP TABLE to perform the previous query
DROP TABLE IF EXISTS #PopulationVaccinatedPercent
CREATE TABLE #PopulationVaccinatedPercent
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PopulationVaccinatedPercent
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS VacPercent
FROM #PopulationVaccinatedPercent;

-- Creating view to store data for later visualizations
CREATE VIEW PopulationVaccinatedPercent
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, (SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Checking above created view
SELECT *
FROM PopulationVaccinatedPercent;
