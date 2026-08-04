/*
 * Count Leading Ones
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream, then
 * counts the number of leading '1' bits (from the MSB) in a fixed test
 * word and prints the result. It runs on the Nios II 'standard',
 * 'full_featured', 'fast', and 'low_cost' example designs. It runs with
 * or without the MicroC/OS-II RTOS and requires a STDOUT device in your
 * system's hardware.
 *
 * Define PERFORMANCE_TEST below to instead run the counting algorithm
 * repeatedly and report its average execution time (measured with the
 * standard C clock() API) rather than a single result.
 */

#include <stdio.h>
#include <stdint.h>

/* #define PERFORMANCE_TEST */

# define PERFORMANCE_TEST

#ifdef PERFORMANCE_TEST
#include <time.h>

#define PERFORMANCE_TEST_ITERATIONS 100000u
#endif

static const uint32_t word = 0xFA000000;

int count_leading_ones(uint32_t value)
{
	uint32_t leading_ones = 0;
	int i;

	for (i = 31; i >= 0; i--)
	{
		uint32_t bit = (value >> i) & 1;
		if (!bit) {
			break;
		}
		++leading_ones;
	}

	return leading_ones;
}

#ifdef PERFORMANCE_TEST
static void run_performance_test(void)
{
	clock_t start, end;
	double elapsed_seconds;
	uint32_t i;
	volatile int result = 0; /* volatile so the compiler can't optimize the loop away */

	printf("Running performance test (%u iterations)...\n",
	       PERFORMANCE_TEST_ITERATIONS);

	start = clock();

	for (i = 0; i < PERFORMANCE_TEST_ITERATIONS; i++)
	{
		/* Vary the input word each iteration so the result can't just
		 * be computed once and cached by the compiler. */
		uint32_t test_word = word ^ i;
		result = count_leading_ones(test_word);
	}

	end = clock();

	elapsed_seconds = (double) (end - start) / CLOCKS_PER_SEC;

	printf("Performance test complete.\n");
	printf("  Total time   : %f s\n", elapsed_seconds);
	printf("  Avg per call : %f us\n",
	       (elapsed_seconds * 1000000.0) / PERFORMANCE_TEST_ITERATIONS);
	printf("  Last result  : %d\n", result);
}
#endif

int main()
{
	printf("Hello from Nios II!\n");

#ifdef PERFORMANCE_TEST
	run_performance_test();
#else
	{
		uint32_t leading_ones = count_leading_ones(word);
		printf("leading ones %lu\n", (unsigned long) leading_ones);
	}
#endif

	return 0;
}
