package main

import (
	"fmt"
	"os"
	"time"

	"github.com/hypebeast/go-osc/osc"
	"periph.io/x/conn/v3/i2c"
	"periph.io/x/conn/v3/i2c/i2creg"
	"periph.io/x/host/v3"

	log "github.com/schollz/logger"
)

// ADS7830 has 8 channels, and we need to read from all of them.
// The command byte for each channel in single-ended input mode are:
var channels = []byte{
	0x84, // Channel 0
	0xC4, // Channel 1
	0x94, // Channel 2
	0xD4, // Channel 3
	0xA4, // Channel 4
	0xE4, // Channel 5
	0xB4, // Channel 6
	0xF4, // Channel 7
}

func main() {
	// Initialize periph.io library
	if _, err := host.Init(); err != nil {
		log.Error(err)
		os.Exit(1)
	}

	// Open a handle to the I2C bus
	bus, err := i2creg.Open("1") // "1" is the bus number
	if err != nil {
		log.Error(err)
		os.Exit(1)
	}
	defer bus.Close()

	// Create a new I2C device with address 0x48
	dev := &i2c.Dev{Bus: bus, Addr: 0x48}

	// supercollider := osc.NewClient("192.168.0.53", 7771)
	supercollider := osc.NewClient("127.0.0.1", 7771)

	for {
		msg := osc.NewMessage("/ads7830")
		for i, cmd := range channels {
			// Write command byte to select channel
			write := []byte{cmd}
			if err := dev.Tx(write, nil); err != nil {
				log.Errorf("Failed to select channel %d: %v", i, err)
				continue
			}

			// Read 1 byte of data (the conversion result)
			read := make([]byte, 1)
			if err := dev.Tx(nil, read); err != nil {
				log.Error(err)
				continue
			}
			fmt.Printf("%d ", read[0])
			msg.Append(int32(read[0]))
		}
		fmt.Println(" ")
		supercollider.Send(msg)
		time.Sleep(100 * time.Millisecond)
	}
}
