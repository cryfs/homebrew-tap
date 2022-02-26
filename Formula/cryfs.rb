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
  license "LGPL-3.0-or-later"

  stable do
    url "https://github.com/cryfs/cryfs/releases/download/0.11.2/cryfs-0.11.2.tar.xz"
    sha256 "951ef565d37521df5586b00ed898f1cb76188739c27b9db866cc91ca14fdf1bd"
  end

  bottle do
    root_url "https://github.com/cryfs/homebrew-tap/releases/download/cryfs-0.11.2"
    sha256 cellar: :any,                 big_sur:      "f4c2194d79645e9d382defdefa069db2b0ed4e2fd5ddcc008d437abcb46b73cc"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "f0a7d3f34cc673fb6eb9f2f55e525f49fe7c1fab12be72472a29f0c7b40a491e"
  end

  head do
    url "https://github.com/cryfs/cryfs.git", branch: "develop", shallow: false
  end

  depends_on "cmake" => :build
  depends_on "conan" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "curl"
  depends_on "libomp"
  depends_on "openssl@1.1"

  on_macos do
    depends_on MacfuseRequirement
  end
  on_linux do
    depends_on "libfuse@2"
  end

  def install
    configure_args = [
      "-GNinja",
      "-DBUILD_TESTING=off",
    ]

    # macFUSE puts pkg-config into /usr/local/lib/pkgconfig, which is not included in
    # homebrew's default PKG_CONFIG_PATH. We need to tell pkg-config about this path for our build
    with_env "PKG_CONFIG_PATH" => ENV["PKG_CONFIG_PATH"] + ":/usr/local/lib/pkgconfig" do
      system "cmake", ".", *configure_args, *std_cmake_args
    end
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
