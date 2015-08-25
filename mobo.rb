#!/usr/bin/env ruby
require 'yaml'
require 'pp'
require 'logger'
require_relative 'lib/mobo/android'

module MOBO
  class << self
    attr_accessor :log, :data, :devices

    def log
      @log || @log = Logger.new(STDOUT)
    end

    def cmd(command)
      log.info(command)
      system(command)
    end

    def cmd_out(command)
      log.info(command)
      `#{command}`
    end

    def start_process(cmd)
      pid = Process.spawn(cmd)
        Process.detach(pid)
        pid
      end

    def devices
      @devices = @devices.nil? ? {} : @devices
    end

    def device_config(device)
      defaults = {
        "name"        => "default",
        "target"      => "android-22",
        "abi"         => "default/x86_64",
        "height"      => "1200",
        "width"       => "720",
        "sdcard_size" => "20M" }
      defaults.merge(device)
    end

    def process_yaml
      # retrive settings for one of each device
      MOBO.data["devices"].each do |device|
        device = device_config(device)
        MOBO.devices[device["name"]] = device
      end

      # build and boot devices
      MOBO.devices.each_pair do |name, device|
        Android::Avd.create(device)
        Android::Emulator.start(device)
        Android::Emulator.unlock(device)
      end
    end
  end

  module SystemCheck
    class << self
      def bash_check(cmd, msg)
        if cmd
          MOBO.log.debug(msg + ": YES")
        else
          raise failure_msg + ": NO"
          exit 1
        end
      end

      def android_home_set
        bash_check(!ENV['ANDROID_HOME'].nil?,
          "ANDROID_HOME is set")
      end

      def android_cmd_exists
        bash_check(Android.exists?, 
          "android set in PATH")
      end

      def target_exists(target)
        bash_check(Android::Targets.exists?(target), 
          "target #{target} exists")
      end

      def abi_exists(target, abi)
        Android::Targets.has_abi?(target, abi)
      end 
    end
  end

end
