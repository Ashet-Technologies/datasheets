{
    type=DATASHEET,
	status = DRAFT,
    title = "SerialPro 550",
    part = "ACT-SER-I",
    date = Date(2023,04,19),
    revision = Version(0,1),
}

# Overview

A 16C550 compatible UART component.

- [Features](#features)
- [Registers](#registers)

# Features

The SerialPro 550 is a 16C550 compatible UART implementation that provides a fully featured UART interface including flow- and modem control.

# Registers

| Offset  | Name | Size | Access | Description                           |
| ------- | ---- | ---- | ------ | ------------------------------------- |
| `0x000` | RBR  | 1    | R      | (DLAB=0) Receiver buffer              |
| `0x000` | THR  | 1    | W      | (DLAB=0) Transmitter holding register |
| `0x001` | IER  | 1    | R/W    | (DLAB=0) Interrupt enable register    |
| `0x000` | DLL  | 1    | R/W    | (DLAB=1) Divisor latch (LSB)          |
| `0x001` | DLM  | 1    | R/W    | (DLAB=1) Divisor latch (MSB)          |
| `0x002` | IIR  | 1    | R      | Interrupt identification register     |
| `0x002` | FCR  | 1    | W      | FIFO control register                 |
| `0x003` | LCR  | 1    | R/W    | Line control register                 |
| `0x004` | MCR  | 1    | R/W    | Modem control register                |
| `0x005` | LSR  | 1    | R      | Line status register                  |
| `0x006` | MSR  | 1    | R      | Modem status register                 |
| `0x007` | SCR  | 1    | R/W    | Scratch register                      |
