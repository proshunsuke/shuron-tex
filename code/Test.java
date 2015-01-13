
public class Test {
	public static void main(String[] args) {
		int x, y;

		try {
			x = Integer.parseInt(args[0]);
			y = Integer.parseInt(args[1]);
		} catch (Exception e) {
			x = 3;
			y = 2;
		}

		test(x, y);
	}

	@Obfuscate
	static void test(int x, int y) {
		int z = x + y;

		if (z > 0) {
			System.out.println("x:" + x);
		} else {
			System.out.println("y:" + y);
		}

		System.out.println("z:" + z);
	}
}
