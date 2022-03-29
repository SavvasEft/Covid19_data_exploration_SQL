
/*
Exploration of Covid 19 Data

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Converting Data Types
*/


---***
-- Viewing data of covid deaths:
---***
SELECT
    *
FROM
    ..Covid_Deaths AS covid_deaths
ORDER BY
    1,2 DESC 

------------------------------------------


---***
-- Calculating Infection rate (Cases no per population) and 
-- Fatality rate (Death numbers per case numbers )
---***
SELECT
    Location, date, population, total_cases,
    (total_cases/population)*100 as infection_rate,
    total_deaths, (total_deaths/total_cases)*100 as death_per_case
FROM
    ..Covid_Deaths AS covid_deaths
WHERE
--    Location like '%Cyprus' and  -- for specific countries
    continent is not NULL
ORDER BY
    1,2 DESC

------------------------------------------


---***
-- Highest infection count per country
-- Maximum percentage of population that has gotten Covid
---***

SELECT
    Location, population, MAX(total_cases) as highest_infection_count,
    ((max(total_cases)/population))*100 as percent_population_infected
FROM
    ..Covid_Deaths AS covid_deaths
WHERE
    continent is not NULL
GROUP BY
    Location, population
ORDER BY
    percent_population_infected DESC

------------------------------------------



---***
-- Highest death count by country
---***

SELECT 
    Location, MAX(cast(Total_deaths as int)) as total_death_count
FROM
    ..Covid_Deaths AS covid_deaths
WHERE
    continent is not NULL
GROUP BY
    Location
ORDER BY
    total_death_count desc

------------------------------------------



---***
-- Deaths per continent
---***

SELECT
    location, MAX(cast(Total_deaths as int)) as total_death_count
FROM
    ..Covid_Deaths AS covid_deaths
WHERE
    location = 'Europe' or
    location = 'North America' or
    location = 'South America' or
    location = 'Oceania' or
    location = 'Asia' or
    location = 'Africa' or
    location = 'South America' and
    continent is NULL

GROUP BY 
    location
ORDER BY
    location desc

------------------------------------------



---***
-- Percentage of world population that has gotten Covid 19, died from Covid 19 and Covid 19 World fatality rate 
---***

SELECT
    SUM(new_cases) as total_cases,
    SUM(cast(new_deaths as int)) as total_deaths,
    SUM(cast(new_deaths as int))/sum(new_cases)*100 as deaths_per_case_percent

FROM
   ..Covid_Deaths AS covid_deaths
WHERE
    continent is not NULL


------------------------------------------



---***
--Population vaccinated per day (Join)
---***
SELECT
    cov_dth.continent, cov_dth.location, cov_dth.date, cov_dth.population,
    CAST(cov_vac.new_vaccinations as int), --  as new_vaccinat,
    SUM(CAST(cov_vac.new_vaccinations as int)) OVER (Partition by cov_dth.Location ORDER BY cov_dth.Location, cov_dth.date) as RollingPeopleVaccinated
    -- --the last calculates the total of new vaccinations no for each location and for each day – summing with the previous day

FROM
   ..Covid_Vaccinations AS cov_vac
JOIN
    ..Covid_Deaths AS cov_dth
    ON
    cov_dth.Location = cov_vac.Location
    AND
    cov_dth.date = cov_vac.date
WHERE
    cov_dth.continent is not null

------------------------------------------



---***
--Percent of Total Population that got vaccinated per day per (CTE)
---***
WITH PopVsVac AS
(

SELECT cov_dth.continent, cov_dth.location, cov_dth.date, cov_dth.population,
    CAST(cov_vac.new_vaccinations as int) as new_vaccinat,
    SUM(CAST(cov_vac.new_vaccinations as int)) OVER (Partition by cov_dth.Location ORDER BY cov_dth.Location, cov_dth.date) as RollingPeopleVaccinated
FROM
   ..Covid_Vaccinations AS cov_vac
JOIN
    ..Covid_Deaths AS cov_dth
    ON
    cov_dth.Location = cov_vac.Location
    AND
    cov_dth.date = cov_vac.date
WHERE
    cov_dth.continent is not null

)
SELECT *, RollingPeopleVaccinated/Population*100 as vaccinated_percent
FROM
    PopVsVac

------------------------------------------



---***
--Population vaccinated so far (Using CTE)
---***
WITH PopVsVac AS
(
SELECT cov_dth.continent, cov_dth.location, cov_dth.date, cov_dth.population,
    CAST(cov_vac.new_vaccinations as int) as new_vaccinat,
    SUM(CAST(cov_vac.new_vaccinations as int)) OVER (Partition by cov_dth.Location ORDER BY cov_dth.Location, cov_dth.date) as RollingPeopleVaccinated
FROM
    ..Covid_Vaccinations AS cov_vac
JOIN
    ..Covid_Deaths AS cov_dth
    ON
    cov_dth.Location = cov_vac.Location
    AND
    cov_dth.date = cov_vac.date
WHERE
    cov_dth.continent is not null
)
SELECT location,population, max(RollingPeopleVaccinated)as ppl_vaccinated, max(RollingPeopleVaccinated)/Population*100 as vaccinated_percent
FROM
    PopVsVac
GROUP BY
    location, population

------------------------------------------




---***
-- Total Cases Vs Total Deaths
-- Percentage of population that has gotten Covid (Using Temp tables)
---*** 

DROP TABLE IF exists ..Covid.PrcPopVac;

CREATE TABLE ..Covid.PrcPopVac(
    Continent string,
    Location string,
    Date datetime,
    Population int, 
    New_vaccinations int,
    RollingPeopleVaccinated int64);

Insert into 
    ..Covid.PrcPopVac
SELECT 
    cov_dth.continent, cov_dth.location, cov_dth.date, cov_dth.population,
    CAST(cov_vac.new_vaccinations as int) as new_vaccinat,
    SUM(CAST(cov_vac.new_vaccinations as int)) OVER (Partition by cov_dth.Location ORDER BY cov_dth.Location, cov_dth.date) as RollingPeopleVaccinated
FROM
    ..Covid_Vaccinations AS cov_vac
JOIN
    ..Covid_Deaths AS cov_dth
    ON
    cov_dth.Location = cov_vac.Location
    AND
    cov_dth.date = cov_vac.date
WHERE
    cov_dth.continent is not null;

Select *, RollingPeopleVaccinated/Population*100 as vaccinated_percent
FROM
    ..Covid.PrcPopVac

------------------------------------------