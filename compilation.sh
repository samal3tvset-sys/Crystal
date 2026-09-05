clang -arch arm64 -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
      -framework IOKit -framework Foundation \
      -o apex_jailbreak apex_jailbreak.c