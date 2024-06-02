using HTTP
using JSON
using Plots

# Funktion zum Abrufen der Daten für ein bestimmtes Jahr und Indikator
function get_indicator_data(country_code::String, indicator::String, start_year::Int, end_year::Int)
    url = "http://api.worldbank.org/v2/country/$country_code/indicator/$indicator?date=$start_year:$end_year&format=json&per_page=1000"
    response = HTTP.get(url)
    if response.status == 200
        data = JSON.parse(String(response.body))
        return data
    else
        println("Fehler beim Abrufen der Daten für den Indikator $indicator: HTTP-Statuscode ", response.status)
        return nothing
    end
end

# Abrufen der Geburten- und Sterberaten von China für die Jahre 1950 bis 2024
country_code = "CHN"
start_year = 1960
end_year = 2022

# Indikatoren für Geburten- und Sterberaten
birth_rate_indicator = "SP.DYN.CBRT.IN"
death_rate_indicator = "SP.DYN.CDRT.IN"

birth_data = get_indicator_data(country_code, birth_rate_indicator, start_year, end_year)
death_data = get_indicator_data(country_code, death_rate_indicator, start_year, end_year)

# Extrahieren der Daten
years = start_year:end_year
birth_rates = [NaN for _ in years]
death_rates = [NaN for _ in years]

for record in birth_data[2]
    year = parse(Int, record["date"])
    if year in years
        birth_rates[year - start_year + 1] = record["value"]
    end
end

for record in death_data[2]
    year = parse(Int, record["date"])
    if year in years
        death_rates[year - start_year + 1] = record["value"]
    end
end

# Plotten der Geburten- und Sterberaten
plot(years, birth_rates, label="Geburtenrate", xlabel="Jahr", ylabel="Rate (pro 1000 Personen)", title="Geburten- und Sterberaten von China (1960-2024)", lw=2)
plot!(years, death_rates, label="Sterberate", lw=2, color=:red)
savefig("geburten_sterberaten_china_1950_2024.png")
