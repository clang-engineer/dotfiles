alias g++="g++ -std=c++17"
alias clang++="clang++ -std=c++17"

# Load secrets (tokens, credentials) from a local-only file
if [ -f "$HOME/.secrets" ]; then
  source "$HOME/.secrets"
fi
