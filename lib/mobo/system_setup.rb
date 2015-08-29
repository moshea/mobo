module Mobo
  module SystemSetup
    class << self

      def base_libraries
        #if ubuntu
        if(Mobo.cmd("which apt-get"))
          Mobo.cmd("sudo apt-get install -y libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1")
        end
      end

      def install_android
        Android.install
      end

      def install_target(target)
        Android.install_package(target) if Android.package_exists?(target)
        raise "Cannot install target: #{target}" unless $?.success?
      end

      def install_abi(target, abi)
        package_name = Android::Targets.abi_package(target, abi)
        Android.install_package(package_name) if Android.package_exists?(package_name)
        raise "Cannot install abi: #{abi} for #{target}" unless $?.success?
      end

      def install_adb
        Android::Adb.install unless Android::Adb.exists?
      end
    end
  end
end