using Ion

suites = Ion.find_test_suites(Returns(true), pkgdir(Ion, "test", "examples"))

suites_proc = Ion.divide_tests(suites, 4)
suites_proc = Ion.divide_tests(suites, 3)

Ion.test(pkgdir(Ion, "test", "examples"), String["folder/*"])
Ion.test(pkgdir(Ion, "test", "examples"), String[])
