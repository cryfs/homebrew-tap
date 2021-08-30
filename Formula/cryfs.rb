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
    url "https://github.com/cryfs/cryfs/releases/download/0.11.0/cryfs-0.11.0.tar.xz"
    sha256 "5583f84f3fcbd4bdbdcc9bfe4bb10971b2fca80a67b539b340556b5de482b737"
  end

  bottle do
    root_url "https://github.com/cryfs/homebrew-tap/releases/download/cryfs-0.11.0"
    sha256 cellar: :any,                 catalina:     "de16cddda3fe2bab46d3495d16018b24251a040638684c47087b55e3c3a948de"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "6521308b819610ca64362886aec31b26c086af8d317a4bbe16e305d3818ef436"
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
