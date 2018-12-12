import os
import sys

from requests_oauthlib import OAuth2Session

BASE_URL = 'https://ambitionschool.instructure.com'
canvas = OAuth2Session(token={'access_token': os.environ['TOKEN']})
r = canvas.post(BASE_URL + '/api/v1/accounts/1/users',
                {'pseudonym[unique_id]': sys.argv[1], 'pseudonym[force_self_registration]': 'true'})
