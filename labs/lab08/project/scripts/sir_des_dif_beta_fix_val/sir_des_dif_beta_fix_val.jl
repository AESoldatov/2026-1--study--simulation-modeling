using DrWatson
@quickactivate "project"
include(srcdir("sir_model_fix_val.jl"))
using Random, StatsPlots, BenchmarkTools

Random.seed!(1234)

tmax = 40.0
u0 = [990, 10, 0]      # S, I, R
betas = [0.03, 0.05, 0.07]


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
    savefig(plotsdir(string("sir_des_fix_val_", β, ".png")))
end
