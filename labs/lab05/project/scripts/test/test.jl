using DrWatson
@quickactivate "project"
include(srcdir("DiningPhilosophers.jl"))
using .DiningPhilosophers

net, u0, names = build_classical_network(3)
println("Сеть построена: ", size(net.incidence))

df_ode = simulate_ode(net, u0, 10.0)
println("ODE моделирование завершено: ", size(df_ode))

df_stoch = simulate_stochastic(net, u0, 10.0)
println("Стохастическое моделирование завершено: ", size(df_stoch))

deadlock = detect_deadlock(df_stoch, net)
println("Deadlock обнаружен: ", deadlock)
