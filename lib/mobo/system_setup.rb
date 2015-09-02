module Mobo
  module SystemSetup
    class << self

      def base_libraries
        if SystemCheck.ubuntu?
          Mobo.cmd("sudo apt-get install -y libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1")
        end

        if Android.supports_haxm and not Android.haxm_installed?
          Android.install_haxm
        end
      end

      def mobo
        Mobo.home_dir = File.expand_path("~/.mobo")
        Mobo.log.info("Using #{Mobo.home_dir} as home directory. Android will be installed here")
        Dir.mkdir(Mobo.home_dir) unless File.exists?(Mobo.home_dir)
        Dir.mkdir(Mobo.avd_home) unless File.exists?(Mobo.avd_home)
      end

    end
  end
end