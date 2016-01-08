defmodule BakeUtils.Cli.Config do
  # only for use with bakefile configs
  defmacro __using__(_opts) do

  end

  def read do
    case File.read(config_path()) do
      {:ok, binary} ->
        case decode_term(binary) do
          {:ok, term} -> term
          {:error, _} -> decode_elixir(binary)
        end
      {:error, _} ->
        []
    end
  end

  def update(config) do
    read()
    |> Keyword.merge(config)
    |> write()
  end

  def write(config) do
    string = encode_term(config)

    path = config_path
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, string)
  end

  defp config_path do
    Path.join(BakeUtils.bake_home(), "bake.config")
  end

  def encode_term(list) do
    list
    |> Enum.map(&[:io_lib.print(&1) | ".\n"])
    |> IO.iodata_to_binary
  end

  def decode_term(string) do
    {:ok, pid} = StringIO.open(string)
    try do
      consult(pid, [])
    after
      StringIO.close(pid)
    end
  end

  defp consult(pid, acc) when is_pid(pid) do
    case :io.read(pid, '') do
      {:ok, term}      -> consult(pid, [term|acc])
      {:error, reason} -> {:error, reason}
      :eof             -> {:ok, Enum.reverse(acc)}
    end
  end

  def decode_elixir(string) do
    {term, _binding} = Code.eval_string(string)
    term
  end
end
