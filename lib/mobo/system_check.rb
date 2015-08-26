module Mobo
  module SystemCheck
    class << self
      def bash_check(cmd, msg)
        Mobo.log.info("#{msg} : #{cmd}")
        cmd
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
        unless Android::Targets.exists?(target)
          Mobo.ask_user("Target #{target} is not installed. Would you like to install it? [Y/n]"){
            SystemSetup.install_target(target)
          }
        end
      end

      def abi_exists?(target, abi)
        unless Android::Targets.has_abi?(target, abi)
          Mobo.ask_user("ABI #{abi} is not installed. Would you like to install it? [Y/n]"){
            SystemSetup.install_abi(target, abi)
          }
        end
      end

      def device_file_exists?(filename)
        File.exists?(filename)
      end
    end
  end
end