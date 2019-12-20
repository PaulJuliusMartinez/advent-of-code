$DATA_STRS = DATA.readlines.map {|str| str[0..-2]}

# Run ./decXX.rb <test_name> to run code on input in file decXX.<test_name>.
#
# For input like:
# a
# b
# c
def get_input_str_arr(original_filename)
  if ARGV[0]
    File.readlines("#{original_filename.chomp('rb')}#{ARGV[0]}").map {|str| str[0..-2]}
  else
    $DATA_STRS
  end
end

# For input like:
# here-is-some-text
def get_input_str(original_filename)
  get_input_str_arr(original_filename)[0]
end

# For input like:
# 1,2,3
def get_single_line_input_int_arr(original_filename, separator: ',')
  get_input_str(original_filename).split(separator).map(&:to_i)
end

# For input like:
# 1
# 2
# 3
def get_multi_line_input_int_arr(original_filename)
  get_input_str_arr(original_filename).map(&:to_i)
end
