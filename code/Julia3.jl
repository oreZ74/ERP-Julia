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

# Abrufen der Geburten- und Sterberaten von China für die Jahre 1960 bis 2022
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

# Berechnung der jährlichen Wachstumsrate in Prozent
growth_rates = [NaN for _ in years]
for i in 1:length(years)
    if !isnan(birth_rates[i]) && !isnan(death_rates[i])
        growth_rates[i] = (birth_rates[i] - death_rates[i]) / 10
    end
end

# Plotten der jährlichen Wachstumsrate in Prozent
plot(years, growth_rates, label="Jährliche Wachstumsrate", xlabel="Jahr", ylabel="Wachstumsrate (%)", title="Jährliche Wachstumsrate von China (1960-2022)", lw=2, color=:blue)
savefig("jaehrliche_wachstumsrate_china_1960_2022.png")
