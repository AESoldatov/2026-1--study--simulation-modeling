using ResumableFunctions
using ConcurrentSim
using Distributions
using Random
using StableRNGs

@resumable function machine(env, repair_facility, spares, rng, F, G, log)
    while true
        try
            @yield timeout(env, Inf)
        catch
        end
        @yield timeout(env, rand(rng, F))
        push!(log, (time=now(env), event="failure"))
        get_spare = take!(spares)
        @yield get_spare | timeout(env)
        if state(get_spare) != ConcurrentSim.idle
            @yield interrupt(value(get_spare))
            push!(log, (time=now(env), event="spare_used"))
        else
            push!(log, (time=now(env), event="crash"))
            throw(StopSimulation("No more spares!"))
        end
        @yield request(repair_facility)
        push!(log, (time=now(env), event="repair_start"))
        @yield timeout(env, rand(rng, G))
        @yield unlock(repair_facility)
        push!(log, (time=now(env), event="repair_end"))
        @yield put!(spares, active_process(env))
        push!(log, (time=now(env), event="spare_returned"))
    end
end

@resumable function start_sim(env, repair_facility, spares, N, S, rng, F, G, log)
    for i = 1:N
        proc = @process machine(env, repair_facility, spares, rng, F, G, log)
        @yield interrupt(proc)
    end
    for i = 1:S
        proc = @process machine(env, repair_facility, spares, rng, F, G, log)
        @yield put!(spares, proc)
    end
end

# Сторожевой процесс – останавливает симуляцию по таймауту
@resumable function watchdog(env, max_time)
    @yield timeout(env, max_time)
    throw(StopSimulation("Time limit reached"))
end

function sim_repair(; N=10, S=3, num_repairmen=1, seed=42, lam=100.0, mu=1.0, max_time=10000.0)
    rng = StableRNG(seed)
    F = Exponential(lam)
    G = Exponential(mu)
    sim = Simulation()
    repair_facility = Resource(sim, num_repairmen)
    spares = Store{Process}(sim)
    log = NamedTuple[]

    @process start_sim(sim, repair_facility, spares, N, S, rng, F, G, log)
    @process watchdog(sim, max_time)   # корректный вызов

    try
        run(sim)
    catch e
        if e isa StopSimulation
            stop_time = now(sim)
            return (stop_time=stop_time, msg=e.msg, log=log)
        else
            rethrow()
        end
    end
    return (stop_time=now(sim), msg="Finished", log=log)
end