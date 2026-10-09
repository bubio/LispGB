(in-package #:lispgb)

(defmacro define-sdl-functions (&body definitions)
  "C の署名を一か所に並べ、SBCL の FFI 宣言を生成する。"
  `(progn
     ,@(loop for (c-name lisp-name result . arguments) in definitions
             for foreign-name = #+(or darwin win32) (intern (format nil "%~A" lisp-name))
                                #-(or darwin win32) lisp-name
             append
             `((sb-alien:define-alien-routine (,c-name ,foreign-name) ,result ,@arguments)
               ,@#+(or darwin win32)
               `((defun ,lisp-name ,(mapcar #'first arguments)
                   ;; Cocoa / Windows の描画処理では、C 呼び出し中だけ例外を抑制する。
                   (sb-int:with-float-traps-masked (:invalid :divide-by-zero :overflow)
                     (,foreign-name ,@(mapcar #'first arguments)))))
               #-(or darwin win32) nil))))
(define-sdl-functions
  ("SDL_SetMainReady" sdl-set-main-ready sb-alien:void)
  ("SDL_Init" sdl-init sb-alien:int (flags sb-alien:unsigned-int))
  ("SDL_Quit" sdl-quit sb-alien:void)
  ("SDL_GetError" sdl-get-error sb-alien:c-string)
  ("SDL_CreateWindow" sdl-create-window sb-alien:system-area-pointer
    (title sb-alien:c-string) (x sb-alien:int) (y sb-alien:int) (w sb-alien:int) (h sb-alien:int) (flags sb-alien:unsigned-int))
  ("SDL_DestroyWindow" sdl-destroy-window sb-alien:void (window sb-alien:system-area-pointer))
  ("SDL_SetWindowFullscreen" sdl-set-window-fullscreen sb-alien:int (window sb-alien:system-area-pointer) (flags sb-alien:unsigned-int))
  ("SDL_CreateRenderer" sdl-create-renderer sb-alien:system-area-pointer (window sb-alien:system-area-pointer) (index sb-alien:int) (flags sb-alien:unsigned-int))
  ("SDL_DestroyRenderer" sdl-destroy-renderer sb-alien:void (renderer sb-alien:system-area-pointer))
  ("SDL_RenderSetLogicalSize" sdl-render-set-logical-size sb-alien:int (renderer sb-alien:system-area-pointer) (w sb-alien:int) (h sb-alien:int))
  ("SDL_SetHint" sdl-set-hint sb-alien:int (name sb-alien:c-string) (value sb-alien:c-string))
  ("SDL_CreateTexture" sdl-create-texture sb-alien:system-area-pointer (renderer sb-alien:system-area-pointer) (format sb-alien:unsigned-int) (access sb-alien:int) (w sb-alien:int) (h sb-alien:int))
  ("SDL_DestroyTexture" sdl-destroy-texture sb-alien:void (texture sb-alien:system-area-pointer))
  ("SDL_UpdateTexture" sdl-update-texture sb-alien:int (texture sb-alien:system-area-pointer) (rect sb-alien:system-area-pointer) (pixels sb-alien:system-area-pointer) (pitch sb-alien:int))
  ("SDL_RenderClear" sdl-render-clear sb-alien:int (renderer sb-alien:system-area-pointer))
  ("SDL_RenderCopy" sdl-render-copy sb-alien:int (renderer sb-alien:system-area-pointer) (texture sb-alien:system-area-pointer) (src sb-alien:system-area-pointer) (dst sb-alien:system-area-pointer))
  ("SDL_RenderPresent" sdl-render-present sb-alien:void (renderer sb-alien:system-area-pointer))
  ("SDL_PollEvent" sdl-poll-event sb-alien:int (event sb-alien:system-area-pointer))
  ("SDL_OpenAudioDevice" sdl-open-audio-device sb-alien:unsigned-int (device sb-alien:system-area-pointer) (capture sb-alien:int) (desired sb-alien:system-area-pointer) (obtained sb-alien:system-area-pointer) (changes sb-alien:int))
  ("SDL_PauseAudioDevice" sdl-pause-audio-device sb-alien:void (device sb-alien:unsigned-int) (pause sb-alien:int))
  ("SDL_QueueAudio" sdl-queue-audio sb-alien:int (device sb-alien:unsigned-int) (data sb-alien:system-area-pointer) (size sb-alien:unsigned-int))
  ("SDL_GetQueuedAudioSize" sdl-get-queued-audio-size sb-alien:unsigned-int (device sb-alien:unsigned-int))
  ("SDL_ClearQueuedAudio" sdl-clear-queued-audio sb-alien:void (device sb-alien:unsigned-int))
  ("SDL_CloseAudioDevice" sdl-close-audio-device sb-alien:void (device sb-alien:unsigned-int))
  ("SDL_GetPerformanceCounter" sdl-get-performance-counter sb-alien:unsigned-long-long)
  ("SDL_GetPerformanceFrequency" sdl-get-performance-frequency sb-alien:unsigned-long-long)
  ("SDL_Delay" sdl-delay sb-alien:void (ms sb-alien:unsigned-int)))

(defun null-pointer () (sb-sys:int-sap 0))
(defun null-pointer-p (pointer) (zerop (sb-sys:sap-int pointer)))
(defun check-sdl (result)
  (when (if (typep result 'sb-sys:system-area-pointer) (null-pointer-p result) (minusp result))
    (error "SDL2: ~A" (sdl-get-error)))
  result)
(defun sdl-library-candidates (&optional
                               (platform (cond ((uiop:os-windows-p) :windows)
                                               ((uiop:os-macosx-p) :macos) (t :linux)))
                               (runtime sb-ext:*runtime-pathname*))
  "実行ファイル横の DLL と OS ごとの標準保存先を返す。"
  (case platform
    (:windows (list (namestring (merge-pathnames "SDL2.dll"
                                 (uiop:pathname-directory-pathname runtime))) "SDL2.dll"))
    (:macos '("libSDL2.dylib" "/opt/homebrew/lib/libSDL2.dylib"
              "/usr/local/lib/libSDL2.dylib" "/opt/local/lib/libSDL2.dylib"
              "/Library/Frameworks/SDL2.framework/SDL2"))
    (otherwise '("libSDL2-2.0.so.0"))))

(defun load-sdl2 ()
  ;; SDL は通常実行時だけ読み込む。保存するコアイメージには含めない。
  (dolist (library (sdl-library-candidates))
    (handler-case
        (progn
          (sb-alien:load-shared-object library :dont-save t)
          ;; Lisp のエントリポイントでは SDL_main を経由しない。
          (sdl-set-main-ready)
          (return-from load-sdl2 t))
      (error () nil)))
  (error #+win32 "SDL2 が見つかりません。x64 版 SDL2.dll を lispgb.exe と同じ場所に置いてください。"
         #+darwin "SDL2 が見つかりません。brew install sdl2 または sudo port install libsdl2 で導入してください。"
         #-(or win32 darwin) "SDL2 が見つかりません。sudo apt install libsdl2-2.0-0 で導入してください。"))

;; SDL_events.h と SDL_keyboard.h の定義に従う。arm64 で C の offsetof とも照合済み。
;; SDL_Event は56バイト、type=0、key.keysym.sym=20、key.repeat=13。
(defconstant +sdl-event-size+ 56)
(defconstant +sdl-key-offset+ 20)
(defconstant +sdl-repeat-offset+ 13)
