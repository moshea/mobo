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

    def device_config(name, lab=nil)
      defaults = {
        "lab"         => lab,
        "name"        => "default",
        "target"      => "android-22",
        "abi"         => "default/x86_64",
        "height"      => "1200",
        "width"       => "720",
        "sdcard_size" => "20M" }
      device = MOBO.data["devices"].select{ |d| d["name"] == name }.first
      device["name"] = lab ? "#{lab["name"]}_#{device["name"]}" : device["name"]
      defaults.merge(device)
    end

    def create_device(device)
      SystemCheck.target_exists(device["target"])
      SystemCheck.abi_exists(device["target"], device["abi"])

      MOBO.log.debug("booting device '#{device["name"]}'")
      Android::Avd.create(device)
    end

    def boot_device(device)
      Android::Emulator.start(device)
    end

    def process_yaml
      if MOBO.data["lab"].empty?
        # retrive settings for one of each device if no labs are defined
        MOBO.data["devices"].each do |device|
          device = device_config(device["name"])
          MOBO.devices[device["name"]] = device
        end
      else
        # iterate and build labs based on the devices specified in lab config
        # iterate the devices listed
        # match the name of the device with the devices listed
        MOBO.data["lab"].each do |lab|
          lab["devices"].each do |lab_device|
            device = device_config(lab_device["name"], lab)
            MOBO.devices[device["name"]] = device
          end
        end

        # build and boot devices
        MOBO.devices.each_pair do |name, device|
          create_device(device)
          boot_device(device)
        end
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
