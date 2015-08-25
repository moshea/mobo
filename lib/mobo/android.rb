module Android
  PORT_START = 5600

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
        MOBO.devices[device["name"]]["port"] = find_open_port
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
    end
  end
end