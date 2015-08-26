#!/usr/bin/env ruby
require 'yaml'
require 'pp'
require 'logger'
require_relative 'mobo/android'
require_relative 'mobo/system_check'
require_relative 'mobo/system_setup'

module Mobo
  class << self
    attr_accessor :log, :data, :devices

    def log
      @log || @log = Logger.new(STDOUT)
    end

    def cmd(command)
      log.debug(command)
      system(command)
    end

    def cmd_out(command)
      log.debug(command)
      `#{command}`
    end

    def start_process(cmd)
      pid = Process.spawn(cmd)
      Process.detach(pid)
      pid
    end

    def ask_user(msg, &block)
      puts msg
      ans = STDIN.gets.chomp
      if ans.match(/yes|y|Y/)
        yield
      end
    end

    def devices
      @devices = @devices.nil? ? {} : @devices
    end

    def device_config(device)
      defaults = {
        "name"        => "default",
        "target"      => "android-22",
        "abi"         => "x86_64",
        "height"      => "1200",
        "width"       => "720",
        "sdcard_size" => "20M" }
      defaults.merge(device)
    end

    def load_data(filename)
      raise "Cannot file #{filename}" unless SystemCheck.device_file_exists?(filename)
      Mobo.data = YAML::load_file(filename)
    end

    def system_checks
      SystemCheck.android_home_set
      SystemCheck.android_cmd_exists
    end

    def up(filename)
      system_checks
      load_data(filename)
      # retrive settings for one of each device
      Mobo.data["devices"].each do |device|
        device = device_config(device)
        Mobo.devices[device["name"]] = device
      end

      # build and boot devices
      Mobo.devices.each_pair do |name, device|
        Mobo::Android::Avd.create(device)
        emulator = Android::Emulator.new(device)
        emulator.start
        emulator.unlock_when_booted
      end
      File.open(MOBO_DEVICES_FILE, "w") do |file|
        file.write Mobo.devices.to_yaml
      end
    end

    def status(filename)
      load_data(filename)
      Mobo.data.each_pair do |name, device|
        Mobo::Android::Emulator.new(device).status
      end
    end

    def destroy(filename)
      load_data(filename)
      Mobo.data.each_pair do |name, device|
        Mobo::Android::Emulator.new(device).destroy
      end
    end

  end

end
