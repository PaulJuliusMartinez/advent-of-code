class ZHash < Hash
  def initialize
    super {|h, k| h[k] = 0}
  end
end
