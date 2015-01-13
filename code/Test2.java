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
		new Test().test(x, y);
	}

	void test(int $var0, int $var1) {
		$V $v = new $V();
		$v.$var0 = $var0;
		$v.$var1 = $var1;
		$o0[(7 * $v.$var0 * $v.$var0 - 1 != $v.$var1 * $v.$var1) ? 0 : 1].m(this, $v); //$v.$var2=$v.$var0+$v.$var1
		if ($v.$var2 > 0) {
			$o1[(7 * $v.$var1 * $v.$var1 - 1 != $v.$var1 * $v.$var1) ? 0 : 1].m(this, $v); //System.out.println("x:"+$v.$var0)
		}
		else {
			$o2[(7 * $v.$var0 * $v.$var0 - 1 != $v.$var1 * $v.$var1) ? 0 : 1].m(this, $v); //System.out.println("y:"+$v.$var1)
		}
		$o3[(7 * $v.$var1 * $v.$var1 - 1 != $v.$var1 * $v.$var1) ? 0 : 1].m(this, $v); //System.out.println("z:"+$v.$var2)
	}

	private static final $O[] $o3 = { $O.$o3a, $O.$o3b };

	static class $3A extends $O {
		void m(Test2 $this, $V $v) {
			System.out.println("z:" + $v.$var2);
		}
	}

	static class $3B extends $O {
		void m(Test2 $this, $V $v) {
			//DummyCode
		}
	}

	private static final $O[] $o2 = { $O.$o2a, $O.$o2b };

	static class $2A extends $O {
		void m(Test2 $this, $V $v) {
			System.out.println("y:" + $v.$var1);
		}
	}

	static class $2B extends $O {
		void m(Test2 $this, $V $v) {
			//DummyCode
		}
	}

	private static final $O[] $o1 = { $O.$o1a, $O.$o1b };

	static class $1A extends $O {
		void m(Test2 $this, $V $v) {
			System.out.println("x:" + $v.$var0);
		}
	}

	static class $1B extends $O {
		void m(Test2 $this, $V $v) {
			//DummyCode
		}
	}

	private static final $O[] $o0 = { $O.$o0a, $O.$o0b };

	static class $0A extends $O {
		void m(Test2 $this, $V $v) {
			$v.$var2 = $v.$var0 + $v.$var1;
		}
	}

	static class $0B extends $O {
		void m(Test2 $this, $V $v) {
			//DummyCode
		}
	}

	static class $V {
		int $var0;
		int $var1;
		int $var2;
	}

	static abstract class $O {
		abstract void m(Test2 $this, $V $v);

		static final $O $o0a = new $0A(), $o0b = new $0B(),
				$o1a = new $1A(), $o1b = new $1B(),
				$o2a = new $2A(), $o2b = new $2B(),
				$o3a = new $3A(), $o3b = new $3B();
	}
}

