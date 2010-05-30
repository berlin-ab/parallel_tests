class FileGroup

  attr_accessor :root, :number_of_groups, :options

  def initialize(root, number_of_groups, options)
    @root = root  
    @number_of_groups = number_of_groups
    @options = options
  end

  def num
    number_of_groups
  end

  def self.get(root, number_of_groups, options={})
    file_group = FileGroup.new(root, number_of_groups, options)

    if options[:no_sort] == true
      file_group.distribute_tests_in_groups
    else
      file_group.sorted_tests_in_groups
    end
  end

  def sorted_tests_in_groups
    # always add to smallest group
    groups = Array.new(num){{:tests => [], :size => 0}}
    tests_with_sizes.each do |test, size|
      smallest = groups.sort_by{|g| g[:size] }.first
      smallest[:tests] << test
      smallest[:size] += size
    end

    groups.map{|g| g[:tests] }
  end

  def distribute_tests_in_groups
    tests = find_tests
    [].tap do |groups|
      while ! tests.empty?
        (0...num).map do |group_number|
          groups[group_number] ||= []
          groups[group_number] << tests.shift
        end
      end
    end
  end

  private

  def tests_with_sizes
    tests_with_sizes = find_tests_with_sizes
    slow_specs_first(tests_with_sizes)
  end

  def slow_specs_first(tests)
    tests.sort_by{|test, size| size }.reverse
  end

  def find_tests_with_sizes
    tests = find_tests.sort

    #TODO get the real root, atm this only works for complete runs when root point to e.g. real_root/spec
    runtime_file = File.join(root,'..','tmp','parallel_profile.log')
    lines = File.read(runtime_file).split("\n") rescue []

    if lines.size * 1.5 > tests.size
      # use recorded test runtime if we got enough data
      times = Hash.new(1)
      lines.each do |line|
        test, time = line.split(":")
        times[test] = time.to_f
      end
      tests.map { |test| [ test, times[test] ] }
    else
      # use file sizes
      tests.map { |test| [ test, File.stat(test).size ] }
    end
  end

  def find_tests
    if root.is_a?(Array)
      root
    else
      Dir["#{root}**/**/*#{options[:suffix]}"]
    end
  end
end
