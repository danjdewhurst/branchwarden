class Branchwarden < Formula
  desc "Git branch hygiene and policy enforcement CLI"
  homepage "https://github.com/danjdewhurst/branchwarden"
  url "https://github.com/danjdewhurst/branchwarden/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "d37ee6fe39d4aa4cc9e95114f75d1c17a5d1a23c962fe04e50b4b44985453512"
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
