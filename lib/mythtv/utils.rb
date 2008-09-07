module MythTV
  
  # Raised when we get a response that isn't what we expect
  class CommunicationError < RuntimeError
  end
  
  # Raised when we have a protocol version mismatch
  class ProcolError < RuntimeError
  end
  
  # Raised when a method is passed incomplete initialisation information
  class ArgumentError < RuntimeError
  end
  
  class Utils
    def self.format_time(time_value, format = :nondelimited)
      # We can be given a time value as a Time object, or a Unix timestamp
      case time_value
      when Time
        time = time_value
      when Bignum
        time = Time.at(time_value)
      when String
        time = Time.at(time_value.to_i)
      else
        raise MythTV::ArgumentError, "format_time must be given a valid time representation. Was given a #{time_value.class} with value #{time_value}"
      end

      case format
      when :nondelimited
        time.strftime("%Y%m%d%H%M%S")
      when :delimited
        time.strftime("%Y-%m-%dT%H:%M:%S")
      else
        raise MythTV::ArgumentError, "format_time must be given a valid format"
      end
    end

  end # end Utils
end # end MythTV