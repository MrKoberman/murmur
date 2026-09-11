package main

import (
	"log/slog"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/getlantern/systray"
)

var (
	logger    = slog.New(slog.NewTextHandler(os.Stderr, nil))
	recordCmd *exec.Cmd
	stopTimer *time.Timer
)

func main() {
	systray.Run(onReady, onExit)
}

func onReady() {
	if icon, err := os.ReadFile("icon2.png"); err == nil {
		systray.SetIcon(icon)
	}

	start := systray.AddMenuItem("Start Recording", "Start")
	stop := systray.AddMenuItem("Stop Recording", "Stop")
	stop.Disable()
	systray.AddSeparator()
	quit := systray.AddMenuItem("Quit", "Exit")

	go func() {
		for {
			select {
			case <-start.ClickedCh:
				logger.Info("Start recording triggered")
				start.Disable()
				stop.Enable()
				recordCmd = exec.Command("arecord", "-f", "cd", "input.wav")
				recordCmd.Start()

				// 60s limit
				stopTimer = time.AfterFunc(60*time.Second, func() {
					stop.ClickedCh <- struct{}{}
				})
			case <-stop.ClickedCh:
				if stopTimer != nil {
					stopTimer.Stop()
				}
				stop.Disable()
				start.Enable()
				if recordCmd != nil && recordCmd.Process != nil {
					recordCmd.Process.Kill()
					recordCmd.Wait()
				}
				transcribe()
			case <-quit.ClickedCh:
				systray.Quit()
				return
			}
		}
	}()
}

func onExit() {}

func transcribe() {
	logger.Info("Invoking whisper")
	modelPath := os.Getenv("MURMUR_MODEL_PATH")
	if modelPath == "" {
		modelPath = "ggml-base.bin"
	}

	out, err := exec.Command("whisper-cli", "-m", modelPath, "-f", "input.wav", "--no-timestamps").Output()
	if err != nil {
		logger.Error("Transcribe failed", "error", err)
		return
	}

	// Clean output: remove empty lines or headers if any
	clean := strings.TrimSpace(string(out))

	logger.Info("Copying to clipboard")
	cmd := exec.Command("xclip", "-selection", "clipboard")
	cmd.Stdin = strings.NewReader(clean)
	cmd.Run()
}
