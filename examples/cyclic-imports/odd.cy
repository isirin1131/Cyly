module example_odd;
import { is_even } from example_even;

export func is_odd(u32 value) -> bool {
    if (value == 0) return false;
    return is_even(value - 1);
}
