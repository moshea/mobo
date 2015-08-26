module Mobo
  module SystemSetup
    class << self

      def install_android
        Android.install
        Android.set_android_home
      end

      def install_target(target)
        Android.install_package(target) if Android.package_exists?(target)
        raise "Cannot install target: #{target}" unless $?.success?
      end

      def install_abi(target, abi)
        full_abi_name = "sys-img-#{abi}-#{target}"
        Android.install_package(full_abi_name) if Android.package_exists?(full_abi_name)
        raise "Cannot install abi: #{full_abi_name}" unless $?.success?
      end

    end
  end
end