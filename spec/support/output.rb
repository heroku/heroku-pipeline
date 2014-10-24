klasses = [Heroku::Command::Pipeline]

klasses.each do |klass|
  klass.class_eval do
    def print(line=nil)
      $command_output << "#{line}"
    end

    def puts(line=nil)
      print("#{line}\n")
    end

    def hputs(line=nil)
      puts(line)
    end

    def error(line=nil)
      puts(line)
    end

    def display(line=nil, opts={})
      puts(line)
    end

    def print_and_flush(chars=nil)
      print(chars)
    end
  end
end

def command_output
  $command_output
end

RSpec.configure do |config|
  config.before(:each) do
    $command_output = ""
  end
end
