module Mobo
  module SystemCheck
    class << self
      def bash_check(cmd, msg)
        if cmd
          Mobo.log.info(msg + ": YES")
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