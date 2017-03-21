# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :
"""Module for custom exceptions definition"""

class SwitchStateAssertionError(AssertionError):
    """Switch's state is unexpected

    Describe an abnormal situation where the switch's state is not the one expected.
    """
    pass

class SwitchBadEchoBudgetExceededError(Exception):
    """Wrong echo budget has been exceeded

    When sending a command to the switch, we check the echo char by char.
    We only tolerate a maximum bad echo budget. When it's exceeded, this exception will be raised.
    """
    pass
