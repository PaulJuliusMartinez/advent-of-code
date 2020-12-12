class ZHash < Hash
  def initialize
    super {|h, k| h[k] = 0}
  end
end

# Grid module with following helpers:
#
# G.empty
# G.copy(grid)
# G.in_bounds?(x, y)
# G.points
# G.values(grid)
# G.points_and_values(grid, &block)
# G.puts(grid)
# G.directions
# G.neighbor_points(x, y)
# G.neighbors(grid, x, y)
module G
  # For grid inputs like:
  # .3..###..
  # ...1# ..#
  # ..#  ...#
  # 5...8..#.
  def self.get_grid_input(original_filename)
    strs = get_input_str_arr(original_filename)

    $HEIGHT = strs.length
    $WIDTH = strs[0].length

    grid = self.empty

    strs.each.with_index do |str, y|
      str.chars.each.with_index do |ch, x|
        grid[x][y] = ch
      end
    end

    [grid, strs.length, strs[0].length]
  end

  def self.empty
    Array.new($WIDTH) { Array.new($HEIGHT) }
  end

  def self.copy(grid)
    new_grid = grid.dup
    grid.count.times do |i|
      new_grid[i] = grid[i].dup
    end
  end

  def self.in_bounds?(x, y)
    0 <= x && x < $WIDTH && 0 <= y && y < $HEIGHT
  end

  def self.points
    return @points if @points
    @points = []

    $WIDTH.times do |x|
      $HEIGHT.times do |y|
        @points << [x, y]
      end
    end

    @points
  end

  def self.values(grid)
    self.points.map do |x, y|
      grid[x][y]
    end
  end

  def self.points_and_values(grid, &block)
    self.points.map do |x, y|
      [x, y, grid[x][y]]
    end
  end

  def self.puts(grid)
    $HEIGHT.times do |y|
      $WIDTH.times do |x|
        print grid[x][y]
      end
      print "\n"
    end
  end

  def self.directions
    [
      [-1, -1],
      [-1,  0],
      [-1,  1],
      [ 0, -1],
      [ 0,  1],
      [ 1, -1],
      [ 1,  0],
      [ 1,  1],
    ]
  end

  def self.neighbor_points(x, y)
    neighbor_points = []

    directions.each do |dx, dy|
      next if !in_bounds?(x + dx, x + dy)

      neighbor_points << [x + dx, y + dy]
    end

    neighbor_points
  end

  def self.neighbors(grid, x, y)
    neighbor_points(x, y).map {|nx, ny| grid[nx][ny]}
  end
end
