# DiffusionGemma 対応の llama.cpp。
#
# DiffusionGemma (google/diffusiongemma-26B-A4B-it, 2026-06-10 リリース) は
# テキスト拡散モデルで、標準の llama.cpp / ollama では動かない。実行には
# llama-diffusion-cli を追加する未マージの PR が必要:
#   https://github.com/ggml-org/llama.cpp/pull/24423
#   (danielhanchen フォーク, branch: diffusion-visual-updates)
#
# nixpkgs の llama-cpp(CPU ビルド) を override し、フォークのソースに差し替えて
# examples を有効化することで llama-diffusion-cli / *-server を $out/bin に入れる。
#
# 使い方 (GGUF は Unsloth 配布。-hf で自動 DL され ~/.cache/llama.cpp に保存):
#   llama-diffusion-cli \
#     -hf unsloth/diffusiongemma-26B-A4B-it-GGUF:Q4_K_M \
#     -ngl 0 -cnv -n 2048
#   ※ Q4_K_M は ~18GB RAM 推奨。GTX 1650 (VRAM 4GB) では -ngl 0 で CPU 推論。
{
  llama-cpp,
  fetchFromGitHub,
  lib,
}:
llama-cpp.overrideAttrs (old: {
  pname = "llama-diffusion";
  version = "0-unstable-2026-06-pr24423";

  src = fetchFromGitHub {
    owner = "danielhanchen";
    repo = "llama.cpp";
    rev = "4a6735f1cf0594250958bcc839267696c7b998a4";
    sha256 = "0f41xlxqszkrnqw37ljy0q8zmrbllkvch55q8qkwvz9ma285yh6p";
  };

  # 元の src は leaveDotGit + postFetch で COMMIT ファイルを作り preConfigure で
  # それを読む。差し替えた src には COMMIT が無いので preConfigure を上書きする。
  preConfigure = ''
    prependToVar cmakeFlags "-DLLAMA_BUILD_COMMIT:STRING=4a6735f"
  '';

  # diffusion CLI / server は examples/ 配下にあり LLAMA_BUILD_EXAMPLES で
  # ゲートされている。末尾に追記して ON へ上書きする (後勝ち)。
  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    "-DLLAMA_BUILD_EXAMPLES=ON"
  ];

  meta = (old.meta or { }) // {
    description = "llama.cpp build with DiffusionGemma (llama-diffusion-cli) support";
    mainProgram = "llama-diffusion-cli";
  };
})
