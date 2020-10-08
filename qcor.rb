# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Qcor < Formula
  desc "quantum-classical c++ compiler"
  homepage "https://github.com/ornl-qci/qcor"
  url "https://github.com/ornl-qci/qcor/tarball/master"
  version "1.0.0"
  sha256 "23592862c224eeb11b9129e72688ff20b3b0e2271f1a19788048c9c52fd8a562"
  license "BSD-3"

  depends_on "cmake" => :build
  depends_on "llvm-csp" => :build
  depends_on "xacc" => :build
  depends_on "gcc@10" => :build

  bottle do
    root_url "https://dl.bintray.com/amccaskey/qci-homebrew-bintray"
    sha256 "692550ca239f36ffbf06956cd8e573b94b498a5b5c3d7f0557474dcefdc50141" => :mojave
  end

  def install
    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_CXX_COMPILER=/usr/local/opt/gcc/bin/g++-10
      -DCMAKE_C_COMPILER=/usr/local/opt/gcc/bin/gcc-10
      -DXACC_DIR=/usr/local/opt/xacc
      -DQCOR_EXTRA_HEADERS="/usr/local/opt/gcc/include/c++/10.2.0;/usr/local/opt/gcc/include/c++/10.2.0/x86_64-apple-darwin18"
      -DGCC_STDCXX_PATH=/usr/local/opt/gcc/lib/gcc/10
      -DLLVM_ROOT=/usr/local/opt/llvm-csp 
      -G Ninja
    ]

    qcorpath = buildpath
    mkdir qcorpath/"build" do
       system "cmake", "..", *(std_cmake_args+args)
       system "cmake", "--build", ".", "--target", "install"
       bin.install #{bin}/qcor
    end 
  end
end
