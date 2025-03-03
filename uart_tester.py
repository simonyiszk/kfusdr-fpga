import tqdm
import random
import serial

if __name__ == "__main__":
    uart = serial.serial_for_url("/dev/ttyUSB0", 9600, 8)
    cntr = 0
    for i in tqdm.tqdm(range(0, 1000)):
        data_2_send = int.to_bytes(random.randint(0, 255), 1, "big")
        uart.write(data_2_send)
        data_received = uart.read()
        if data_2_send != data_received:
            print(f"Failure: sent {data_2_send}, got {data_received}")
            cntr += 1
    print(f"Finished, errors: {cntr}")
