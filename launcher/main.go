//go:build windows

// ACCDCServer.exe: startet mit einem Doppelklick alles, was zum Server gehoert.
//
// Ist die Weboberflaeche installiert (accweb\accweb.exe), startet sie accweb. accweb startet
// den ACC-Server selbst (Autostart). Danach oeffnet sich der Browser.
// Ohne accweb startet sie server\accServer.exe direkt.
//
// Alle gestarteten Programme haengen an einem Windows-Job-Objekt. Schliesst du das Fenster,
// beendet Windows damit auch accweb und den ACC-Server, es bleibt nichts im Hintergrund haengen.
package main

import (
	"bufio"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"regexp"
	"strings"
	"syscall"
	"time"
	"unsafe"

	"golang.org/x/sys/windows"
)

var reader = bufio.NewReader(os.Stdin)

func main() {
	exe, err := os.Executable()
	if err != nil {
		fail("Programmpfad nicht gefunden: %v", err)
	}
	root := filepath.Dir(exe)

	fmt.Println("==============================================")
	fmt.Println("  ACC Race Control - Assetto Corsa Competizione")
	fmt.Println("==============================================")
	fmt.Println()

	accweb := filepath.Join(root, "accweb", "accweb.exe")
	server := filepath.Join(root, "server", "accServer.exe")

	if !exists(server) {
		fail("server\\accServer.exe fehlt. Zuerst install.ps1 ausfuehren (siehe README.md).")
	}

	stopRunning()

	job, err := newKillOnCloseJob()
	if err != nil {
		fail("Windows-Job konnte nicht angelegt werden: %v", err)
	}

	var cmd *exec.Cmd
	if exists(accweb) {
		cmd = startAccweb(root, accweb, job)
	} else {
		cmd = startServer(root, server, job)
	}

	// Strg+C und Fenster schliessen: alles beenden
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt, syscall.SIGTERM)
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()

	select {
	case <-sig:
		fmt.Println("\nBeende alles ...")
		windows.TerminateJobObject(job, 0)
		time.Sleep(500 * time.Millisecond)
	case err := <-done:
		windows.TerminateJobObject(job, 0)
		fmt.Println()
		if err != nil {
			fmt.Printf("Das Programm wurde beendet: %v\n", err)
		} else {
			fmt.Println("Das Programm wurde beendet.")
		}
		if exists(accweb) {
			fmt.Println("Den Grund findest du am Ende von accweb\\accweb.log.")
		}
		pause()
	}
}

// startAccweb startet accweb mit Log-Datei und oeffnet den Browser, sobald es antwortet.
func startAccweb(root, accweb string, job windows.Handle) *exec.Cmd {
	dir := filepath.Dir(accweb)
	logPath := filepath.Join(dir, "accweb.log")
	if exists(logPath) {
		os.Rename(logPath, filepath.Join(dir, "accweb.old.log"))
	}
	logFile, err := os.Create(logPath)
	if err != nil {
		fail("accweb.log kann nicht angelegt werden: %v", err)
	}

	cmd := exec.Command(accweb)
	cmd.Dir = dir
	cmd.Stdout = logFile
	cmd.Stderr = logFile
	start(cmd, job, "accweb")

	url := fmt.Sprintf("http://localhost:%s", webPort(filepath.Join(dir, "config.yml")))
	fmt.Println("Weboberflaeche startet ...")
	if waitHTTP(url, 30*time.Second) {
		fmt.Println("Weboberflaeche laeuft:  " + url)
		fmt.Println("Der ACC-Server startet automatisch mit (Autostart in accweb).")
		openBrowser(url)
	} else {
		fmt.Println("Die Weboberflaeche antwortet nicht. Siehe accweb\\accweb.log.")
	}
	fmt.Println()
	fmt.Println("Meldungen von accweb:   accweb\\accweb.log")
	fmt.Println("Zum Beenden von allem dieses Fenster schliessen oder Strg+C druecken.")
	return cmd
}

