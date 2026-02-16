cask "mousestride" do
  version "0.0.4"
  sha256 "e41eb24f1b67a3cc62887a9ffb524970c7d54cba22593e471df95531074e9a83"

  url "https://github.com/trustbe/MouseStride/releases/download/v#{version}/MouseStrideDaemon-v#{version}.zip"
  name "MouseStride"
  desc "Lightweight mouse distance tracker for macOS"
  homepage "https://mousestride.trustbe.com/"

  depends_on macos: ">= :ventura"

  app "MouseStrideDaemon.app"

  zap trash: [
    "~/Library/Preferences/com.mousestride.daemon.plist",
  ]
end
