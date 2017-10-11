defmodule FinanceTest do
  use ExUnit.Case, async: true
  doctest Finance

  def multiply(integer) do
    integer * 2
  end

  test "xirr/2 positive and negative flow in the same day" do
    d = [{2014,04,15},{2014,04,15},{2014,10,19}]
    v = [-10000.0,10000.0,500.0]
    assert Finance.xirr(d,v) == {:error, "Values should have at least one positive or negative value."}
  end

  test "xirr/2 impossible returns on investments" do
    d = [{2015, 11, 1}, {2015,10,1}, {2015,6,1}]
    v = [-800_000, -2_200_000, 1_000_000]
    assert Finance.xirr(d,v) == {:error, "Xirr value is too large"}
  end


  test "xirr/2 bad investment" do
    d = [{1985, 1, 1}, {1990, 1, 1}, {1995, 1, 1}]
    v = [1000, -600, -200]
    assert Finance.xirr(d,v) == {:ok, -0.034592}
  end


  test "xirr/2 repeated cashflow" do
    v = [1000.0,
      2000.0,
      -2000.0,
      -4000.0]
    d = [{2011,12,07},
      {2011,12,07},
      {2013,05,21},
      {2013,05,21}]

    assert Finance.xirr(d,v) == {:error, "Xirr value is too large"}
  end


  test "xirr/2 ok investment" do
    v = [1000.0, -600.0, -6000.0]
    d = [{1985,1,1},{1990,1,1},{1995,1,1}]

    assert Finance.xirr(d,v) == {:ok, 0.225683}
  end

  test "xirr/2 long investment" do
    v = [105187.06, 816709.66, 479069.684, 937309.708, 88622.661, 100000.0, 80000.0, 403627.95, 508117.9, 789706.87, -88622.661,
    -789706.871,-688117.9, -403627.95, 403627.95, 789706.871, 88622.661, 688117.9, 45129.14, 26472.08, 51793.2, 126605.59,
    278532.29, 99284.1, 58238.57, 113945.03, 405137.88, -405137.88, 165738.23, -165738.23, 144413.24, 84710.65, -84710.65, -144413.24]

    d = [{2011,12,07},{2011,12,07},{2011,12,07},{2012,01,18},{2012,07,03},{2012,07,03},{2012,07,19},{2012,07,23},{2012,07,23},{2012,07,23},
    {2012,09,11},{2012,09,11},{2012,09,11},{2012,09,11},{2012,09,12},{2012,09,12},{2012,09,12},{2012,09,12},{2013,03,11},{2013,03,11},
    {2013,03,11},{2013,03,11},{2013,03,28},{2013,03,28},{2013,03,28},{2013,03,28},{2013,05,21},{2013,05,21},{2013,05,21},{2013,05,21},
    {2013,05,21},{2013,05,21},{2013,05,21},{2013,05,21}]

    assert Finance.xirr(d,v) == {:ok, 0.08006}
  end

  test "xirr/2 wrong size" do
    d = [
      {2014,04,15},
      {2014,10,19}
    ]
    v = [
      -10000.0,
      305.6,
      500.0
    ]
    assert Finance.xirr(d,v) == {:error, "Date and Value collections must have the same size"}
  end

  test "xirr/2 wrong values" do
    d = [
      {2014,04,15},
      {2014,10,19}
    ]
    v = [
      305.6,
      500.0
    ]

    assert Finance.xirr(d,v) == {:error, "Values should have at least one positive or negative value."}
  end

  test "xirr/2 not a bad investment" do
    d = [{2008,2,5},{2008,7,5},{2009,1,5}]
    v = [2750.0,-1000.0,-2000.0]

    assert Finance.xirr(d,v) == {:ok, 0.123631}
  end

  test "xirr/2 fail when the rate is too large" do
    d = [{2017,1,1}, {2017,1,5}]
    v = [10000, -11000]
    assert Finance.xirr(d,v) == {:error, "Unable to converge"}
  end
end
