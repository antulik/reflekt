class Reflection

  # Keys.
  TIME    = "t"
  INPUT   = "i"
  OUTPUT  = "o"
  TYPE    = "T"
  COUNT   = "C"
  VALUE   = "V"
  STATUS  = "s"
  MESSAGE = "m"
  # Values.
  PASS    = "p"
  FAIL    = "f"

  attr_accessor :clone

  def initialize(execution, method, ruler)

    @execution = execution
    @method = method
    @ruler = ruler

    # Clone the execution's object.
    @clone = execution.object.clone
    @clone_id = nil

    # Result.
    @status = nil
    @time = Time.now.to_i
    @input = []
    @output = nil

  end

  ##
  # Reflect on a method.
  #
  # Creates a shadow execution stack.
  #
  # @param method - The name of the method.
  # @param *args - The method arguments.
  #
  # @return - A reflection hash.
  ##
  def reflect(*args)

    # Create deviated arguments.
    args.each do |arg|
      case arg
      when Integer
        @input << rand(999)
      else
        @input << arg
      end
    end

    # Action method with new arguments.
    begin
      # Validate input with controls.
      unless @ruler.nil?
        if @ruler.validate_input(@execution.caller_class, @method, @input)
          @status = PASS
        else
          @status = FAIL
        end
      end
      # Run reflection.
      @output = @clone.send(@method, *@input)
    # When fail.
    rescue StandardError => message
      @status = FAIL
      @message = message
    # When pass.
    else
      # Validate output with controls.
      unless @ruler.nil?
        if @ruler.validate_output(@execution.caller_class, @method, @output)
          @status = PASS
        else
          @status = FAIL
        end
        return
      end
      @status = PASS
    end

  end

  def result()
    # Build reflection.
    reflection = {
      TIME => @time,
      STATUS => @status,
      INPUT => normalize_input(@input),
      OUTPUT => normalize_output(@output),
      MESSAGE => @message
    }
  end

  ##
  # Normalize inputs.
  #
  # @param args - The actual inputs.
  # @return - A generic inputs representation.
  ##
  def normalize_input(args)
    inputs = []
    args.each do |arg|
      input = {
        TYPE => arg.class.to_s,
        VALUE => normalize_value(arg)
      }
      if (arg.class == Array)
        input[COUNT] = arg.count
      end
      inputs << input
    end
    inputs
  end

  ##
  # Normalize output.
  #
  # @param input - The actual output.
  # @return - A generic output representation.
  ##
  def normalize_output(input)

    output = {
      TYPE => input.class.to_s,
      VALUE => normalize_value(input)
    }

    if (input.class == Array || input.class == Hash)
      output[COUNT] = input.count
    elsif (input.class == TrueClass || input.class == FalseClass)
      output[TYPE] = :Boolean
    end

    return output

  end

  def normalize_value(value)

    unless value.nil?
      value = value.to_s.gsub(/\r?\n/, " ").to_s
      if value.length >= 30
        value = value[0, value.rindex(/\s/,30)].rstrip() + '...'
      end
    end

    return value

  end

end
