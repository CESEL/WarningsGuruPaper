"""
Settings to connect to postgresql database
"""

import os
import pwd

DATABASE_SETTINGS = {
    "louisq": {
        "DATABASE_HOST": "brom",
        "DATABASE_NAME": "cas_fse",
        "DATABASE_USERNAME": "",
        "DATABASE_PASSWORD": "red36brick"
    }
}


def get_local_settings():

    username = __get_username__()

    if username in DATABASE_SETTINGS:
        return DATABASE_SETTINGS[username]
    else:
        print("Current system username '%s' not defined in settings.py" % username)


def __get_username__():
    return pwd.getpwuid(os.getuid()).pw_name


if __name__ == "__main__":
    # Helps you find out your username
    print("Your username is: '%s'" % __get_username__())
