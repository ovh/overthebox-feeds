# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :
"""OTBv2 Switch module, extension with exceptions definition

This module adds exceptions and methods to the class Sw
"""

import logging
logger = logging.getLogger('swconfig')

class StateAssertionError(AssertionError):
    """Switch's state is unexpected

    Describe an abnormal situation where the switch's state is not the one expected.
    """
    pass

class BadEchoBudgetExceededError(Exception):
    """Wrong echo budget has been exceeded

    When sending a command to the switch, we check the echo char by char.
    We only tolerate a maximum bad echo budget. When it's exceeded, this exception will be raised.
    """
    pass

def _assert_state(self, state):
    if self.state != state:
        actual_state_name = "Unknown" if not self.state else self.state.name
        msg = "Unexpected switch state. Expected: '%s', got '%s'." % (state.name, actual_state_name)
        logger.error(msg)
        raise StateAssertionError(msg)
