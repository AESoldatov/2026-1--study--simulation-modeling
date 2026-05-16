using DrWatson
@quickactivate "project"
include(srcdir("ross_model.jl"))

using DataFrames, CSV, Plots, Statistics

function build_repairmen_state(log_df, num_repairmen, stop_time)
    sort!(log_df, :time)
    times = [0.0]
    busy_repairmen = [0]
    current_busy = 0
    for row in eachrow(log_df)
        if row.event == "repair_start"
            current_busy += 1
            push!(times, row.time)
            push!(busy_repairmen, current_busy)
        elseif row.event == "repair_end"
            current_busy -= 1
            push!(times, row.time)
            push!(busy_repairmen, current_busy)
        end
    end
    push!(times, stop_time)
    push!(busy_repairmen, current_busy)
    state_df = DataFrame(time=times, busy_repairmen=busy_repairmen)
    busy_area = 0.0
    for i in 1:(nrow(state_df)-1)
        dt = state_df.time[i+1] - state_df.time[i]
        busy_area += state_df.busy_repairmen[i] * dt
    end
    utilization = busy_area / (stop_time * num_repairmen)
    return state_df, utilization
end

function build_repair_queue_state(log_df, stop_time)
    sort!(log_df, :time)
    times = [0.0]
    queue_lengths = [0]
    current_queue = 0
    for row in eachrow(log_df)
        if row.event == "repair_request"
            current_queue += 1
            push!(times, row.time)
            push!(queue_lengths, current_queue)
        elseif row.event == "repair_start"
            current_queue -= 1
            push!(times, row.time)
            push!(queue_lengths, current_queue)
        end
    end
    push!(times, stop_time)
    push!(queue_lengths, current_queue)
    queue_df = DataFrame(time=times, queue_length=queue_lengths)
    queue_area = 0.0
    for i in 1:(nrow(queue_df)-1)
        dt = queue_df.time[i+1] - queue_df.time[i]
        queue_area += queue_df.queue_length[i] * dt
    end
    mean_queue_length = queue_area / stop_time
    return queue_df, mean_queue_length
end

function build_good_machines_state(log_df, N, S, stop_time)
    sort!(log_df, :time)
    times = [0.0]
    good_machines = [N + S]
    current_good = N + S
    for row in eachrow(log_df)
        if row.event == "failure"
            current_good -= 1
            push!(times, row.time)
            push!(good_machines, current_good)
        elseif row.event == "repair_end"
            current_good += 1
            push!(times, row.time)
            push!(good_machines, current_good)
        end
    end
    push!(times, stop_time)
    push!(good_machines, current_good)
    return DataFrame(time=times, good_machines=good_machines)
end

# =============================================================
# Параметры экспериментов
# =============================================================
RUNS_PER_PARAM = 20
SEED_OFFSET = 1000
λ = 100.0
μ = 1.0

# ---- График 1: зависимость времени падения от числа ремонтников ----
function plot_crash_vs_repairmen(N, S, repairmen_range)
    results = []
    for R in repairmen_range
        crash_times = Float64[]
        for run in 1:RUNS_PER_PARAM
            seed = SEED_OFFSET + R * 100 + run
            res = sim_repair(; N=N, S=S, num_repairmen=R, seed=seed, lam=λ, mu=μ)
            push!(crash_times, res.stop_time)
        end
        push!(results, (R, mean(crash_times), std(crash_times)))
    end
    df = DataFrame(R=[r for (r,_,_) in results],
                   mean=[m for (_,m,_) in results],
                   std=[s for (_,_,s) in results])
    p = plot(df.R, df.mean, yerror=df.std, marker=:circle,
             xlabel="Число ремонтников", ylabel="Среднее время до падения (часы)",
             title="Временя падения от числа ремонтников (N=$N, S=$S)",
             legend=false, size=(800, 600))
    savefig(p, plotsdir("ross_crash_vs_repairmen.png"))
    return p, df
end

# ---- График 2: зависимость времени падения от числа запасных машин S ----
function plot_crash_vs_spares(N, repairmen, S_range)
    results = []
    for S in S_range
        crash_times = Float64[]
        for run in 1:RUNS_PER_PARAM
            seed = SEED_OFFSET + S * 100 + run
            res = sim_repair(; N=N, S=S, num_repairmen=repairmen, seed=seed, lam=λ, mu=μ)
            push!(crash_times, res.stop_time)
        end
        push!(results, (S, mean(crash_times), std(crash_times)))
    end
    df = DataFrame(S=[s for (s,_,_) in results],
                   mean=[m for (_,m,_) in results],
                   std=[s for (_,_,s) in results])
    p = plot(df.S, df.mean, yerror=df.std, marker=:circle,
             xlabel="Число запасных машин S", ylabel="Среднее время до падения (часы)",
             title="Временя падения от резерва (N=$N, ремонтников=$repairmen)",
             legend=false, size=(800, 600))
    savefig(p, plotsdir("ross_crash_vs_spares.png"))
    return p, df
end

# ---- График 3: зависимость времени падения от числа основных машин N ----
function plot_crash_vs_N(S, repairmen, N_range)
    results = []
    for N in N_range
        crash_times = Float64[]
        for run in 1:RUNS_PER_PARAM
            seed = SEED_OFFSET + N * 10 + run
            res = sim_repair(; N=N, S=S, num_repairmen=repairmen, lam=λ, mu=μ)
            push!(crash_times, res.stop_time)
        end
        push!(results, (N, mean(crash_times), std(crash_times)))
    end
    df = DataFrame(N=[n for (n,_,_) in results],
                   mean=[m for (_,m,_) in results],
                   std=[s for (_,_,s) in results])
    p = plot(df.N, df.mean, yerror=df.std, marker=:circle,
             xlabel="Число основных машин N", ylabel="Среднее время до падения (часы)",
             title="Временя падения от числа машин (S=$S, ремонтников=$repairmen)",
             legend=false, size=(800, 600))
    savefig(p, plotsdir("ross_crash_vs_N.png"))
    return p, df
end

# ---- График 4: динамика числа исправных машин во времени (один прогон) ----
function plot_good_machines_dynamics(N, S, repairmen, seed=seed)
    res = sim_repair(; N=N, S=S, num_repairmen=repairmen, seed=seed, lam=λ, mu=μ)
    log_df = DataFrame(res.log)
    good_df = build_good_machines_state(log_df, N, S, res.stop_time)
    
    p = plot(good_df.time, good_df.good_machines, seriestype=:steppost,
             xlabel="Время (часы)", ylabel="Число исправных машин",
             title="Динамика исправных машин (N=$N, S=$S, ремонтников=$repairmen)",
             legend=false, linewidth=2, size=(800,600))
    vline!([res.stop_time], linestyle=:dash, color=:red, label="Падение")
    savefig(p, plotsdir("ross_good_machines_dynamics.png"))
    return p, good_df, res.stop_time
end

# =============================================================
# Запуск всех трёх анализов
# =============================================================
println("1. Строим график: время падения vs число ремонтников...")
plot_crash_vs_repairmen(10, 3, 1:5)

println("2. Строим график: время падения vs число запасных S...")
plot_crash_vs_spares(10, 1, 0:6)

println("3. Строим график: время падения vs число основных машин N...")
plot_crash_vs_N(3, 1, 5:5:20)

println("4. График: динамика исправных машин...")
plot_good_machines_dynamics(10, 3, 1, 123)

println("Все графики сохранены в папку plots/")