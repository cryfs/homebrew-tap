class MacfuseRequirement < Requirement
  fatal true

  satisfy(build_env: false) { self.class.binary_macfuse_installed? }

  def self.binary_macfuse_installed?
    File.exist?("/usr/local/include/fuse/fuse.h") &&
      !File.symlink?("/usr/local/include/fuse")
  end

  def message
    "macFUSE is required to build cryfs. Please run `brew install --cask macfuse` first."
  end
end

class Cryfs < Formula
  desc "Encrypts your files so you can safely store them in Dropbox, iCloud, etc."
  homepage "https://www.cryfs.org"
  url "https://github.com/cryfs/cryfs/releases/download/1.0.1/cryfs-1.0.1.tar.xz"
  sha256 "7ad4cc45e1060431991538d3e671ec11285896c0d7a24880290945ef3ca248ed"
  license "LGPL-3.0-or-later"
  head "https://github.com/cryfs/cryfs.git", branch: "develop", shallow: false

  # Don't manually update anything in the `bottle` section, it will be updated by CI
  bottle do
    root_url "https://github.com/cryfs/homebrew-tap/releases/download/cryfs-1.0.1"
    sha256 cellar: :any,                 arm64_sonoma: "e24c787f84a240037bf3afadb716c271b0d9230ab75e4243c57b3c914429fa78"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "e0a6e77b5e11249cec888e96ab5a39a279a529ed55b3b6d5ddb4c64c9a935849"
  end

  depends_on "cmake" => :build
  depends_on "conan@2" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "libomp"

  on_macos do
    depends_on MacfuseRequirement
  end
  on_linux do
    depends_on "libfuse@2"
  end

  def install
    # macFUSE puts pkg-config into /usr/local/lib/pkgconfig, which is not included in
    # homebrew's default PKG_CONFIG_PATH. We need to tell pkg-config about this path for our build
    pkg_config_path = ENV["PKG_CONFIG_PATH"]
    if pkg_config_path.nil?
      pkg_config_path = "/usr/local/lib/pkgconfig"
    else
      pkg_config_path += ":/usr/local/lib/pkgconfig"
    end
    with_env "PKG_CONFIG_PATH" => pkg_config_path do
      system "conan", "profile", "detect"
      system "conan", "build", ".",
        "--build=missing",
        "-s", "build_type=RelWithDebInfo",
        "-o", "&:build_tests=False"
      chdir "build/RelWithDebInfo" do
        system "cmake", "--install", ".", "--prefix", prefix
      end
    end
  end

  test do
    ENV["CRYFS_FRONTEND"] = "noninteractive"

    # Test showing help page
    assert_match "CryFS", shell_output("#{bin}/cryfs 2>&1", 10)

    # Test mounting a filesystem. This command will ultimately fail with "Operation not permitted"
    # because homebrew tests don't have the required permissions to mount fuse filesystems.
    # So this doesn't really test CryFS functionality, but at least it tests that CryFS tries to
    # access something that homebrew tests don't have access to...
    # This is still helpful. For example there was an ABI incompatibility issue between the crypto++
    # version the cryfs bottle was compiled with and the crypto++ library installed by homebrew to,
    # this test catches such things.
    mkdir "basedir"
    mkdir "mountdir"

    if OS.mac?
      assert_match "Operation not permitted", pipe_output("#{bin}/cryfs -f basedir mountdir 2>&1", "password")
    elsif OS.linux?
      assert_match "CryFS Version", pipe_output("#{bin}/cryfs -f basedir mountdir 2>&1", "password")
    end
  end
end
