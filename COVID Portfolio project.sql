SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

--Select Data that we are going to be using 

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths 
order by 1,2

--looking at total cases vs total deaths

Select Location, date, total_cases, total_deaths, (CONVERT(float,total_deaths)/NULLIF(CONVERT(float, total_cases),0))*100 AS
Deathpercentage
From PortfolioProject..CovidDeaths
WHERE location like '%states%'
order by 1,2


--looking at the Total Cases vs Population
--shows what percentage of population got Covid 


Select Location, date, population, total_cases, (CONVERT(float,total_cases)/NULLIF(CONVERT(float, population),0))*100 AS
PercentPopulationInfected
From PortfolioProject..CovidDeaths
WHERE location like '%states%'
order by 1,2


--looking at Countries with highest infection rate compared to population 

Select Location, population, MAX(total_cases) as HighestInfectionCount, (CONVERT(float,MAX (total_cases))/NULLIF(CONVERT(float, population),0))*100 AS
PercentPopulationInfected
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
Group by location, population
order by PercentPopulationInfected desc

--Showing countries with the Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
where continent is not null
Group by location
order by TotalDeathCount desc

--LETS BREAK THINGS DOWN BY CONTINENT
--showing continents with highest death counts per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
where continent is not null
Group by continent
order by TotalDeathCount desc

--Global Numbers

Select SUM(cast(new_cases as float)) totalcases, sum(cast(new_deaths as int)) totaldeaths, sum(cast(new_deaths as int))/sum(cast(new_cases as float))*100 as deathpercentage
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
where continent is not null
--group by date
order by 2,1

UPDATE CovidDeaths
set new_deaths=NULL where new_deaths=0 

update CovidVaccinations
set new_vaccinations_smoothed_per_million=null 
where new_vaccinations_smoothed_per_million not like '%[a-z,0-9]%'

update CovidDeaths
set continent=null 
where continent not like '%[a-z,0-9]%'

--looking at total population vs vaccinations 

select *
from PortfolioProject..Coviddeaths dea
join PortfolioProject..CovidVaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date


   select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..Coviddeaths dea
join PortfolioProject..CovidVaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
order by 2,3


--use CTE

with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..Coviddeaths dea
join PortfolioProject..CovidVaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select*, (RollingPeopleVaccinated/population)*100
from PopVsVac 

--Temp Table
drop table if exists #percentpopulationvaccinated 
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..Coviddeaths dea
join PortfolioProject..CovidVaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
--where dea.continent is not null
--order by 2,3
select*, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


--creating view to store data for later visualizations


create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..Coviddeaths dea
join PortfolioProject..CovidVaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
--order by 2,3