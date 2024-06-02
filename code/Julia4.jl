using HTTP
using JSON
using Plots
using Statistics

# Funktion zum Abrufen der Daten für ein bestimmtes Jahr und Indikator
function get_indicator_data(country_code::String, indicator::String, start_year::Int, end_year::Int)
    # URL für den API-Aufruf zur Abrufung der Daten von der Weltbank
    url = "http://api.worldbank.org/v2/country/$country_code/indicator/$indicator?date=$start_year:$end_year&format=json&per_page=1000"
    # HTTP-GET-Anfrage an die URL
    response = HTTP.get(url)
    # Überprüfen, ob die Anfrage erfolgreich war
    if response.status == 200
        # JSON-Daten aus der Antwort parsen
        data = JSON.parse(String(response.body))
        return data
    else
        # Fehlermeldung ausgeben, wenn die Anfrage nicht erfolgreich war
        println("Fehler beim Abrufen der Daten für den Indikator $indicator: HTTP-Statuscode ", response.status)
        return nothing
    end
end

# Abrufen der Geburten-, Sterberaten und Bevölkerung von China für die Jahre 1960 bis 2022
country_code = "CHN" # Ländercode für China
start_year = 1960 # Startjahr
end_year = 2022 # Endjahr

# Indikatoren für Geburten-, Sterberaten und Bevölkerung
birth_rate_indicator = "SP.DYN.CBRT.IN" # Indikator für die Geburtenrate
death_rate_indicator = "SP.DYN.CDRT.IN" # Indikator für die Sterberate
population_indicator = "SP.POP.TOTL" # Indikator für die Gesamtbevölkerung

# Abrufen der Daten für die jeweiligen Indikatoren
birth_data = get_indicator_data(country_code, birth_rate_indicator, start_year, end_year)
death_data = get_indicator_data(country_code, death_rate_indicator, start_year, end_year)
population_data = get_indicator_data(country_code, population_indicator, start_year, end_year)

# Extrahieren der Daten
years = start_year:end_year # Jahre von 1960 bis 2022
birth_rates = [NaN for _ in years] # Initialisiere Geburtenraten mit NaN
death_rates = [NaN for _ in years] # Initialisiere Sterberaten mit NaN
historical_population = [NaN for _ in years] # Initialisiere historische Bevölkerung mit NaN

# Extrahieren der Geburtenraten
for record in birth_data[2]
    year = parse(Int, record["date"]) # Jahr aus dem Datensatz parsen
    if year in years
        birth_rates[year - start_year + 1] = record["value"] # Geburtenrate für das entsprechende Jahr speichern
    end
end

# Extrahieren der Sterberaten
for record in death_data[2]
    year = parse(Int, record["date"]) # Jahr aus dem Datensatz parsen
    if year in years
        death_rates[year - start_year + 1] = record["value"] # Sterberate für das entsprechende Jahr speichern
    end
end

# Extrahieren der Bevölkerungsdaten
for record in population_data[2]
    year = parse(Int, record["date"]) # Jahr aus dem Datensatz parsen
    if year in years
        historical_population[year - start_year + 1] = record["value"] # Bevölkerungszahl für das entsprechende Jahr speichern
    end
end

# Berechnung der jährlichen Wachstumsrate in Prozent
function calculate_growth_rate(birth_rates::Vector{Float64}, death_rates::Vector{Float64})
    growth_rates = [NaN for _ in birth_rates] # Initialisiere Wachstumsraten mit NaN
    for i in 1:length(birth_rates)
        if !isnan(birth_rates[i]) && !isnan(death_rates[i]) # Überprüfen, ob Geburten- und Sterberate gültige Werte haben
            growth_rates[i] = (birth_rates[i] - death_rates[i]) / 10 # Berechnung der Wachstumsrate
        end
    end
    return growth_rates
end

growth_rates = calculate_growth_rate(birth_rates, death_rates) # Berechne die jährlichen Wachstumsraten

# Prognose der zukünftigen Wachstumsraten mit Annahme einer sinkenden Bevölkerung
function extend_growth_rates(growth_rates::Vector{Float64}, future_years::Int)
    avg_growth_rate = mean(skipmissing(growth_rates)) # Durchschnittliche Wachstumsrate berechnen, unter Auslassung von NaN
    # Nehmen wir an, dass die Wachstumsrate jedes Jahr leicht negativ wird, um eine moderate Abnahme der Bevölkerung zu erreichen
    extended_growth_rates = vcat(growth_rates, [0.1 - i*0.03 for i in 1:future_years])
    return extended_growth_rates
end

# Funktion zur Bevölkerungsprognose
function forecast_population(start_population::Float64, growth_rates::Vector{Float64}, future_years::Int)
    future_population = [start_population] # Initialisiere zukünftige Bevölkerung mit der Startpopulation
    for i in 1:future_years
        # Berechnung der neuen Bevölkerungszahl basierend auf der Wachstumsrate
        new_population = future_population[end] * (1 + growth_rates[length(growth_rates) - future_years + i] / 100)
        push!(future_population, new_population) # Neue Bevölkerungszahl zur Liste hinzufügen
    end
    return future_population
end

# Beispielhafte Startpopulation und Prognose bis 2040
start_population = historical_population[end] # Startpopulation ist die letzte bekannte Bevölkerungszahl
future_years = 2022:2100 # Zukunftsjahre von 2022 bis 2100
extended_growth_rates = extend_growth_rates(growth_rates, length(future_years)) # Erweitere die Wachstumsraten um die Zukunftsjahre
future_population = forecast_population(start_population, extended_growth_rates, length(future_years)) # Prognostiziere die zukünftige Bevölkerung

# Plot der jährlichen Wachstumsrate in Prozent
plot(years, growth_rates, label="Jährliche Wachstumsrate", xlabel="Jahr", ylabel="Wachstumsrate (%)", title="Jährliche Wachstumsrate von China (1960-2022)", lw=2, color=:blue)
savefig("jaehrliche_wachstumsrate_china_1960_2022.png") # Speichere den Plot der jährlichen Wachstumsrate

# Plot der historischen und prognostizierten Bevölkerung
plot(years, historical_population, label="Historische Bevölkerung", xlabel="Jahr", ylabel="Bevölkerung", title="Bevölkerungsprognose für China", lw=2)
plot!(future_years, future_population[2:end], label="Prognostizierte Bevölkerung", lw=2, color=:red)
savefig("bevoelkerungsprognose_china.png") # Speichere den Plot der Bevölkerungsprognose

# Weitere Visualisierung: Geburtenrate vs. Sterberate
plot(years, birth_rates, label="Geburtenrate", xlabel="Jahr", ylabel="Rate (pro 1000 Personen)", title="Geburtenrate vs. Sterberate in China", lw=2)
plot!(years, death_rates, label="Sterberate", lw=2, color=:red)
savefig("geburtenrate_vs_sterberate_china.png") # Speichere den Plot der Geburten- und Sterberaten