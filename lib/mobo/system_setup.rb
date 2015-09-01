module Mobo
  module SystemSetup
    class << self

      def base_libraries
        if SystemCheck.ubuntu?
          Mobo.cmd("sudo apt-get install -y libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1")
        end
      end

    end
  end
end