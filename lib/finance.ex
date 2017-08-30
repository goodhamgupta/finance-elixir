require IEx;

defmodule Finance do

  defmodule Fraction do
    @moduledoc """
    Module to handle fractions
    """
    defstruct num: 0, den: 1

    def negative(%Fraction{} = fraction) do
      %Fraction{ num: -fraction.num, den: fraction.den }
    end

    def to_float(%Fraction{} = fraction) do
      fraction.num / fraction.den
    end

    @typedoc """
     Rational numbers (num/den)
    """
    @type fraction :: %Fraction{
      num: integer,
      den: non_neg_integer
    }
  end

  @moduledoc """
  Library to calculate XIRR through the Newton Raphson method.
  """

  @type date :: Date.t

  @max_error 1.0e-3
  @days_in_a_year 365

  defp pmap(collection, function) do
    me = self
    collection
    |> Enum.map(fn (element) -> spawn_link fn -> (send me, {self, function.(element)}) end end)
    |> Enum.map(fn (pid) -> receive do {^pid, result} -> result end end)
  end

  def power_of(rate, fraction) when rate < 0 do
    :math.pow(-rate, Fraction.to_float(fraction)) * :math.pow(-1, fraction.num)
  end

  def power_of(rate, fraction) do
    :math.pow(rate, Fraction.to_float(fraction))
  end

  defp xirr_reduction({fraction, value, rate}) do
    value / power_of(1.0 + rate, fraction)
  end

  def dxirr_reduction({fraction, value, rate}) do
    -value * Fraction.to_float(fraction) * power_of(1.0 + rate, Fraction.negative(fraction)) * :math.pow(1.0 + rate, -1)
  end

  @doc """
    iex> d = [{2015, 11, 1}, {2015,10,1}, {2015,6,1}]
    iex> v = [-800_000, -2_200_000, 1_000_000]
    iex> Finance.xirr(d,v)
    { :ok, 21.118359 }
  """
  @spec xirr([date], [number]) :: float
  def xirr(dates, values) when length(dates) != length(values) do
    {:error, "Date and Value collections must have the same size"}
  end

  def xirr(dates, values) do
    dates = Enum.map dates, &(Date.from_erl(&1) |> elem(1))
    min_date = Enum.max(dates)
    {dates, values, dates_values} = compact_flow(Enum.zip(dates, values), min_date)
    cond do
      !verify_flow(values) ->
        {:error, "Values should have at least one positive or negative value."}
      length(dates) - length(values) == 0 && verify_flow(values) ->
        calculate(:xirr, dates_values, [], guess_rate(dates, values),0)
        true -> {:error, "Uncaught error"}
    end
  end # def xirr

  def absolute_rate(0, days), do: {:error, "Rate is 0" }

  def absolute_rate(rate, days) do
    try do
      if days < @days_in_a_year do
        {:ok, (:math.pow(1+rate, days/@days_in_a_year) -1) * 100 |> Float.round(2)}
      else
        {:ok, (rate * 100) |> Float.round(2)}
      end
    rescue _ ->
      {:error, 0.0}
    end
  end

  defp compact_flow(dates_values, min_date) do
    flow = Enum.reduce(dates_values, %{}, &organize_value(&1, &2, min_date))
    {Map.keys(flow), Map.values(flow), Enum.filter(flow, &(elem(&1,1) != 0))}
  end

  defp organize_value(date_value, dict, min_date) do
    {date, value} = date_value
    fraction = %Fraction{
      num: (Date.diff(date, min_date)),
      den: 365.0
    }
    Dict.update(dict, fraction, value, &(value + &1))
  end

  defp verify_flow(values) do
    {min, max} = Enum.min_max(values)
    min < 0 && max > 0
  end

  @spec guess_rate([date], [number]) :: float
  defp guess_rate(dates, values) do
    {min_value, max_value} = Enum.min_max(values)
    period = 1 / (length(dates) - 1)
    multiple = 1 + abs(max_value / min_value)
    rate = :math.pow(multiple, period) - 1
    Float.round(rate, 6)
  end

  defp reduce_date_values(dates_values, rate) do
    list = Dict.to_list(dates_values)
    calculated_xirr = list
      |> pmap(fn (x) ->
        {
          elem(x,0),
          elem(x,1),
          rate
        } end)
      |> pmap(&(xirr_reduction/1))
      |> Enum.sum
      |> Float.round(6)
    calculated_dxirr = list
      |> pmap(fn (x) ->
        {
          elem(x,0),
          elem(x,1),
          rate
        } end)
      |> pmap(&(dxirr_reduction/1))
      |> Enum.sum
      |> Float.round(6)
    {calculated_xirr, calculated_dxirr}
  end

  defp calculate(:xirr, _           , 0.0 , rate, _), do: {:ok, Float.round(rate, 6)}
  defp calculate(:xirr, _           , _   , -1.0, _), do: {:error, "Could not converge"}
  defp calculate(:xirr, _           , _   , _, 300), do: {:error, "I give up"}
  defp calculate(:xirr, dates_values, _   , rate, tries) do
    {xirr, dxirr} = reduce_date_values(dates_values, rate)
    if dxirr < 0.0 do
      new_rate = rate
    else
      new_rate = rate - xirr/dxirr
    end
    diff = Kernel.abs(new_rate - rate)
    if diff < @max_error do
      diff = 0.0
    end
    tries = tries + 1
    calculate(:xirr, dates_values, diff, new_rate, tries)
  end

end # defmodule Finance

