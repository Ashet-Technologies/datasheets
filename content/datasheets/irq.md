{
    type=DATASHEET,
	status = PUBLISHED,
    title = "IRQ Dispatch",
    part = "ACT-IRQ-I",
    date = Date(2024,05,26),
    revision = Version(1,0,0),
}

# Overview

- Dispatch multiple IRQ lanes into a single lane
- Acknowledge of IRQs
- Masking of IRQs
- up to 32 IRQs

# Function

The IRQ controller manages up to 32 different IRQ sources that work with level-driven IRQs.
If a source IRQ lane is _low_, the IRQ is assumed to be active. A IRQ becomes inactive when the
source lane will go to _high_.

When an IRQ becomes active, a corresponding bit is set in the `IRQ0` or `IRQ1` register and the output IRQ lane is pulled to _low_.
The output IRQ lane is _low_ until all bits in the `IRQ0` and `IRQ1` registers are `0`.

To acknowledge that an IRQ was handled, write a `1` bit into `IRQ0` or `IRQ1` to tell the controller that this interrupt was handled.
If the IRQ was previously active, it is now disabled.

Masking interrupts is supported by writing a `1` bit to `MASK0` or `MASK1`. Interrupts will only become active when the IRQ lane is _low_ and the corresponding bit in `MASK0` or `MASK1` is `0`. When the controller is reset, all interrupts are masked.

# Registers

| Offset  | Name  | Size | Access | Description            |
| ------- | ----- | ---- | ------ | ---------------------- |
| `0x000` | IRQ0  | 2    | R      | Active IRQs 0…15       |
| `0x002` | IRQ1  | 2    | R      | Active IRQs 16…31      |
| `0x000` | ACK0  | 2    | W      | Acknowledge IRQs 0…15  |
| `0x002` | ACK1  | 2    | W      | Acknowledge IRQs 16…31 |
| `0x004` | MASK0 | 2    | R/W    | Mask IRQs 0…15         |
| `0x006` | MASK1 | 2    | R/W    | Mask IRQs 16…31        |

## Active IRQs 0…15

When read, all IRQs between 0 and 15 that were triggered since the last acknowledge are
displayed as `1`. All non-triggered IRQs are `0`.

## Active IRQs 16…31

When read, all IRQs between 16 and 31 that were triggered since the last acknowledge are
displayed as `1`. All non-triggered IRQs are `0`.

## Acknowledge IRQs 0…15

When writing to this register, all bits that are `1` in this register will be acknowledged and reset.

## Acknowledge IRQs 16…31

When writing to this register, all bits that are `1` in this register will be acknowledged and reset.

## Mask IRQs 0…15

When a bit is 1, the corresponding interrupt is masked and will not be able to get active. On controller reset, all interrupts are masked.

## Mask IRQs 16…31

When a bit is 1, the corresponding interrupt is masked and will not be able to get active. On controller reset, all interrupts are masked.
