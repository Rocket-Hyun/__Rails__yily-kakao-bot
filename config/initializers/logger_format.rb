class ActiveSupport::Logger::SimpleFormatter
  def call(severity, time, progname, msg)

    formatted_time = time.strftime("%Y-%m-%d %H:%M:%S")

    "[#{formatted_time}] #{severity} -- : #{msg.strip}\n"
  end
end
