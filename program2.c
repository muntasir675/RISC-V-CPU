#define MEM_BASE ((volatile int*) 0x100)

// 1. Tests Load-to-Store forwarding / stall
int test_load_to_store() {
    volatile int* p = MEM_BASE;
    p[0] = 0x12345678;
    int val = p[0];
    p[1] = val;              // Store immediately uses loaded value
    if (p[1] != 0x12345678) return -1;
    return 0;
}

// 2. Tests Load-to-Branch condition hazard
int test_load_to_branch() {
    volatile int* p = MEM_BASE;
    p[2] = 42;
    if (p[2] != 42) return -2; // Branch immediately depends on load
    return 0;
}

// 3. Tests Byte and Halfword load/store (sign extension & offsets)
int test_byte_halfword() {
    volatile char* pb = (volatile char*) (MEM_BASE + 4);
    volatile short* ph = (volatile short*) (MEM_BASE + 6);

    pb[0] = 0x5A;
    pb[1] = (char) 0xCE;
    if (pb[0] != 0x5A) return -3;
    if (pb[1] != (char) 0xCE) return -4;

    ph[0] = (short) 0xBEEF;
    if (ph[0] != (short) 0xBEEF) return -5;
    return 0;
}

// 4. Tests back-to-back arithmetic dependency chains (ALU forwarding)
int test_hazard_chain() {
    volatile int a = 10;
    volatile int b = 20;
    int x = a + b;                   // 30
    int z = (x << 2) - b + (x >> 1); // 120 - 20 + 15 = 115
    if (z != 115) return -6;
    return 0;
}

// 5. Tests tight loop branch prediction & stack calls
int test_call_and_loop() {
    volatile int sum = 0;
    for (int i = 1; i <= 10; i++) {
        if ((i & 1) == 0) sum += i;
        else sum -= i;
    }
    if (sum != 5) return -7;
    return 0;
}

int main() {
    if (test_load_to_store() != 0) return -10;
    if (test_load_to_branch() != 0) return -20;
    if (test_byte_halfword() != 0) return -30;
    if (test_hazard_chain() != 0) return -40;
    if (test_call_and_loop() != 0) return -50;

    return 1; // 1 = ALL PASS
}