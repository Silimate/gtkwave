class TclTkAT8 < Formula
  desc "Tool Command Language"
  homepage "https://www.tcl-lang.org"
  url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.16/tcl8.6.16-src.tar.gz"
  sha256 "91cb8fa61771c63c262efb553059b7c7ad6757afa5857af6265e4b0bdc2a14a5"
  license "TCL"

  livecheck do
    url :stable
    regex(%r{url=.*?/(?:tcl|tk).?v?(8(?:\.\d+)+)[._-]src\.t}i)
  end

  bottle do
    sha256 arm64_sequoia: "f2bc0545e0e48b4029c35281527224d2dd12deead360a6a982c77e82986c9bfd"
    sha256 arm64_sonoma:  "f3f32a9ace4e639678829daae9c7d8ced421144db16d944438ff5a2285d99e7f"
    sha256 arm64_ventura: "72de6c290a2095906aea8dc034af2b81f88c5efc162adf642c90486c74ef0ab5"
    sha256 sonoma:        "2d568cf0322e7bd4151c7bc1fd714c017a8c037fb238ea0d2f9aed7ac8cb22dd"
    sha256 ventura:       "5cd357c52827c17fc0c648f7134f4cf0bb11f3621a65f2b2a58f2ddd86db2c62"
    sha256 arm64_linux:   "c7af04cbdb5930ea4c7cfdc132f007f1d50e321f11e755226ce72cda01e0cb71"
    sha256 x86_64_linux:  "1208ceb8fe4df5fde9596567c11a8f2e956dacec3af26f6148eee9f6a93d7294"
  end

  keg_only :versioned_formula

  depends_on "openssl@3"

  uses_from_macos "zlib"

  on_linux do
    depends_on "freetype" => :build
    depends_on "pkgconf" => :build
    depends_on "libx11"
    depends_on "libxext"
  end

  resource "critcl" do
    url "https://github.com/andreas-kupries/critcl/archive/refs/tags/3.3.1.tar.gz"
    sha256 "d970a06ae1cdee7854ca1bc571e8b5fe7189788dc5a806bce67e24bbadbe7ae2"
  end

  resource "tcllib" do
    url "https://downloads.sourceforge.net/project/tcllib/tcllib/2.0/tcllib-2.0.tar.xz"
    sha256 "642c2c679c9017ab6fded03324e4ce9b5f4292473b62520e82aacebb63c0ce20"
  end

  resource "tcltls" do
    url "https://core.tcl-lang.org/tcltls/uv/tcltls-1.7.22.tar.gz"
    sha256 "e84e2b7a275ec82c4aaa9d1b1f9786dbe4358c815e917539ffe7f667ff4bc3b4"
  end

  resource "tk" do
    url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.16/tk8.6.16-src.tar.gz"
    sha256 "be9f94d3575d4b3099d84bc3c10de8994df2d7aa405208173c709cc404a7e5fe"

    livecheck do
      formula :parent
    end
  end

  def install
    odie "tk resource needs to be updated" if version != resource("tk").version

    # Remove bundled zlib
    rm_r("compat/zlib")

    args = %W[
      --prefix=#{prefix}
      --includedir=#{include}/tcl-tk
      --mandir=#{man}
      --enable-man-suffix
      --enable-threads
      --enable-64bit
    ]

    ENV["TCL_PACKAGE_PATH"] = "#{HOMEBREW_PREFIX}/lib"
    cd "unix" do
      system "./configure", *args
      system "make"
      system "make", "install"
      system "make", "install-private-headers"
      bin.install_symlink "tclsh#{version.to_f}" => "tclsh"
    end

    # Let tk finds our new tclsh
    ENV.prepend_path "PATH", bin

    resource("tk").stage do
      cd "unix" do
        # SILIMATE: disable corefoundation and aqua, enable X11
        system "./configure", "--disable-corefoundation", "--with-tcl=#{lib}"
        system "make"
        system "make", "install"
        system "make", "install-private-headers"
        bin.install_symlink "wish#{version.to_f}" => "wish"
      end
    end

    resource("critcl").stage do
      system bin/"tclsh", "build.tcl", "install"
    end

    resource("tcllib").stage do
      system "./configure", "--prefix=#{prefix}", "--mandir=#{man}"
      system "make", "install"
      system "make", "critcl"
      cp_r "modules/tcllibc", "#{lib}/"
      ln_s "#{lib}/tcllibc/macosx-x86_64-clang", "#{lib}/tcllibc/macosx-x86_64" if OS.mac?
    end

    resource("tcltls").stage do
      system "./configure", "--with-ssl=openssl",
                            "--with-openssl-dir=#{Formula["openssl@3"].opt_prefix}",
                            "--prefix=#{prefix}",
                            "--mandir=#{man}"
      system "make", "install"
    end

    # Use the sqlite-analyzer formula instead
    # https://github.com/Homebrew/homebrew-core/pull/82698
    rm bin/"sqlite3_analyzer"
  end

  def caveats
    <<~EOS
      The sqlite3_analyzer binary is in the `sqlite-analyzer` formula.
    EOS
  end

  test do
    assert_match "#{HOMEBREW_PREFIX}/lib", pipe_output("#{bin}/tclsh", "puts $auto_path\n")
    assert_equal "honk", pipe_output("#{bin}/tclsh", "puts honk\n").chomp

    # Fails with: no display name and no $DISPLAY environment variable
    return if OS.linux? && ENV["HOMEBREW_GITHUB_ACTIONS"]
  end
end

