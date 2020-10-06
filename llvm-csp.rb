# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class LlvmCsp < Formula
  desc "clang syntax handler"
  homepage "https://github.com/hfinkel/llvm-project-csp"
  url "https://github.com/hfinkel/llvm-project-csp/tarball/csplugin"
  version "1.0.0"
  sha256 "2df409617c290ddec870be5c84e21b6c7413f9531e778e6f8555762a951248cf"
  license "Apache 2.0"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "gcc@10" => :build

  bottle do
    root_url "https://github.com/ORNL-QCI/llvm-project-csp/releases/download/1.0.0/" => :mojave
    cellar :any
    sha256 "99bcaa48f7f05f92f108763e434d5ffa06b2e732e3aa098d21205f4a8c250667" => :mojave
  end

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DLLVM_BUILD_LLVM_DYLIB=ON
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_TARGETS_TO_BUILD=X86
      -DLLVM_ENABLE_DUMP=ON
      -DLLVM_ENABLE_PROJECTS=clang
      -DCMAKE_CXX_COMPILER=g++-10
      -DCMAKE_C_COMPILER=gcc-10
      -G Ninja
    ]

    llvmpath = buildpath
    mkdir llvmpath/"build" do
       system "cmake", "../llvm", *(std_cmake_args + args)
       system "cmake", "--build", ".", "--target", "install"
    end 
  end

end
