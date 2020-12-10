# Days using GB: 8

class GB # (GameBoy)
  attr_accessor :acc

  def initialize(instructions)
    # instructions
    @insts = instructions
    # accumulator
    @acc = 0
    # instruction pointer
    @ip = 0


    @infinite_looped = false
    @needs_input = false
  end

  def needs_input?
    @needs_input
  end

  def done?
    @ip == @insts.count
  end

  def infinite_looped?
    @infinted_looped
  end

  def self.parse_instructions(instructions)
    instructions.map do |str|
      opp, arg = str.split(" ")
      arg = arg.to_i
      [opp, arg]
    end
  end

  ACC = 'acc'
  JMP = 'jmp'
  NOP = 'nop'

  def run
    executed_insts = Set.new

    loop do
      if executed_insts.include?(@ip)
        @infinite_looped = true
        break
      end

      break if @ip == @insts.count

      op, arg = @insts[@ip]
      executed_insts << @ip

      case op
      when ACC
        @acc += arg
        @ip += 1
      when JMP
        @ip += arg
      when NOP
        @ip += 1
      end
    end
  end
end
