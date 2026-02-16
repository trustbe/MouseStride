cask "mousestride" do
  version "0.0.3"
  sha256 "d3f91b4ec935415ac0c4a307008390360d50f69e2f1a985d390c30b10972021a"

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
