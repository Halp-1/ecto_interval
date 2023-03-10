if Code.ensure_loaded?(Postgrex) do
  defmodule EctoInterval do
    @moduledoc """
    This implements Interval support for Postgrex that used to be in Ecto but no longer is.
    """

    @type interval_map :: %{
            optional(:years) => integer() | String.t(),
            optional(:months) => integer() | String.t(),
            optional(:weeks) => integer() | String.t(),
            optional(:days) => integer() | String.t(),
            optional(:secs) => integer() | String.t()
          }

    if macro_exported?(Ecto.Type, :__using__, 1) do
      use Ecto.Type
    else
      @behaviour Ecto.Type
    end

    @impl true
    def type, do: Postgrex.Interval

    @impl true
    @spec cast(interval_map()) :: :error | {:ok, interval_map()}
    def cast(interval) when is_map(interval) do
      atom_interval =
        Map.new(interval, fn {k, v} ->
          if is_atom(k) do
            {k, v}
          else
            {String.to_atom(k), v}
          end
        end)

      years = Map.get(atom_interval, :years, 0)
      months = Map.get(atom_interval, :months, 0)
      weeks = Map.get(atom_interval, :weeks, 0)
      days = Map.get(atom_interval, :days, 0)
      secs = Map.get(atom_interval, :secs, 0)

      do_cast(years, months, weeks, days, secs)
    end

    def cast(_) do
      :error
    end

    defp do_cast(years, months, weeks, days, secs) do
      try do
        years = to_integer(years)
        months = to_integer(months)
        weeks = to_integer(weeks)
        days = to_integer(days)
        secs = to_integer(secs)

        {:ok, %{years: years, months: months, weeks: weeks, days: days, secs: secs}}
      rescue
        _ -> :error
      end
    end

    defp to_integer(arg) when is_binary(arg) do
      String.to_integer(arg)
    end

    defp to_integer(arg) when is_integer(arg) do
      arg
    end

    @impl true
    def load(%{months: months, days: days, weeks: weeks, secs: secs}) do
      {:ok,
       %{years: div(months, 12), months: rem(months, 12), weeks: weeks, days: days, secs: secs}}
    end

    @impl true
    def dump(%{years: years, months: months, weeks: weeks, days: days, secs: secs}) do
      days = weeks * 7 + days
      {:ok, %Postgrex.Interval{months: months + years * 12, days: days, secs: secs}}
    end

    def dump(%{
          "years" => years,
          "months" => months,
          "weeks" => weeks,
          "days" => days,
          "secs" => secs
        }) do
      days = weeks * 7 + days
      {:ok, %Postgrex.Interval{months: months + years * 12, days: days, secs: secs}}
    end

    def dump(_) do
      :error
    end
  end

  defimpl String.Chars, for: [Postgrex.Interval] do
    import Kernel, except: [to_string: 1]

    def to_string(%{:months => months, :days => days, :secs => secs}) do
      m =
        if months === 0 do
          ""
        else
          " #{months} months"
        end

      d =
        if days === 0 do
          ""
        else
          " #{days} days"
        end

      s =
        if secs === 0 do
          ""
        else
          " #{secs} seconds"
        end

      if months === 0 and days === 0 and secs === 0 do
        "<None>"
      else
        "Every#{m}#{d}#{s}"
      end
    end
  end

  defimpl Inspect, for: [Postgrex.Interval] do
    def inspect(inv, _opts) do
      inspect(Map.from_struct(inv))
    end
  end

  if Code.ensure_loaded?(Phoenix.HTML.Safe) do
    defimpl Phoenix.HTML.Safe, for: [Postgrex.Interval] do
      def to_iodata(inv) do
        to_string(inv)
      end
    end
  end
end
