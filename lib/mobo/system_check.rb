module Mobo
  module SystemCheck
    class << self
      def bash_check(cmd, msg, error)
        system(cmd)
        Mobo.log.info("#{msg} : #{$?}")
        raise error unless $?.success?
      end

      def android?
        Android.install unless Android.exists?
      end

      def adb?
        Android::Adb.install unless Android::Adb.exists?
      end

      def target_exists?(target)
        unless Android::Targets.exists?(target)
          Android.install_package(target) if Android.package_exists?(target)
        end
      end

      def abi_exists?(target, abi)
        unless Android::Targets.has_abi?(target, abi)
          package_name = Android::Targets.abi_package(target, abi)
          Android.install_package(package_name) if Android.package_exists?(package_name)
          raise "Cannot install abi: #{abi} for #{target}" unless $?.success?
        end
      end

      def skin_exists?(target, abi)
        Android::Targets.has_skin?(target, abi)
      end

      def device_file_exists?(filename)
        File.exists?(filename)
      end

      def ubuntu?
        RUBY_PLATFORM.match(/linux/) and Mobo.cmd("which apt-get")
      end

      def osx?
        RUBY_PLATFORM.match(/darwin/)
      end
    end
  end
end
