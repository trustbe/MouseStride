cask "mousestride" do
  version "0.0.2"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/trustbe/MouseStride/releases/download/v#{version}/MouseStrideDaemon-v#{version}.zip"
  name "MouseStride"
  desc "Lightweight mouse distance tracker for macOS"
  homepage "https://trustbe.github.io/MouseStride/"

  depends_on macos: ">= :ventura"

  app "MouseStrideDaemon.app"

  zap trash: [
    "~/Library/Preferences/com.mousestride.daemon.plist",
  ]
end
