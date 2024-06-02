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

# Funktion zur Berechnung der Wachstumsrate
function calculate_growth_rate(populations)
    population_2015 = populations[findfirst(years .== 2015)]
    population_2022 = populations[end]
    return (population_2022 / population_2015)^(1 / (2022 - 2015)) - 1
end

# Abrufen der Bevölkerungsdaten von China für die Jahre 2000 bis 2024
country_code = "CHN"
years = 2000:2022
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
# Berechnung der durchschnittlichen Wachstumsrate seit 2015
growth_rate = calculate_growth_rate(populations)
# Prognose der Bevölkerung von China bis 2100 mit exponentiellem Wachstum
P0 = populations[end]
year_2100 = 2100
populations_2100 = [P0 * exp(growth_rate * (year - 2022)) for year in 2022:year_2100]

println(growth_rate)

println("Prognostizierte Bevölkerung von China im Jahr 2100: ", round(population_2100), " Personen")

# Plotten der historischen und prognostizierten Bevölkerung
plot(years, populations, label="Historische Bevölkerung", xlabel="Jahr", ylabel="Einwohnerzahl", title="Bevölkerung von China (2000-2022)", lw=2, marker=:circle)
plot!(2022:year_2100, populations_2100, label="Prognostizierte Bevölkerung (2022-2100)", lw=2, marker=:cirle,color=:red)


# Plot anzeigen
gui()  # Plottfenster anzeigen

# Plot als PNG-Datei speichern
savefig("bevoelkerung_china_2000_2100_prognose.png")
