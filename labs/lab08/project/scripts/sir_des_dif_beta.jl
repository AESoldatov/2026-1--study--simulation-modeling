using DrWatson
@quickactivate "project"
include(srcdir("sir_model.jl"))
using Random, StatsPlots, BenchmarkTools

# Параметры модели
tmax = 40.0
u0 = [990, 10, 0]      # S, I, R
betas = [0.03, 0.05, 0.07]
Random.seed!(1234)
  
for β in betas
    p = [β, 10.0, 0.25]  # β, c, γ
    des_model = MakeSIRModel(u0, p) # Запуск модели
    activate(des_model)
    sir_run(des_model, tmax)
    data_des = out(des_model)
    @df data_des plot( # Визуализация
        :t,
        [:S :I :R],
        labels = ["S" "I" "R"],
        xlab = "Время",
        ylab = "Численность",
        title = "Дискретно-событийная SIR модель",
    )
    savefig(plotsdir(string("sir_des_", β, ".png")))    
end
