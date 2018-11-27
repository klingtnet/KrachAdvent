extern crate rosc;
extern crate rppal;

use rppal::spi::{Bus, Mode, SlaveSelect, Spi};
use std::thread;
use std::time::Duration;

use rosc::encoder;
use rosc::{OscMessage, OscPacket, OscType};
use std::net::UdpSocket;

fn main() {
    let spi =
        Spi::new(Bus::Spi0, SlaveSelect::Ss0, 1_000_000, Mode::Mode0).expect("SPI setup failed");
    let mut buf = [0u8; 3];

    let sock = UdpSocket::bind("127.0.0.1:55555").expect("socket creation failed");

    let addrs = [
        "/pitch/ratio",
        "/randomness/amount",
        "/grain/rate",
        "/grain/overlap",
        "/position/speed",
        "/reverb/mix",
        // pots are swapped
        "/volume",
        "/filter/cutoff",
    ];

    let mut idx: usize = 0;
    let mut pots = vec![0f32; 8];
    let mut last_pots = vec![0f32; 8];
    let epsilon = 1.0 / 2048.0;
    loop {
        let select = &mut [0b0000_0001, (0b1000 + (idx as u8)) << 4, 0];
        spi.transfer(&mut buf, select).expect("SPI transfer failed");
        let val = f32::from(u16::from(buf[1]) * 256 + u16::from(buf[2])) / 1024.0;

        if (val - last_pots[idx]).abs() > epsilon {
            let msg_buf = encoder::encode(&OscPacket::Message(OscMessage {
                addr: addrs[idx].into(),
                args: Some(vec![OscType::Float(val)]),
            })).expect("failed to build OSC packet");
            sock.send_to(&msg_buf, "127.0.0.1:55556")
                .expect("failed to send UDP packet");
        }

        pots[idx] = val;
        last_pots[idx] = pots[idx];
        idx = (idx + 1) & 0b_0111;
        thread::sleep(Duration::from_millis(1));
    }
}