// startServer startet accServer.exe ohne Weboberflaeche, das Serverlog erscheint im Fenster.
func startServer(root, server string, job windows.Handle) *exec.Cmd {
	cmd := exec.Command(server)
	cmd.Dir = filepath.Dir(server)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	fmt.Println("Keine Weboberflaeche installiert, starte den ACC-Server direkt.")
	fmt.Println("Zum Beenden dieses Fenster schliessen oder Strg+C druecken.")
	fmt.Println()
	start(cmd, job, "accServer.exe")
	return cmd
}

func start(cmd *exec.Cmd, job windows.Handle, name string) {
	if err := cmd.Start(); err != nil {
		fail("%s konnte nicht gestartet werden: %v", name, err)
	}
	h, err := windows.OpenProcess(windows.PROCESS_SET_QUOTA|windows.PROCESS_TERMINATE, false, uint32(cmd.Process.Pid))
	if err == nil {
		windows.AssignProcessToJobObject(job, h)
		windows.CloseHandle(h)
	}
}

// stopRunning findet alte accweb- und accServer-Prozesse und bietet an, sie zu beenden.
func stopRunning() {
	var running []string
	for _, name := range []string{"accweb.exe", "accServer.exe"} {
		if isRunning(name) {
			running = append(running, name)
		}
	}
	if len(running) == 0 {
		return
	}
	fmt.Printf("Es laeuft bereits: %s\n", strings.Join(running, ", "))
	fmt.Print("Beenden und neu starten? [J/n] ")
	answer, _ := reader.ReadString('\n')
	answer = strings.ToLower(strings.TrimSpace(answer))
	if answer != "" && answer != "j" && answer != "y" {
		fmt.Println("Abgebrochen, es wurde nichts gestartet.")
		pause()
		os.Exit(0)
	}
	for _, name := range running {
		exec.Command("taskkill", "/f", "/im", name).Run()
	}
	time.Sleep(time.Second)
	fmt.Println()
}

func isRunning(name string) bool {
	out, err := exec.Command("tasklist", "/fi", "imagename eq "+name, "/fo", "csv", "/nh").Output()
	return err == nil && strings.Contains(strings.ToLower(string(out)), strings.ToLower(name))
}

func webPort(configYml string) string {
	data, err := os.ReadFile(configYml)
	if err == nil {
		if m := regexp.MustCompile(`host:\s*[^:\s]*:(\d+)`).FindSubmatch(data); m != nil {
			return string(m[1])
		}
	}
	return "8080"
}

func waitHTTP(url string, timeout time.Duration) bool {
	client := http.Client{Timeout: 2 * time.Second}
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if resp, err := client.Get(url); err == nil {
			resp.Body.Close()
			return true
		}
		time.Sleep(500 * time.Millisecond)
	}
	return false
}

func openBrowser(url string) {
	exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
}

// newKillOnCloseJob legt ein Job-Objekt an, das beim Ende dieses Programms alle Prozesse darin beendet,
// auch den ACC-Server, den accweb selbst startet.
func newKillOnCloseJob() (windows.Handle, error) {
	job, err := windows.CreateJobObject(nil, nil)
	if err != nil {
		return 0, err
	}
	info := windows.JOBOBJECT_EXTENDED_LIMIT_INFORMATION{
		BasicLimitInformation: windows.JOBOBJECT_BASIC_LIMIT_INFORMATION{
			LimitFlags: windows.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE,
		},
	}
	_, err = windows.SetInformationJobObject(job, windows.JobObjectExtendedLimitInformation,
		uintptr(unsafe.Pointer(&info)), uint32(unsafe.Sizeof(info)))
	return job, err
}

func exists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

func pause() {
	fmt.Print("\nEnter druecken zum Schliessen ...")
	reader.ReadString('\n')
}

func fail(format string, a ...any) {
	fmt.Printf("FEHLER: "+format+"\n", a...)
	pause()
	os.Exit(1)
}
