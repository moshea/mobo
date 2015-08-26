module Mobo
  module SystemCheck
    class << self
      def bash_check(cmd, msg, error)
        system(cmd)
        Mobo.log.info("#{msg} : #{$?}")
        raise error unless $?.success?
      end

      def android_home_set
        unless ENV['ANDROID_HOME']
          SystemSetup.install_android
        end
      end

      def android_cmd_exists
        unless Android.exists?
          Android.set_android_home
        end
      end

      def target_exists(target)
        unless Android::Targets.exists?(target)
          SystemSetup.install_target(target)
        end
      end

      def abi_exists?(target, abi)
        unless Android::Targets.has_abi?(target, abi)
          SystemSetup.install_abi(target, abi)
        end
      end

      def device_file_exists?(filename)
        File.exists?(filename)
      end
    end
  end
end
