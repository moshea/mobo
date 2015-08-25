module Android
  PORT_START = 5600
  BOOT_SLEEP = 5
  BOOT_WAIT_ATTEMPTS = 30
  UNLOCK_KEY_EVENT = 82
  BACK_KEY_EVENT = 4

  class << self
    def exists?
      MOBO.cmd("which android")
    end
  end

  module Targets
    class << self
      def exists?(target)
        MOBO.cmd("android list targets --compact | grep #{target}")
      end

      def has_abi?(target, abi)
        output = MOBO.cmd_out("android list targets")
        records = output.split('----------')
        has_abi = false
        records.each do |record|
          if record.match(/#{target}/) and record.match(/#{abi}/)
            has_abi = true
          end
        end
        return has_abi
      end
    end
  end

  module Avd
    class << self
      def create(device)
        MOBO.cmd("echo no | android create avd \
          --name #{device["name"]} \
          --target #{device["target"]} \
          --abi #{device["abi"]} \
          --force > /dev/null 2>&1")
      end
    end
  end

  class Emulator

    class << self
      attr_accessor :last_port
    end

    def initialize(device)
      @device = device
    end

    def find_open_port
      port = (Emulator.last_port || PORT_START) + 2
      until not MOBO.cmd("netstat -an | grep 127.0.0.1.#{port}")
        port += 2
      end
      Emulator.last_port = port
      return port
    end

    def create_sdcard
      sdcard_name = "#{@device["name"]}_sdcard.img"
      MOBO.cmd("mksdcard -l e #{@device["sdcard_size"]} #{sdcard_name}")
      return sdcard_name
    end

    def create_cache
      @device["name"] + "_cache.img"
    end

    def start
      port = find_open_port
      @device["port"] = port
      @device["id"] = "emulator-#{port}"
      @device["sdcard"] = create_sdcard
      @device["cache"] = create_cache

      cmd ="emulator @#{@device["name"]} \
        -port #{@device["port"]} \
        -sdcard #{@device["sdcard"]} \
        -cache #{@device["cache"]}"
      MOBO.log.debug(cmd)
      pid = Process.spawn(cmd)
      Process.detach(pid)

      @device["pid"] = pid
      return @device
    end

    def unlock_when_booted
      Process.fork do
        BOOT_WAIT_ATTEMPTS.times do |attempt|
          if booted?
            MOBO.log.info("#{@device["id"]} has booted")
            break
          else
            MOBO.log.debug("waiting for #{@device["id"]} to boot...")
            sleep(BOOT_SLEEP)
          end
        end

        if booted?
          unlock
        end
      end
    end

    def booted?
      bootanim = MOBO.cmd_out("adb -s #{@device["id"]} shell 'getprop init.svc.bootanim'")
      if bootanim.match(/stopped/)
        return true
      else
        return false
      end
    end

    def unlock
      # unlock the emulator, so it can be used for UI testing
      # then, pressing back because sometimes a menu appears
      [UNLOCK_KEY_EVENT, BACK_KEY_EVENT].each do |key|
        sleep(BOOT_SLEEP)
        MOBO.cmd("adb -d #{@device["id"]} shell input keyevent #{key}")
      end
    end

    def status
      MOBO.log.info("#{@device["name"]} (#{@device["id"]}) is running: #{booted?}")
    end

    def destroy
      (0..10).each do 
        if booted?
          MOBO.cmd("adb -d #{@device["id"]} emu kill")
          sleep 1
        else
          MOBO.log.info("#{@device["name"]} (#{@device["id"]}) is shutdown")
          break
        end
      end
    end
  end
end