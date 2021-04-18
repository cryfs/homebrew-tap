class Cryfs < Formula
  desc "Encrypts your files so you can safely store them in Dropbox, iCloud, etc."
  homepage "https://www.cryfs.org"
  license "LGPL-3.0-or-later"
  url "https://github.com/cryfs/cryfs/releases/download/0.10.3/cryfs-0.10.3.tar.xz"
  sha256 "051d8d8e6b3751a088effcc4aedd39061be007c34dc1689a93430735193d979f"

  stable do
    on_macos do
      depends_on :osxfuse
    end
  end

  head do
    url "https://github.com/cryfs/cryfs.git", branch: "develop", shallow: false
    on_macos do
      depends_on :macfuse
    end
  end

  on_linux do
    depends_on "libfuse"
  end

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "libomp"
  depends_on "openssl@1.1"

  def install
    configure_args = [
      "-DBUILD_TESTING=off",
    ]

    if build.head?
      libomp = Formula["libomp"]
      configure_args.concat(
        [
          "-DOpenMP_CXX_FLAGS='-Xpreprocessor -fopenmp -I#{libomp.include}'",
          "-DOpenMP_CXX_LIB_NAMES=omp",
          "-DOpenMP_omp_LIBRARY=#{libomp.lib}/libomp.dylib",
        ],
      )
    end

    system "cmake", ".", *configure_args, *std_cmake_args
    system "make", "install"
  end

  test do
    ENV["CRYFS_FRONTEND"] = "noninteractive"

    # Test showing help page
    assert_match "CryFS", shell_output("#{bin}/cryfs 2>&1", 10)

    # Test mounting a filesystem. This command will ultimately fail because homebrew tests
    # don't have the required permissions to mount fuse filesystems, but before that
    # it should display "Mounting filesystem". If that doesn't happen, there's something
    # wrong. For example there was an ABI incompatibility issue between the crypto++ version
    # the cryfs bottle was compiled with and the crypto++ library installed by homebrew to.
    mkdir "basedir"
    mkdir "mountdir"
    assert_match "Operation not permitted", pipe_output("#{bin}/cryfs -f basedir mountdir 2>&1", "password")
  end
end
