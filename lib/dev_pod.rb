
$projects = %w(tt_app_ios tt_app_ios2 tt_app_ios3 tt_app_ios4)
$pod_txts = %w(pods1.txt pods2.txt pods3.txt pods4.txt)

$work_dir = "/Users/nami/git"

class PodInfo
  attr_reader :name
  attr_reader :file_name
  attr_reader :ext_name
  attr_accessor :version
  attr_accessor :git_path
  attr_accessor :git_branch

  def initialize(ext_name)
    @ext_name = ext_name
    if ext_name =~ /(\w+):(\d+)/
      @name = $1
      @file_name = $1 << $2
    else
      @name = ext_name
      @file_name = ext_name
    end
  end
end

def get_options
  $command = ARGV[0]
  $project_index = ARGV[1].to_i - 1
  $branch = ARGV[2]
  if $project_index == -1
    pwd = Dir.pwd
    3.downto(0) do |i|
      if pwd.include?($projects[i])
        $project_index = i
        break
      end
    end
  end
  if $command == 'install'
    install_pod
  elsif $command == 'push'
    fix_podfile
  elsif $command == 'auto'
    install_pod
    puts
    puts
    fix_podfile
  elsif $command == 'edit'
    open_pod_txt
  else
    puts("Usage: #{$PROGRAM_NAME} install [index [branch]]")
    puts("       #{$PROGRAM_NAME} push [index]")
    puts("       #{$PROGRAM_NAME} auto [index [branch]]")
    puts("       #{$PROGRAM_NAME} edit [index]")
  end
end

def read_pod_version(pod_file_path, pod_name)
  file = File.new(pod_file_path, "r")
  file.each_line do |line|
    if line =~ /pod\w*\s\'#{pod_name}\'\s*,\s*'([\w\.]+)'/
      return $1
    end
  end
  puts("pod not found!")
  nil
end

def checkout_pod_branch(pod_infos)
  puts("Get pods info")
  Dir.chdir("#{$work_dir}/#{$projects[$project_index]}/Article")
  pod_infos.each do |pod_info|
    pod_info.version = read_pod_version('Podfile', pod_info.name)
    puts("#{pod_info.ext_name}: version: #{pod_info.version}")
  end
  unless $branch
    $branch = `git symbolic-ref --short -q HEAD`.strip
    puts("branch: #{$branch}")
  end
  pod_infos.each do |pod_info|
    Dir.chdir("#{$work_dir}/#{pod_info.file_name}")
    pod_current_branch = `git symbolic-ref --short -q HEAD`.strip
    pod_current_status = `git status -s`.strip
    if pod_current_branch != 'master' || !pod_current_status.empty?
      puts("#{pod_info.ext_name} not clean!")
    else
      `git checkout toutiao_#{pod_info.version}`
      `git checkout -b #{$branch}`
      puts("#{pod_info.ext_name} success!")
    end
  end
end

def update_podfile(pod_infos)
  puts("Get pods info")
  pod_infos.each do |pod_info|
    Dir.chdir("#{$work_dir}/#{pod_info.file_name}")
    pod_info.git_path = `git remote get-url origin`.strip
    pod_info.git_branch = `git symbolic-ref --short -q HEAD`.strip
    puts("#{pod_info.ext_name}: git: #{pod_info.git_path} branch: #{pod_info.git_branch}")
  end
  puts("Get pods info end.")
  Dir.chdir("#{$work_dir}/#{$projects[$project_index]}/Article")
  text = File.read('Podfile')
  pod_infos.each do |pod_info|
    text.gsub!(/(pod_source|pod_binary|pod)\s+\'#{pod_info.name}\',\s+\'[\w\.]+\'/, "pod_source '#{pod_info.name}', git:'#{pod_info.git_path}', branch:'#{pod_info.git_branch}'")
  end
  File.write('Podfile', text)
  puts("Update podfile end.")
end

def fix_podfile
  puts("Start push.")
  file = File.new("#{$work_dir}/PodfilePatchs/#{$pod_txts[$project_index]}", 'r')
  pod_infos = Array.new
  file.each_line do |line|
    line.strip!
    unless line.start_with?('//') || line.start_with?('#') || line.empty?
      pod_info = PodInfo.new(line)
      pod_infos << pod_info
    end
  end
  update_podfile(pod_infos)
end

def install_pod
  puts("Start install.")
  file = File.new("#{$work_dir}/PodfilePatchs/#{$pod_txts[$project_index]}", 'r')
  pod_infos = Array.new
  file.each_line do |line|
    line.strip!
    unless line.start_with?('//') || line.start_with?('#') || line.empty?
      pod_info = PodInfo.new(line)
      pod_infos << pod_info
    end
  end
  checkout_pod_branch(pod_infos)
end

def open_pod_txt
  `subl #{$work_dir}/PodfilePatchs/#{$pod_txts[$project_index]}`
end