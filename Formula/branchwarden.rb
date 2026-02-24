class Branchwarden < Formula
  desc "Git branch hygiene and policy enforcement CLI"
  homepage "https://github.com/danjdewhurst/branchwarden"
  url "https://github.com/danjdewhurst/branchwarden/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "94dd4f8b81ffc5ea3da108c74711f220ac5311192f46b62d01901dc31e27d674"
  license "MIT"

  def install
    bin.install "branchwarden"
    bash_completion.install "completions/branchwarden.bash" => "branchwarden"
    zsh_completion.install "completions/_branchwarden"
    fish_completion.install "completions/branchwarden.fish"
  end

  test do
    assert_match "branchwarden - git branch hygiene CLI", shell_output("#{bin}/branchwarden --help")
  end
end
