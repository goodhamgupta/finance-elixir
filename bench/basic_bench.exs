defmodule BasicBench do
  use Benchfella

  bench "calculate xirr" do
    d = [{2012, 5, 29}, {2015, 5, 29}]
    v = [-2.0e4, 4.0e4]
    Finance.xirr(d,v)
  end
end
