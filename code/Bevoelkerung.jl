using HTTP
using JSON
using Plots

# Funktion zum Abrufen der Bevölkerungsdaten für ein bestimmtes Jahr
function get_population_data(country_code::String, year::Int)
    url = "http://api.worldbank.org/v2/country/$country_code/indicator/SP.POP.TOTL?date=$year&format=json"
    response = HTTP.get(url)
    if response.status == 200
        data = JSON.parse(String(response.body))
        return data
    else
        println("Fehler beim Abrufen der Daten für das Jahr $year: HTTP-Statuscode ", response.status)
        return nothing
    end
end

# Abrufen der Bevölkerungsdaten von China für die Jahre 1950 bis 2024
country_code = "CHN"
years = 1960:2022
populations = []

for year in years
    population_data = get_population_data(country_code, year)
    if population_data !== nothing && length(population_data) > 1 && length(population_data[2]) > 0
        population = population_data[2][1]["value"]
        push!(populations, population)
    else
        push!(populations, NaN)  # NaN falls keine Daten gefunden wurden
    end
end

# Plotten der historischen Bevölkerung von 1950 bis 2024
plot(years, populations, label="Bevölkerung von China", xlabel="Jahr", ylabel="Einwohnerzahl", title="Bevölkerungswachstum von China (1960-2022)", lw=2, marker=:circle)
savefig("bevoelkerung_china_1950_2024.png")
