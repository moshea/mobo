module Mobo

  module Android

    class << self
      def exists?
        if Dir.exists?(Mobo.home_dir) and not Dir["#{Mobo.home_dir}/**/tools/android"].empty?
          add_to_path
        end
        Mobo.cmd("which android | grep #{Mobo.home_dir}")
      end

      # as a default, install in ~/.mobo
      def install
        unless File.exists?(Mobo.android_home)
          if SystemCheck.ubuntu?
            Mobo.cmd("curl -o #{path}/android-sdk_r24.3.4-linux.tgz http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz")
            Mobo.cmd("tar -xf #{path}/android-sdk_r24.3.4-linux.tgz -C #{path}")
            Mobo.cmd("mv #{path}/android-sdk-linux #{Mobo.android_home}")
          elsif SystemCheck.osx?
            Mobo.cmd("curl -o #{path}/android-sdk_r24.3.4-macosx.zip http://dl.google.com/android/android-sdk_r24.3.4-macosx.zip")
            Mobo.cmd("unzip #{path}/android-sdk_r24.3.4-macosx.zip -d #{path}")
            Mobo.cmd("mv #{path}/android-sdk-macosx #{Mobo.android_home}")
          else
            Mobo.log.error("Platform not yet supported! Please raise a request with the project to support it.")
          end
        end
        add_to_path
      end
 
      def add_to_path
        unless ENV['PATH'].match(/^#{Mobo.android_home}\/tools/)
          ENV['ANDROID_HOME'] = Mobo.android_home
          ENV['PATH'] = "#{Mobo.android_home}/tools:#{ENV['PATH']}"
          Mobo.log.debug("$PATH set to '#{ENV['PATH']}' to set up android")
        end
      end

      def package_exists?(package)
        Mobo.cmd("android list sdk --extended --no-ui --all | grep '#{package}'")
      end

      def install_package(package)
        Mobo.cmd("echo y | android update sdk --no-ui --all --filter #{package}")
      end

      def haxm_installed?
        if SystemCheck.osx?
          Mobo.cmd("kextstat | grep intel")
        end
      end

      def install_haxm
        if SystemCheck.osx?
          install_package("extra-intel-Hardware_Accelerated_Execution_Manager")
          Mobo.cmd("hdiutil attach #{Mobo.android_home}/extras/intel/Hardware_Accelerated_Execution_Manager/IntelHAXM.dmg")
          Mobo.log.info("Using the sudo command to install haxm - Intel Hardware Accelerated Execution Manager")
          haxm_mount_point = Dir["/Volumes/IntelHAXM*"].first
          Mobo.cmd("sudo installer -pkg #{haxm_mount_point}/*.mpkg -target /")
          Mobo.cmd("hdiutil detach #{haxm_mount_point}")
        else
          raise "Platform not supported for haxm installation yet"
        end
      end
    end

    module Targets
      class << self
        def exists?(target)
          Mobo.cmd("android list targets --compact | grep #{target}")
        end

        def target_details(target)
          output = Mobo.cmd_out("android list targets")
          records = output.split('----------')
          records.each do |record|
            return record if record.match(/#{target}/)
          end
          # return empty string if nothing is found
          return ""
        end

        def abi_package(target, abi)
          prepend = "sys-img"
          "#{prepend}-#{abi}-#{target}"
        end

        def has_abi?(target, abi)
          target_details(target).match(/#{abi}/)
        end

        def has_skin?(target, skin)
          target_details(target).match(/#{skin}/)
        end
      end
    end

    module Avd
      class << self
        def create(device)
          SystemCheck.target_exists?(device["target"])
          SystemCheck.abi_exists?(device["target"], device["abi"])
          SystemCheck.skin_exists?(device["target"], device["skin"])
          emulator_cmd =
            "echo no | android create avd \
            --name #{device["name"]} \
            --target #{device["target"]} \
            --abi #{device["abi"]} \
            --path #{Mobo.avd_home}/#{device["name"]} \
            --force"
          emulator_cmd += " --skin #{device["skin"]}" if device["skin"]
          Mobo.cmd(emulator_cmd)

          raise "Error creating AVD" unless $?.success?
        end
      end
    end

    class Adb
      class << self

        def add_to_path
          if !ENV['PATH'].match(/#{Mobo.android_home}\/platform-tools/)
            ENV['PATH'] = "#{Mobo.android_home}/platform-tools:#{ENV['PATH']}"
          end
          Mobo.log.debug("$PATH set to #{ENV['PATH']}")
        end

        def exists?
          if Dir.exists?(Mobo.home_dir) and not Dir["#{Mobo.android_home}/platform-tools/adb"].empty?
            add_to_path
          end
          Mobo.cmd("which adb | grep #{Mobo.home_dir}")
        end

        def install
          Mobo.cmd("echo yes | android update sdk --all --no-ui --filter platform-tools")
          add_to_path  
          raise "Installing adb failed" unless self.exists?
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
        pid = Process.fork {
          Mobo.cmd(cmd)
          Mobo.log.info("Emulator #{@device["name"]} has stopped")
        }
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
            elsif !running?
              Mobo.log.error("Emulator #{@device["name"]} has stopped")
              break
            elsif booting?
              Mobo.log.info("waiting for #{@device["id"]} to boot...")
              sleep(BOOT_SLEEP)
            else
              # adb does not always recgnoise new emulators booted up, so it needs to be restarted
              Mobo.cmd('adb kill-server')
              sleep(BOOT_SLEEP)
            end
          end

          if running? && booted?
            unlock
          end
        end
      end

      def running?
        begin
          Process.getpgid( @device["pid"] )
          true
        rescue Errno::ESRCH
          false
        end
      end

      def booted?
        bootanim = Mobo.cmd_out("adb -s #{@device["id"]} shell 'getprop init.svc.bootanim'")
        bootanim.match(/stopped/) ? true : false
      end

      def booting?
        bootanim = Mobo.cmd_out("adb -s #{@device["id"]} shell 'getprop init.svc.bootanim'")
        bootanim.match(/running/) ? true : false
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
        puts "#{@device["id"]} \t #{@device["name"]} \t #{booted?} \t #{@device["port"]}"
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