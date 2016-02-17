require "open3"

class Cryfs < Formula
  desc "CryFS encrypts your files, so you can safely store them anywhere. It works well together with cloud services like Dropbox, iCloud, OneDrive and others."
  homepage "https://www.cryfs.org"
  url "https://github.com/cryfs/cryfs.git", tag: "0.9.2"
  head "https://github.com/cryfs/cryfs.git", branch: "develop"

  depends_on "cmake" => :build
  depends_on :python => :build
  depends_on "openssl"
  depends_on "boost"
  depends_on "cryptopp"
  depends_on :osxfuse

  needs :cxx11

  def install
    mkdir("build") do
      #TODO Homebrew is passing in CXXFLAGS to cmake which disable -O3. Can I make it build with -O3?
      system "cmake", "..", "-DBUILD_TESTING=off", *std_cmake_args
      system "make", "install", "prefix=#{prefix}"
    end
  end

  test do
    Open3.popen3("#{bin}/cryfs") do |stdin, stdout, _|
      stdin.close
      assert_match "CryFS", stdout.read
    end
  end
end
