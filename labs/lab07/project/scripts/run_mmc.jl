using DrWatson
@quickactivate "project"
include(srcdir("mmc_model.jl"))

using DataFrames, CSV, Plots, Statistics

function main()
    # Параметры симуляции
    seed = 123
    num_customers = 10
    num_servers = 2
    mu = 1.0 / 2
    lam = 0.9

    log = setup_and_run(; seed, num_customers, num_servers, mu, lam)
    df = DataFrame(log)

    # 1. Динамика числа клиентов
    events = []
    current = 0
    for row in eachrow(df)
        if row.event == "arrived"
            current += 1
            push!(events, (row.time, current))
        elseif row.event == "exitedService"
            current -= 1
            push!(events, (row.time, current))
        end
    end
    pushfirst!(events, (0.0, 0.0))
    times_N = [e[1] for e in events]
    values_N = [e[2] for e in events]

    p1 = plot(times_N, values_N, seriestype=:steppost, linewidth=2,
              xlabel="Время моделирования", ylabel="Число клиентов",
              title="Динамика числа клиентов в системе", legend=false)

    # 2. Время ожидания по клиентам
    waiting_times = []
    for id in 1:num_customers
        arrived = df[(df.id .== id) .& (df.event .== "arrived"), :time]
        entered = df[(df.id .== id) .& (df.event .== "enteredService"), :time]
        if !isempty(arrived) && !isempty(entered)
            push!(waiting_times, entered[1] - arrived[1])
        else
            push!(waiting_times, NaN)
        end
    end

    p2 = scatter(1:num_customers, waiting_times,
                 xlabel="Индекс клиента", ylabel="Время ожидания",
                 title="Время ожидания по клиентам", label="", markersize=3)

    # 3. Гистограмма
    p3 = histogram(waiting_times[isfinite.(waiting_times)], bins=15, alpha=0.7,
                   xlabel="Время ожидания", ylabel="Частота",
                   title="Распределение времени ожидания", label="")

    final_plot = plot(p1, p2, p3, layout=(3,1), size=(600, 900))
    savefig(final_plot, plotsdir("mmc_advanced_analysis.png"))

    waiting_df = DataFrame(id=1:num_customers, waiting_time=waiting_times)
    CSV.write(datadir("waiting_times.csv"), waiting_df)

    println("Среднее время ожидания: ", mean(skipmissing(waiting_times)))
    println("Максимальное время ожидания: ", maximum(skipmissing(waiting_times)))
    println("Доля клиентов, получивших обслуживание: ",
            count(isfinite, waiting_times) / num_customers * 100, "%")
end

main()