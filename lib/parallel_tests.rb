require 'parallel'

class ParallelTests
  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip

  # parallel:spec[2,controller] <-> parallel:spec[controller]
  def self.parse_rake_args(args)
    num_processes = Parallel.processor_count
    options = ""
    if args[:count].to_s =~ /^\d*$/ # number or empty
      num_processes = args[:count] unless args[:count].to_s.empty?
      prefix = args[:path_prefix]
      options = args[:options] if args[:options]
    else # something stringy
      prefix = args[:count]
    end
    [num_processes.to_i, prefix.to_s, options]
  end

  # finds all tests and partitions them into groups
  def self.tests_in_groups(root, num, options={})
    options[:suffix] ||= test_suffix
    FileGroup.get(root, num, options)
  end

  def self.run_tests(test_files, process_number, options)
    require_list = test_files.map { |filename| "\"#{filename}\"" }.join(",")
    cmd = "ruby -Itest #{options} -e '[#{require_list}].each {|f| require f }'"
    execute_command(cmd, process_number)
  end

  def self.execute_command(cmd, process_number)
    cmd = "TEST_ENV_NUMBER=#{test_env_number(process_number)} ; export TEST_ENV_NUMBER; #{cmd}"
    f = open("|#{cmd}", 'r')
    all = ''
    while char = f.getc
      char = (char.is_a?(Fixnum) ? char.chr : char) # 1.8 <-> 1.9
      all << char
      print char
      STDOUT.flush
    end
    all
  end

  def self.find_results(test_output)
    test_output.split("\n").map {|line|
      line = line.gsub(/\.|F|\*/,'')
      next unless line_is_result?(line)
      line
    }.compact
  end

  def self.failed?(results)
    return true if results.empty?
    !! results.detect{|line| line_is_failure?(line)}
  end

  def self.test_env_number(process_number)
    process_number == 0 ? '' : process_number + 1
  end

  protected

  def self.line_is_result?(line)
    line =~ /\d+ failure/
  end

  def self.line_is_failure?(line)
    line =~ /(\d{2,}|[1-9]) (failure|error)/
  end

  def self.test_suffix
    "_test.rb"
  end
end
