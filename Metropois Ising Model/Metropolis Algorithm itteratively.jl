
#include("FunsForSquareInsingModel.jl")
using Distributed
@everywhere using Plots, Statistics, CSV, DataFrames

# Funtions to be moved to a module to use @everywhere --------------
@everywhere function H(spin_grid)
    acc = 0
    n = 4
    J = 1
    #spin_grid = reshape(spin_vec, (n,n))


    for i = 1:n, j = 1:n
        local i_1 = i-1
        local j_1 = j-1
        if i == 1
            i_1 = n
        end
        if j == 1
            j_1 = n
        end
        acc += spin_grid[i,j]*spin_grid[i_1,j]*(-J)
        acc += spin_grid[i,j]*spin_grid[i,j_1]*(-J)
    end
    return acc
end
@everywhere function M(spin_grid)
    return sum(spin_grid)
end
@everywhere function w(T, σ_trial, σ_0)
    β = 1/T
    return exp(-β*(H(σ_trial) - H(σ_0)))
end
#-------------------------------------------------------------------


# global varaible declaration -------------------------------------- 
begin
    # @everywhere σ_00 = [-1 1 -1 1
    #         1 -1 1 -1
    #         -1 1 -1 1
    #         1 -1 1 -1]
    # @everywhere σ_trial = similar(σ_00)
    # @everywhere Ms = []
    # @everywhere Ts = []
    # Mmeans = []
    @everywhere dfMmeans = DataFrame()
end
#-------------------------------------------------------------------

# main functions of the algorithm ----------------------------------
@everywhere function algotithm(T,σ_00, σ_trial )
    @inbounds for i in 1:1_000
        push!(Ms, sum(σ_00))

        σ_trial = copy(σ_00)
        σ_trial[rand(1:16)] *= -1

        r = rand()

        if r <= w(T, σ_trial, σ_00) 
            global σ_00 = σ_trial
        end    
    end
end

@everywhere function itter_over_Temps()
    local Mmeans = []
    local σ_00 = [-1 1 -1 1
                   1 -1 1 -1
                   -1 1 -1 1
                   1 -1 1 -1]
    local σ_trial = similar(σ_00)
    local Ts = []

    for T in 0:0.01:5
        algotithm(T, σ_00, σ_trial)
        push!(Mmeans, abs(mean(Ms)/16)) # /16 to 'normalize' or average magnetization over all spins
        push!(Ts, T)
        global Ms = []
    end

    return Mmeans # saves as collumns
end
#-------------------------------------------------------------------

# multiprocessing troubleshooting tools ----------------------------
# using Distributed
# addprocs(16)
# print(nprocs())
# print(nworkers())
#-------------------------------------------------------------------

function itter_via_workers()
    for i in workers()
        #print(i)
        r = remotecall_fetch(itter_over_Temps, WorkerPool(workers()))
        j = Symbol(i-2)
        dfMmeans.j = r
    end
end

itter_via_workers()

dfMmeans |> CSV.write("Metropois Ising Model/Phase Transition Data/Mmeans.csv")
#^^^^^^^^ to add more data run csv.write("file", append=true) or concat

# itter_over_Temps()

# PLots, but you knew that already ---------------------------------
# plot(Ts, Mmeans, label=M)
# xlabel!("Temperature")
# ylabel!("Magnetization")
# title!("Magnetization vs Temperature")  
#-------------------------------------------------------------------
