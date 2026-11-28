module example_even;
import { is_odd } from example_odd;

export func is_even(u32 value) -> bool {
    if (value == 0) return true;
    return is_odd(value - 1);
}
