$INTCODE_ID = 0

class Intcode
  OPCODE_TO_NUM_PARAMS = {
    1 => 3, # Add
    2 => 3, # Multiply
    3 => 1, # Input
    4 => 1, # Output
    5 => 2, # Jump-if-true
    6 => 2, # Jump-if-false
    7 => 3, # Less than
    8 => 3, # Equals
  }

  POSITION_MODE = 0
  IMMEDIATE_MODE = 1

  DONE = :done
  AWAITING_INPUT = :input
  OUTPUT = :output

  attr_reader :id

  def initialize(mem, id = nil)
    @mem = mem.dup
    @ip = 0

    @id = id || ($INTCODE_ID += 1)
    @halted = false
  end

  def run(inputs = [])
    fail 'Intcode has halted' if @halted

    loop do
      op = @mem[@ip]

      opcode = op % 100
      mode1 = (op / 100) % 10
      mode2 = (op / 1000) % 10
      mode3 = (op / 10000) % 10

      if opcode == 99
        @halted = true
        return {state: DONE}
      end

      param1 = @mem[@ip + 1]
      param2 = @mem[@ip + 2]
      param3 = @mem[@ip + 3]

      value1 = value_for_param(param1, mode1) if param1
      value2 = value_for_param(param2, mode2) if param2
      value3 = value_for_param(param3, mode3) if param3

      @ip += 1 + OPCODE_TO_NUM_PARAMS[opcode]

      if opcode == 1
        @mem[param3] = value1 + value2
      elsif opcode == 2
        @mem[param3] = value1 * value2
      elsif opcode == 3
        if inputs.any?
          @mem[param1] = inputs.shift
        else
          # Rewind ip, so we can just call .run again.
          @ip -= 1 + OPCODE_TO_NUM_PARAMS[opcode]
          return {state: AWAITING_INPUT}
        end
      elsif opcode == 4
        return {state: OUTPUT, value: value1}
      elsif opcode == 5
        @ip = value2 if value1 != 0
      elsif opcode == 6
        @ip = value2 if value1 == 0
      elsif opcode == 7
        @mem[param3] = value1 < value2 ? 1 : 0
      elsif opcode == 8
        @mem[param3] = value1 == value2 ? 1 : 0
      end
    end
  end

  def value_for_param(param, mode)
    if mode == POSITION_MODE
      @mem[param]
    elsif mode == IMMEDIATE_MODE
      param
    end
  end
end
