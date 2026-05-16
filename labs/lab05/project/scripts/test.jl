using DrWatson
@quickactivate "project"
include(srcdir("DiningPhilosophers.jl"))
using .DiningPhilosophers

# Тест 1: построение сети
net, u0, names = build_classical_network(3)
println("Сеть построена: ", size(net.incidence))

# Тест 2: моделирование ODE
df_ode = simulate_ode(net, u0, 10.0)
println("ODE моделирование завершено: ", size(df_ode))

# Тест 3: стохастическое моделирование
df_stoch = simulate_stochastic(net, u0, 10.0)
println("Стохастическое моделирование завершено: ", size(df_stoch))

# Тест 4: проверка deadlock
deadlock = detect_deadlock(df_stoch, net)
println("Deadlock обнаружен: ", deadlock)
