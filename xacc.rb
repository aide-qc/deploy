# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Xacc < Formula
  desc "xacc quantum programming framework"
  homepage "https://github.com/eclipse/xacc"
  url "https://dl.bintray.com/amccaskey/qci-homebrew-bintray/xacc-1.0.0.tar.gz"
  version "1.0.0"
  sha256 "02da8022fcc2afec0945a09b9614c0683bd0d9100faf42c7af18d3d05250603c"
  license "EPL and EDL"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "gcc@10" => :build
  depends_on "python3" => :build
  depends_on "openssl" => :build
  depends_on "curl" => :build

  bottle do
    root_url "https://dl.bintray.com/amccaskey/qci-homebrew-bintray/xacc--1.0.0.mojave.bottle.tar.gz" => :mojave
    sha256 "a55240619050654847cca87c910be5b195daa25e99c63a19af2e87f05177049c" => :mojave
  end

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_CXX_COMPILER=g++-10
      -DCMAKE_C_COMPILER=gcc-10
      -G Ninja
    ]

    xaccpath = buildpath
    mkdir xaccpath/"build" do
       system "cmake", "..", *(std_cmake_args + args)
       system "cmake", "--build", ".", "--target", "install"
    end 
  end

end
