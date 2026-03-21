using DrWatson
@quickactivate "project"
using Agents
using DataFrames
using Plots

include(srcdir("daisyworld.jl"))

using CairoMakie

#Определение критериев отбора агентов
black(a) = a.breed == :black
white(a) = a.breed == :white
adata = [(black, count), (white, count)]

#Инициализация модели
model = daisyworld(; solar_luminosity = 1.0)

#Запуск симуляции и сбор данных
agent_df, model_df = run!(model, 1000; adata)

#Визуализация результатов
figure = Figure(size = (600, 400));

ax = figure[1, 1] = Axis(figure, xlabel = "tick", ylabel = "daisy count")
blackl = lines!(ax, agent_df[!, :time], agent_df[!, :count_black], color = :black)
whitel = lines!(ax, agent_df[!, :time], agent_df[!, :count_white], color = :orange)
Legend(figure[1, 2], [blackl, whitel], ["black", "white"], labelsize = 12)

#Сохранение результатов
save(plotsdir("daisy_count.png"), figure)
