module Mobo

  module Android

    class << self
      def exists?
        if Mobo.cmd("which android")
          return true
        elsif ENV['ANDROID_HOME'] and File.exists?(ENV['ANDROID_HOME'] + '/tools/android')
          add_to_path(ENV['ANDROID_HOME'])
          Mobo.cmd("which android")
        end
      end

      def install
        if SystemCheck.ubuntu?
          Mobo.cmd("curl -O http://dl.google.com/android/android-sdk_r24.3.4-linux.tgz")
          Mobo.cmd("sudo tar -xf android-sdk_r24.3.4-linux.tgz -C /usr/local/")
          Mobo.cmd("sudo chown -R $(whoami) /usr/local/android-sdk-linux")
          add_to_path("/usr/local/android-sdk-linux")
        elsif SystemCheck.osx?
          Mobo.cmd("curl -O http://dl.google.com/android/android-sdk_r24.3.4-macosx.zip")
          Mobo.cmd("sudo unzip android-sdk_r24.3.4-macosx.zip -d /usr/local/")
          Mobo.cmd("sudo chown -R $(whoami) /usr/local/android-sdk-macosx")
          add_to_path("/usr/local/android-sdk-macosx")
        else
          Mobo.log.error("Platform not yet supported! Please raise a request with the project to support it.")
        end
      end
 
      # setting env variables in the bash profile and trying to reload them isn't easy,
      # as the variables are only set in the sub process the bash_profile is executed in
      # so we can set env variables, which take effect here, and also set them in bash_profile
      # for the user to use later on
      def add_to_path(android_home)
        android_tools = android_home + '/tools'
        unless ENV['PATH'].match(/#{android_home}/)
          ENV['ANDROID_HOME'] = android_home
          ENV['PATH'] += ":#{android_tools}"
        end
        unless Mobo.cmd("grep -i ANDROID_HOME ~/.bash*")
          Mobo.cmd("echo 'export ANDROID_HOME=#{android_home}' >> ~/.bash_profile")
          Mobo.cmd("echo 'export PATH=\$PATH:#{android_tools}' >> ~/.bash_profile")
          Mobo.log.info("ANDROID_HOME and PATH env variables have been updated. 
            Start a new terminal session for them to take effect")
        end
        raise "Setting ANDROID_HOME and PATH failed" unless self.exists?
      end

      def package_exists?(package)
        Mobo.cmd("android list sdk --extended --no-ui --all | grep '\"#{package}\"'")
      end

      def install_package(package)
        Mobo.cmd("echo y | android update sdk --no-ui --all --filter #{package} 2>&1 >> /dev/null")
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
          if !ENV['PATH'].match(/platform-tools/)
            ENV['PATH'] += ":#{ENV['ANDROID_HOME']}/platform-tools"
            Mobo.cmd("echo 'export PATH=\$PATH:#{ENV['ANDROID_HOME']}/platform-tools' >> ~/.bash_profile")
            Mobo.log.debug("ENV['PATH'] set to #{ENV['PATH']}")
            Mobo.log.info("PATH env variables has been updated. 
            Start a new terminal session for it to take effect")
          end
        end

        def exists?
          Mobo.cmd("which adb")
        end

        def install
          Mobo.cmd("echo yes | android update sdk --all --no-ui --filter platform-tools 2>&1 >> /dev/null")
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
            else
              Mobo.log.debug("waiting for #{@device["id"]} to boot...")
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