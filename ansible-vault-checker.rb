#!/usr/bin/env ruby

require 'yaml'

abort "Exit program. Ansible vault is not installed" if !system("which ansible-vault > /dev/null")
abort "Usage: ansible-vault-checker PASSWORDPATH 'FILEPATH'" if ARGV.length != 2

passwordpath = ARGV[0]
filepath = ARGV[1]
vault_data = {}

Dir.glob(filepath).each do |filename|
  data = YAML.load(File.read(filename))
  puts "Checking vault in #{filename} file"
  data.each do |key, value|
    if value.is_a?(Hash)
      value.each do |k,v|
        next if !v.to_s.include? "VAULT"
        vault_data["#{key}.#{k}"] = v
      end
    elsif value.is_a?(Array)
      value.each_with_index do |v, i|
        next if !v.to_s.include? "VAULT"
        vault_data["#{key}.#{i}"] = v
      end
    else
      next if !value.to_s.include? "VAULT"
      vault_data[key] = value
    end
  end
  vault_data.each do |key, value|
    if !value.start_with? "$ANSIBLE_VAULT;1.1;AES256"
      puts "  - #{key} => value must start with $ANSIBLE_VAULT;1.1;AES256"
      next
    end
    system "echo '#{value}' | ansible-vault decrypt --vault-password-file #{passwordpath} > /dev/null 2>&1"
    result = $?.exitstatus
    puts result == 0 ? "  - #{key} => OK" : "  - #{key} => Failed to decrypt"
  end
end
