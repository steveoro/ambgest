# encoding: utf-8


=begin

= ConsoleLogger

  - Goggles framework vers.:  4.00.807
  - author: Steve A.

  Simple/fake logger class, outputs directly any string using puts.
  Mainly used by test methods to simulate the controller +logger+ instance.

=end
class ConsoleLogger

  # Debug-level output
  def debug( txt )
    puts txt
  end

  # Info-level output, without carriage return
  def infoc( txt )
    putc txt
  end

  # Info-level output
  def info( txt )
    puts txt
  end

  # Warning-level output
  def warn( txt )
    puts txt
  end

  # Error-level output
  def error( txt )
    puts txt
  end
end
# -----------------------------------------------------------------------------