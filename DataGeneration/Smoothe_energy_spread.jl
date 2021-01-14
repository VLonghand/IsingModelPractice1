using CSV
using DataFrames
# using plotting
n = 4
N = 65536

df_energies = CSV.read("Data/All4x4_Energies_with_flat_exampels.csv", DataFrame)



# via map function
# check first element in row if COND true then export and edit looking_for dict
# COND = element belongs to set p

num_of_exmaples_per = 20 # the number of examples for each energy

# make looking_for dict
looking_for = Dict()
for i in -32:4:32
    looking_for["$i"] = num_of_exmaples_per #first entry "-32" => 12
end

df_energies_even_spread = DataFrame()

# make function to map
function row_checker_expoter(row)
    # check the first against dict and export
    local energy = convert(Int, row[1])
    if looking_for["$energy"] > 0 
        push!(df_energies_even_spread, row)
        looking_for["$energy"] -= 1
    end
# could make faster, by it stop when number of exaples is num_of_exmaples_per*(n*n-2)-4
# -2 for empty 28, -28 and -4 for only 2 32 and 2 -32 examples
end

map(row_checker_expoter, eachrow(df_energies))

# only 2 exmpeles for each of -32, 32; fix that
while looking_for["32"] + looking_for["-32"] > 0 
    map(row_checker_expoter, eachrow(df_energies_even_spread))
end

print(looking_for)

print(num_of_exmaples_per*(n*n-2))

df_energies_even_spread |> CSV.write("Data/Energies_even_spread_$num_of_exmaples_per.csv")
