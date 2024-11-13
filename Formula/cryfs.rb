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
  url "https://github.com/cryfs/cryfs/releases/download/1.0.0/cryfs-1.0.0.tar.xz"
  sha256 "b4652c0816a233a54269a11f72b179b570872105da94f1c9c2b4f08c39031469"
  license "LGPL-3.0-or-later"
  head "https://github.com/cryfs/cryfs.git", branch: "develop", shallow: false

  bottle do
    root_url "https://github.com/cryfs/homebrew-tap/releases/download/cryfs-0.11.4"
    sha256 cellar: :any,                 monterey:     "4186f9a13b6461adc640c4842b9164f833f8b63534bded21b050245579a50173"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "5edece59320ba4423ea91505425b7933c535a7be7ae2c10fc177c3c903ba571c"
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
