require 'benchmark'

Benchmark.bm(1000) do |x|
    x.report("First:") { `iex -S mix run -e "Finance.calculate_xirr"` }
    x.report("Second:") { `iex -S mix run -e "Finance.calculate_xirr"` }
    x.report("Third:") { `iex -S mix run -e "Finance.calculate_xirr"` }
end

