/******************************************************************************
 *
 * Description
 * *************
 * Pulses the LEDs up and down in brightness using the PWM custom
 * instruction component (ALT_CI_NCI_PWM_CONTROLLER_0). The duty-cycle
 * "level" ramps from PWM_LEVEL_MIN up to PWM_LEVEL_MAX and back down again,
 * repeating forever, which produces a breathing/pulsing LED effect.
 *
 * Requirements
 * **************
 * This program requires a PWM controller custom instruction component
 * named 'PWM_CONTROLLER_0' to be present in the system (see system.h for
 * the generated ALT_CI_NCI_PWM_CONTROLLER_0(A,B) macro).
 *
 *****************************************************************************/

#include "system.h"

#include <stdbool.h>
#include <stdint.h>
#include <unistd.h>

/* Duty-cycle range accepted by the PWM controller. */
#define PWM_LEVEL_MIN 0
#define PWM_LEVEL_MAX 10

/* Delay between duty-cycle steps, in microseconds. */
#define PWM_STEP_DELAY_US 200000

int main()
{
	uint32_t level = PWM_LEVEL_MIN;
	bool increment = true;

	while (true)
	{
		ALT_CI_NCI_PWM_CONTROLLER_0(level, 0);

		if (increment)
		{
			if (level == PWM_LEVEL_MAX)
				increment = false;
			else
				level++;
		}
		else
		{
			if (level == PWM_LEVEL_MIN)
				increment = true;
			else
				level--;
		}

		usleep(PWM_STEP_DELAY_US);
	}

	return 0;
}
