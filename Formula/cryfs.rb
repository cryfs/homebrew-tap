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

class OsxfuseRequirement < Requirement
  fatal true

  satisfy(build_env: false) { self.class.binary_osxfuse_installed? }

  def self.binary_osxfuse_installed?
    File.exist?("/usr/local/include/osxfuse/fuse.h") &&
      !File.symlink?("/usr/local/include/osxfuse")
  end

  def message
    "osxfuse is required to build cryfs. Please run `brew install --cask osxfuse` first."
  end
end

class Cryfs < Formula
  desc "Encrypts your files so you can safely store them in Dropbox, iCloud, etc."
  homepage "https://www.cryfs.org"
  license "LGPL-3.0-or-later"

  stable do
    url "https://github.com/cryfs/cryfs/releases/download/0.10.3/cryfs-0.10.3.tar.xz"
    sha256 "051d8d8e6b3751a088effcc4aedd39061be007c34dc1689a93430735193d979f"
    on_macos do
      depends_on OsxfuseRequirement
    end
    depends_on "boost"
  end

  bottle do
    root_url "https://github.com/cryfs/homebrew-tap/releases/download/cryfs-0.10.3"
    sha256 cellar: :any, catalina: "abab942c49d1609b9cce8652bd2c681ccb4b9eb0449baaa3ad21d1dfcddc4bdc"
  end

  head do
    url "https://github.com/cryfs/cryfs.git", branch: "develop", shallow: false
    on_macos do
      depends_on MacfuseRequirement
    end
    depends_on "conan" => :build
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "libomp"
  depends_on "openssl@1.1"

  on_linux do
    depends_on "libfuse"
  end

  def install
    configure_args = [
      "-GNinja",
      "-DBUILD_TESTING=off",
    ]

    system "cmake", ".", *configure_args, *std_cmake_args
    system "ninja", "install"
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
    assert_match "Operation not permitted", pipe_output("#{bin}/cryfs -f basedir mountdir 2>&1", "password")
  end
end
