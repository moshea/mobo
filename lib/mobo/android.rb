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

  module Emulator
    class << self

      def find_open_port
        port = PORT_START
        until not MOBO.cmd("netstat -an | grep 127.0.0.1.#{port}")
          port += 2
        end
        return port
      end

      def create_sdcard(device)
        sdcard_name = "#{device["name"]}_sdcard.img"
        MOBO.cmd("mksdcard -l e #{device["sdcard_size"]} #{sdcard_name}")
        return sdcard_name
      end

      def create_cache(device)
        device["name"] + "_cache.img"
      end

      def start(device)
        port = find_open_port
        MOBO.devices[device["name"]]["port"] = port
        MOBO.devices[device["name"]]["id"] = "emulator-#{port}"
        MOBO.devices[device["name"]]["sdcard"] = create_sdcard(device)
        MOBO.devices[device["name"]]["cache"] = create_cache(device)
        cmd ="emulator @#{device["name"]} \
          -port #{MOBO.devices[device["name"]]["port"]} \
          -sdcard #{MOBO.devices[device["name"]]["sdcard"]} \
          -cache #{MOBO.devices[device["name"]]["cache"]}"
        pid = Process.spawn(cmd)
        Process.detach(pid)

        MOBO.devices[device["name"]]["pid"] = pid
      end

      def unlock(device)
        device = MOBO.devices[device["name"]]
        boot_successful = false
        Process.fork do
          BOOT_WAIT_ATTEMPTS.times do |attempt|
            bootanim = MOBO.cmd_out("adb -s #{device["id"]} shell 'getprop init.svc.bootanim'")
            if bootanim.match(/stopped/)
              boot_successful = true
              MOBO.log.debug("#{device["id"]} has booted")
              break
            else
              MOBO.log.debug("waiting for #{device["id"]} to boot...")
              sleep(BOOT_SLEEP)
            end
          end
          if boot_successful
            # unlock the emulator, so it can be used for UI testing
            # then, pressing back because sometimes a menu appears
            [UNLOCK_KEY_EVENT, BACK_KEY_EVENT].each do |key|
              sleep(BOOT_SLEEP)
              MOBO.cmd("adb -s #{device["id"]} shell input keyevent #{key}")
            end
          end
        end
      end
    end
  end
end