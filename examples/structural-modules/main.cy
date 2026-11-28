module examples.structural_modules;
import { make_point } from example_producer;
import { sum_coordinates } from example_consumer;

func main() -> void {
    print sum_coordinates(make_point()); // 7：两模块中的结构相同
}
