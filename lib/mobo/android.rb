module Mobo
  module Android

    class << self
      def exists?
        Mobo.cmd("which android")
      end
    end

    module Targets
      class << self
        def exists?(target)
          Mobo.cmd("android list targets --compact | grep #{target}")
        end

        def has_abi?(target, abi)
          output = Mobo.cmd_out("android list targets")
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
          Mobo.cmd("echo no | android create avd \
            --name #{device["name"]} \
            --target #{device["target"]} \
            --abi #{device["abi"]} \
            --force > /dev/null 2>&1")
        end
      end
    end

    class Emulator
      PORT_START = 5600
      BOOT_SLEEP = 5
      BOOT_WAIT_ATTEMPTS = 30
      UNLOCK_KEY_EVENT = 82
      BACK_KEY_EVENT = 4

      class << self
        attr_accessor :last_port
      end

      def initialize(device)
        @device = device
      end

      def find_open_port
        port = (Emulator.last_port || PORT_START) + 2
        until not Mobo.cmd("netstat -an | grep 127.0.0.1.#{port}")
          port += 2
        end
        Emulator.last_port = port
        @device["port"] = port
      end

      def create_sdcard
        @device["sdcard"] = "#{@device["name"]}_sdcard.img"
        Mobo.cmd("mksdcard -l e #{@device["sdcard_size"]} #{@device["sdcard"]}")
      end

      def destroy_sdcard
        Mobo.cmd("rm -f #{@device["sdcard"]}")
      end

      def create_cache
        @device["cache"] = @device["name"] + "_cache.img"
      end

      def destroy_cache
        Mobo.cmd("rm -f #{@device["cache"]}")
      end

      def start
        find_open_port
        create_sdcard
        create_cache

        cmd ="emulator @#{@device["name"]} \
          -port #{@device["port"]} \
          -sdcard #{@device["sdcard"]} \
          -cache #{@device["cache"]}"
        Mobo.log.debug(cmd)
        pid = Process.spawn(cmd)
        Process.detach(pid)

        @device["pid"] = pid
        @device["id"] = "emulator-#{@device["port"]}"
        return @device
      end

      def unlock_when_booted
        Process.fork do
          BOOT_WAIT_ATTEMPTS.times do |attempt|
            if booted?
              Mobo.log.info("#{@device["id"]} has booted")
              break
            else
              Mobo.log.debug("waiting for #{@device["id"]} to boot...")
              sleep(BOOT_SLEEP)
            end
          end

          if booted?
            unlock
          end
        end
      end

      def booted?
        bootanim = Mobo.cmd_out("adb -s #{@device["id"]} shell 'getprop init.svc.bootanim'")
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
          Mobo.cmd("adb -s #{@device["id"]} shell input keyevent #{key}")
        end
      end

      def status
        Mobo.log.info("#{@device["name"]} (#{@device["id"]}) is running: #{booted?}")
      end

      def destroy
        (0..10).each do 
          if booted?
            Mobo.cmd("adb -s #{@device["id"]} emu kill")
            sleep 1
          else
            Mobo.log.info("#{@device["name"]} (#{@device["id"]}) is shutdown")
            destroy_cache
            destroy_sdcard
            break
          end
        end
      end
    end
  end
end