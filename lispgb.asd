;;; 外部の Lisp ライブラリを必要としないシステム定義。
(asdf:defsystem "lispgb/core"
  :description "Game Boy Color エミュレーションコア"
  :version "0.1.0"
  :license "MIT"
  :pathname "src/core/"
  :serial t
  :components (
    (:file "package")
    (:file "types")
    (:file "cartridge")
    (:file "mbc")
    (:file "timer")
    (:file "joypad")
    (:file "ppu")
    (:file "apu")
    (:file "bus")
    (:file "cpu")
    (:file "opcodes")
    (:file "machine")
    (:file "savestate")))

(asdf:defsystem "lispgb"
  :description "LispGB の SDL2 フロントエンド"
  :version "0.1.0"
  :depends-on ("lispgb/core")
  :pathname "src/app/"
  :serial t
  :components (
    (:file "package")
    (:file "sdl2")
    (:file "paths")
    (:file "fileio")
    (:file "cli")
    (:file "config")
    (:file "recent")
    (:file "bmp")
    (:file "video")
    (:file "audio")
    (:file "input")
    (:file "main")))

(asdf:defsystem "lispgb/tests"
  :description "LispGB の単体テストと ROM テスト"
  :depends-on ("lispgb/core" "lispgb")
  :pathname "tests/"
  :serial t
  :components ((:file "framework")
               (:file "unit/cartridge-test")
               (:file "suites/harness")
               (:file "unit/bus-test")
               (:file "unit/cpu-test")
               (:file "unit/timer-test")
               (:file "unit/mbc-test")
               (:file "suites/blargg")
               (:file "unit/ppu-test")
               (:file "suites/mooneye")
               (:file "suites/acid2")
               (:file "unit/apu-test")
               (:file "unit/cgb-test")
               (:file "unit/joypad-test")
               (:file "unit/savestate-test")))
